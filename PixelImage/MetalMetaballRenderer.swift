import Metal
import UIKit
import ChameleonFramework

@objc class MetalMetaballRenderer: NSObject {

	typealias TargetView = UIImageView

	let targetView: TargetView

	let metaballGraph: MTMGraph!

	let context = MTLContext()
	var activeComputeContext: MTLComputeContext? = nil
	var idleComputeContext: MTLComputeContext? = nil

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
		let size = size ?? CGSize(width: 736, height: 414)

		let width = Int(ceil(size.width))
		let height = Int(ceil(size.height))

		var positions = [CGPoint]()
		positions.append(CGPoint(
			x: Double(width) / 2,
			y: Double(height) / 2))
		for i in 1...5 {
			let sine = sin(Double(i) * 2 * .pi / 5)
			let cosine = cos(Double(i) * 2 * .pi / 5)
			let radius: Double = 150
			let x = Double(width) / 2 + sine * radius
			let y = Double(height) / 2 + cosine * radius
			positions.append(CGPoint(x: x, y: y))
		}
		let colors =
			[UIColor(red255: 110, green: 220, blue: 220, alpha: 1.0),
			 UIColor(red255: 250, green: 235, blue: 50, alpha: 1.0),
			 UIColor(red255: 110, green: 220, blue: 220, alpha: 1.0),
			 UIColor(red255: 90, green: 170, blue: 170, alpha: 1.0),
			 UIColor(red255: 90, green: 170, blue: 170, alpha: 1.0),
			 UIColor(red255: 110, green: 220, blue: 220, alpha: 1.0)]

		let vertices = zip(positions, colors).map {
			MTMVertex(position: $0.0, color: $0.1)
		}

		self.metaballGraph = MTMGraph(vertices: vertices)

		self.targetView = TargetView(frame: CGRect(origin: .zero, size: size))

		super.init()

		updateSize(to: size)
	}

	func updateSize(to newSize: CGSize) {
		let width = Int(ceil(newSize.width))
		let height = Int(ceil(newSize.height))

		let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
				pixelFormat: .bgra8Unorm,
				width: width,
				height: height,
				mipmapped: false)

		let texture1 = context.device.makeTexture(descriptor: textureDescriptor)
		let texture2 = context.device.makeTexture(descriptor: textureDescriptor)

		self.activeComputeContext = MTLComputeContext(size: newSize,
		                                              texture: texture1)
		self.idleComputeContext = MTLComputeContext(size: newSize,
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
		let width = Int(targetView.width)
		let height = Int(targetView.height)

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
			let threadGroups = MTLSizeMake(width / threadGroupCounts.width,
			                               height / threadGroupCounts.height,
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
		let imageSize = CGSize(width: CGFloat(texture.width),
		                       height: CGFloat(texture.height))
		let width = Int(imageSize.width)
		let height = Int(imageSize.height)
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
