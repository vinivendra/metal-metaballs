import Metal
import UIKit
import ChameleonFramework

@objc class MetalMetaballRenderer: NSObject {

	let targetView: UIImageView

	let metaballGraph: MTMGraph!

	let context = MTLContext()
	var activeComputeContext: MTLComputeContext? = nil
	var idleComputeContext: MTLComputeContext? = nil

	internal var bufferSize: (width: Int, height: Int) = (0, 0)

	let semaphore = DispatchSemaphore(value: 2)

	enum RendererState {
		case idle
		case running
		case ending
	}

	var state: RendererState = .idle {
		willSet {
			if state == .idle {
				if newValue == .running {
					updateTargetView()
				}
			}
		}
	}

	init(size: CGSize? = nil) {
		self.metaballGraph = MTMGraph()

		self.targetView = UIImageView()

		super.init()

		if let size = size {
			updateSize(to: size)
		}
	}

	func updateSize(to newSize: CGSize) {
		updateContextSize(to: (Int(ceil(newSize.width)),
		                       Int(ceil(newSize.height))))
	}

	func updateSize(to newSize: (width: Int, height: Int)) {
		updateContextSize(to: newSize)
	}

	private func updateContextSize(to newSize: (width: Int, height: Int)) {
		guard newSize.width > 0, newSize.height > 0 else {
			self.activeComputeContext = nil
			self.idleComputeContext = nil
			return
		}
		guard newSize != bufferSize else {
			return
		}

		bufferSize = newSize

		let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
			pixelFormat: .bgra8Unorm,
			width: bufferSize.width,
			height: bufferSize.height,
			mipmapped: false)

		let texture1 = context.device.makeTexture(descriptor: textureDescriptor)
		let texture2 = context.device.makeTexture(descriptor: textureDescriptor)

		self.activeComputeContext = MTLComputeContext(width: newSize.width,
		                                              height: newSize.height,
		                                              texture: texture1)
		self.idleComputeContext = MTLComputeContext(width: newSize.width,
		                                            height: newSize.height,
		                                            texture: texture2)
	}

	internal func updateTargetView() {
		let timeout = DispatchTime.distantFuture
		_ = semaphore.wait(timeout: timeout)

		state = .ending

		let userInteractiveQueue =
			DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
		userInteractiveQueue.async { () -> Void in
			guard let computeContext = self.activeComputeContext else { return }
			swap(&self.activeComputeContext, &self.idleComputeContext)

			// Render graphics to metal texture
			self.renderToContext(computeContext)

			if self.state != .running {
				self.state = .idle
			} else {
				self.updateTargetView()
			}

			// Transform metal texture into image
			let uiimage = self.createImageFromContext(computeContext)

			self.semaphore.signal()

			DispatchQueue.main.async { () -> Void in
				// FIXME: [#10] Race conditions might replace new image with old
				// image

				// Send image to view
				self.targetView.image = uiimage
			}
		}
	}

	internal func renderToContext(_ computeContext: MTLComputeContext) {
		let kernelFunction: MTLFunction?
		let pipeline: MTLComputePipelineState
		do {
			// FIXME: [#11] Should these be stored?
			// Get long-lived objects
			kernelFunction =
				context.library.makeFunction(name: "drawMetaballs")
			pipeline = try context.device.makeComputePipelineState(
				function: kernelFunction!)

			// Configure info for computing
			let threadGroupCounts = MTLSizeMake(8, 8, 1)
			let threadGroups = MTLSizeMake(
				computeContext.size.width / threadGroupCounts.width,
				computeContext.size.height / threadGroupCounts.height,
				1)

			// Send commands to metal and render
			let commandBuffer = context.commandQueue.makeCommandBuffer()

			let commandEncoder = commandBuffer.makeComputeCommandEncoder()
			commandEncoder.setComputePipelineState(pipeline)
			commandEncoder.setTexture(computeContext.texture, at: 0)
			let metaballInfoBuffer = metaballBuffer()
			commandEncoder.setBuffer(metaballInfoBuffer, offset: 0, at: 0)
			let edgesBuffer = metaballEdgesBuffer()
			commandEncoder.setBuffer(edgesBuffer, offset: 0, at: 1)
			commandEncoder.dispatchThreadgroups(threadGroups,
			                                    threadsPerThreadgroup: threadGroupCounts)
			commandEncoder.endEncoding()

			commandBuffer.commit()
			commandBuffer.waitUntilCompleted()
		} catch _ {
			assertionFailure()
		}
	}

	internal func createImageFromContext(_ computeContext: MTLComputeContext)
		-> UIImage
	{
		let texture = computeContext.texture

		// Get image info
		let width = texture.width
		let height = texture.height
		let imageByteCount = width * height * 4
		let bytesPerRow = width * 4
		let region = MTLRegionMake2D(0, 0, width, height)

		// Transfer texture info into image buffer
		texture.getBytes(computeContext.imageBuffer,
		                 bytesPerRow: bytesPerRow,
		                 from: region,
		                 mipmapLevel: 0)

		// Get info for UIImage
		let provider = CGDataProvider(dataInfo: nil,
		                              data: computeContext.imageBuffer,
		                              size: imageByteCount) {
										(_, _, _) in }
		let bitsPerComponent = 8
		let bitsperPixel = 32
		let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
		let bitmapInfoRaw = CGImageAlphaInfo.premultipliedLast.rawValue |
			CGBitmapInfo.byteOrder32Big.rawValue
		let bitmapInfo = CGBitmapInfo(rawValue: bitmapInfoRaw)
		let renderingIntent = CGColorRenderingIntent.defaultIntent

		// Create UIImage from image buffer
		let imageRef = CGImage(width: width, height: height,
		                       bitsPerComponent: bitsPerComponent,
		                       bitsPerPixel: bitsperPixel,
		                       bytesPerRow: bytesPerRow,
		                       space: colorSpaceRef,
		                       bitmapInfo: bitmapInfo,
		                       provider: provider!,
		                       decode: nil, shouldInterpolate: false,
		                       intent: renderingIntent)
		let image = UIImage(cgImage: imageRef!, scale: 0.0, orientation: .up)

		return image
	}

	internal func metaballEdgesBuffer() -> MTLBuffer {
		let floats = metaballGraph.edges.buffer

		let bufferLength = floats.count * MemoryLayout<Float>.size
		let device = context.device
		let buffer = device.makeBuffer(bytes: floats,
		                               length: bufferLength,
		                               options: MTLResourceOptions())

		return buffer
	}

	internal func metaballBuffer() -> MTLBuffer {
		// Create Float array for buffer
		// Exclude metaballs far from the view's bounds
		// FIXME: [#12] Metaballs can't be culled like this, otherwise edges
		// will disappear
		let border: CGFloat = 100
		let metaballs = self.metaballGraph.vertices

		var floats = [Float](repeating: 0, count: 5)
		floats = metaballs.reduce(floats) {
			(array, metaball) -> [Float] in
			var array = array

			let x = CGFloat(metaball.position.x)
			let y = CGFloat(metaball.position.y)
			if -border < x,
				x < targetView.width + border,
				-border < y,
				y < targetView.height + border {
				array.append(Float(x))
				array.append(Float(y))

				let color = metaball.color
				let components = color.components
				array.append(Float(components.red))
				array.append(Float(components.green))
				array.append(Float(components.blue))
			}
			return array
		}

		// Add array size to start of array so metal knows how far to go
		floats[0] = Float(floats.count) / 5

		// Create buffer
		let bufferLength = floats.count * MemoryLayout<Float>.size
		let device = context.device
		let buffer = device.makeBuffer(bytes: floats,
		                               length: bufferLength,
		                               options: MTLResourceOptions())

		return buffer
	}
}
