import Metal
import UIKit
import ChameleonFramework

@objc class MetalMetaballRenderer: NSObject {

    typealias TargetView = UIImageView

    let targetView: TargetView

    let context = MTLContext()
    var activeComputeContext: MTLComputeContext
    var idleComputeContext: MTLComputeContext

    let dataSource: MetaballDataSource

    let semaphore = dispatch_semaphore_create(2)

    enum RendererState {
        case Idle
        case Running
        case Ending
    }

    var state: RendererState = .Idle {
        willSet {
            if state == .Idle {
                if newValue == .Running {
                    updateTargetView()
                }
            }
        }
    }

    required init(dataSource: MetaballDataSource, frame: CGRect) {
        self.dataSource = dataSource

        targetView = TargetView(frame: frame)

        let width = Int(frame.width)
        let height = Int(frame.height)
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.BGRA8Unorm, width: width, height: height, mipmapped: false)

        let texture1 = context.device.newTextureWithDescriptor(textureDescriptor)
        activeComputeContext = MTLComputeContext(size: targetView.size, texture: texture1)
        let texture2 = context.device.newTextureWithDescriptor(textureDescriptor)
        idleComputeContext = MTLComputeContext(size: targetView.size, texture: texture2)
    }

    internal func updateTargetView() {

        let timeout = dispatch_time(DISPATCH_TIME_NOW, 1000000000)
        dispatch_semaphore_wait(semaphore, timeout)

        state = .Ending

        let userInteractiveQueue = dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.rawValue), 0)
        dispatch_async(userInteractiveQueue) { () -> Void in

            let computeContext = self.activeComputeContext
            swap(&self.activeComputeContext, &self.idleComputeContext)

            // Render graphics to metal texture
            self.renderToContext(computeContext)

            if self.state != .Running {
                self.state = .Idle
            } else {
                self.updateTargetView()
            }

            // Transform metal texture into image
            let uiimage = self.createImageFromContext(computeContext)

            dispatch_semaphore_signal(self.semaphore)

            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                // Send image to view
                self.targetView.image = uiimage
            }
        }
    }

    internal func renderToContext(computeContext: MTLComputeContext) {
        let width = Int(targetView.width)
        let height = Int(targetView.height)

        let kernelFunction: MTLFunction?
        let pipeline: MTLComputePipelineState
        do {
            // Get long-lived objects
            kernelFunction = context.library.newFunctionWithName("drawMetaballs")
            pipeline = try context.device.newComputePipelineStateWithFunction(kernelFunction!)

            // Configure info for computing
            let threadGroupCounts = MTLSizeMake(8, 8, 1)
            let threadGroups = MTLSizeMake(width / threadGroupCounts.width, height / threadGroupCounts.height, 1)

            // Send commands to metal and render
            let commandBuffer = context.commandQueue.commandBuffer()

            let commandEncoder = commandBuffer.computeCommandEncoder()
            commandEncoder.setComputePipelineState(pipeline)
            commandEncoder.setTexture(computeContext.texture, atIndex: 0)
            let metaballInfoBuffer = metaballBuffer()
            commandEncoder.setBuffer(metaballInfoBuffer, offset: 0, atIndex: 0)
            let edgesBuffer = metaballEdgesBuffer()
            commandEncoder.setBuffer(edgesBuffer, offset: 0, atIndex: 1)
            commandEncoder.dispatchThreadgroups(threadGroups,
                threadsPerThreadgroup: threadGroupCounts)
            commandEncoder.endEncoding()

            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        } catch _ {
            assertionFailure()
        }
    }

    internal func createImageFromContext(computeContext: MTLComputeContext) -> UIImage {
        let texture = computeContext.texture

        // Get image info
        let imageSize = CGSizeMake(CGFloat(texture.width), CGFloat(texture.height))
        let width = Int(imageSize.width)
        let height = Int(imageSize.height)
        let imageByteCount = width * height * 4
        let bytesPerRow = width * 4
        let region = MTLRegionMake2D(0, 0, width, height)

        // Allocate the buffer if needed
        if computeContext.imageBuffer == nil {
            computeContext.imageBuffer = malloc(imageByteCount)
        }

        // Transfer texture info into image buffer
        texture.getBytes(computeContext.imageBuffer, bytesPerRow: bytesPerRow, fromRegion: region, mipmapLevel: 0)

        // Get info for UIImage
        let provider = CGDataProviderCreateWithData(nil, computeContext.imageBuffer, imageByteCount, nil)
        let bitsPerComponent = 8
        let bitsperPixel = 32
        let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
        let bitmapInfoRaw = CGImageAlphaInfo.PremultipliedLast.rawValue | CGBitmapInfo.ByteOrder32Big.rawValue
        let bitmapInfo = CGBitmapInfo(rawValue: bitmapInfoRaw)
        let renderingIntent = CGColorRenderingIntent.RenderingIntentDefault

        // Create UIImage from image buffer
        let imageRef = CGImageCreate(width, height, bitsPerComponent, bitsperPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, nil, false, renderingIntent)
        let image = UIImage(CGImage: imageRef!, scale: 0.0, orientation: .Up)

        return image
    }

    internal func metaballEdgesBuffer() -> MTLBuffer {
        let floats = dataSource.metaballGraph.adjacencyMatrix.buffer

        let bufferLength = floats.count * sizeof(Float)
        let device = context.device
        let buffer = device.newBufferWithBytes(floats, length: bufferLength, options: .StorageModeShared)

        return buffer
    }

    internal func metaballBuffer() -> MTLBuffer {
        // Create Float array for buffer
        // Exclude metaballs far from the view's bounds
        let border: CGFloat = 100
        let metaballs = self.dataSource.metaballs

        var floats = [Float](count: 5, repeatedValue: 0)
        floats = metaballs.reduce(floats) {
            (var array, metaball) -> [Float] in

            let x = CGFloat(metaball.midX)
            let y = CGFloat(metaball.midY)
            if -border < x ≤ targetView.width + border &&
                -border < y ≤ targetView.height + border {
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
        let bufferLength = floats.count * sizeof(Float)
        let device = context.device
        let buffer = device.newBufferWithBytes(floats, length: bufferLength, options: .StorageModeShared)

        return buffer
    }
}
