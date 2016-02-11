// TOOD: Use two compute contexts and double recursion

// TODO: Make graphics have edges only according to graph (instead of being a complete graph)

// TODO: Interpolate metaball colors
// TODO: Use metaballs as mask: apply strong blur inside, weak blur outside
// TODO: Add antialiasing

import Metal
import UIKit

var i = 0

class MetalMetaballRenderer {

    typealias TargetView = UIImageView

    let targetView: TargetView

    let context = MTLContext()
    var computeContext: MTLComputeContext

    let dataSource: MetaballDataSource

    var dirty = false
    var metalIsBusy = false

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
        let textureDescriptor =
        MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.BGRA8Unorm, width: width, height: height, mipmapped: false)
        let texture = context.device.newTextureWithDescriptor(textureDescriptor)
        computeContext = MTLComputeContext(size: targetView.size, texture: texture)
    }

    func updateTargetView() {

        print("Update \(i++)!")

        state = .Ending

        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.rawValue), 0)) { () -> Void in

            // Render graphics to metal texture
            self.renderToContext(shouldUsePrimaryContext: true)

            // Transform metal texture into image
            let uiimage = self.createImageFromContext(shouldUsePrimaryContext: true)

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                // Send image to view
                self.targetView.image = uiimage

                if self.state != .Running {
                    self.state = .Idle
                } else {
                    self.updateTargetView()
                }
            })
        }
    }

    func renderToContext(shouldUsePrimaryContext shouldUsePrimaryContext: Bool) {
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
            let threadGroups = MTLSizeMake(width / threadGroupCounts.width,
                height / threadGroupCounts.height, 1)

            // Send commands to metal and render
            let commandBuffer = context.commandQueue.commandBuffer()

            let commandEncoder = commandBuffer.computeCommandEncoder()
            commandEncoder.setComputePipelineState(pipeline)
            commandEncoder.setTexture(computeContext.texture, atIndex: 0)
            let metaballInfoBuffer = metaballBuffer()
            commandEncoder.setBuffer(metaballInfoBuffer, offset: 0, atIndex: 0)
            commandEncoder.dispatchThreadgroups(threadGroups,
                threadsPerThreadgroup: threadGroupCounts)
            commandEncoder.endEncoding()

            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()

        } catch _ {
            print("Error!")
        }
    }

    func createImageFromContext(shouldUsePrimaryContext shouldUsePrimaryContext: Bool) -> UIImage {
        let texture = computeContext.texture

        // Get image info
        let imageSize = CGSizeMake(CGFloat(texture.width),
            CGFloat(texture.height))
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
        texture.getBytes(computeContext.imageBuffer, bytesPerRow: bytesPerRow,
            fromRegion: region, mipmapLevel: 0)

        // Get info for UIImage
        let provider = CGDataProviderCreateWithData(nil, computeContext.imageBuffer,
            imageByteCount, nil)
        let bitsPerComponent = 8
        let bitsperPixel = 32
        let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue:
            CGImageAlphaInfo.PremultipliedLast.rawValue |
                CGBitmapInfo.ByteOrder32Big.rawValue)
        let renderingIntent = CGColorRenderingIntent.RenderingIntentDefault

        // Create UIImage from image buffer
        let imageRef = CGImageCreate(width, height,
            bitsPerComponent, bitsperPixel, bytesPerRow,
            colorSpaceRef, bitmapInfo, provider,
            nil, false, renderingIntent)
        let image = UIImage(CGImage: imageRef!, scale: 0.0,
            orientation: UIImageOrientation.Up)

        return image
    }

    func metaballBuffer() -> MTLBuffer {
        // Create Float array for buffer
        // Exclude metaballs far from the view's bounds
        let border: CGFloat = 100
        let metaballs = self.dataSource.metaballs
        var floats: [Float] = metaballs.reduce([Float(0)]) { (var array, metaball) -> [Float] in
            let x = CGFloat(metaball.midX)
            let y = CGFloat(metaball.midY)
            if -border < x ≤ targetView.width + border &&
                -border < y ≤ targetView.height + border {
                    array.append(Float(x))
                    array.append(Float(y))
            }
            return array
        }
        // Add array size to start of array so metal knows how far to go
        floats[0] = Float(floats.count) / 2

        // Create buffer
        let buffer = context.device.newBufferWithBytes(floats, length: floats.count * sizeof(Float), options: .StorageModeShared)
        
        return buffer
    }
}
