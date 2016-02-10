// TODO: Metaballs from texture to buffer
// TODO: Use async dispatch to free up main queue
// TODO: Refactor update into 2 calls: metalRendering() and textureToImage()
// TODO: Use two textures/images to alternate the 2 calls (like OpenGL double buffers)

// TODO: Make graphics have edges only according to graph (instead of being a complete graph)

// TODO: Interpolate metaball colors
// TODO: Use metaballs as mask: apply strong blur inside, weak blur outside
// TODO: Add antialiasing

import Metal
import UIKit

class MetalMetaballRenderer: MetaballRenderer {

    typealias TargetView = UIImageView

    let targetView = TargetView()
    var previousFrame = CGRect.zero

    let context = MTLContext()
    var renderingTexture: MTLTexture!
    var imageBuffer: UnsafeMutablePointer<Void>!

    let dataSource: MetaballDataSource

    required init(dataSource: MetaballDataSource) {
        self.dataSource = dataSource
    }

    func updateTargetView() {
        let metaballs = dataSource.metaballs

        if previousFrame != targetView.frame {
            previousFrame = targetView.frame
            updateFrame()
        }

        let width = Int(targetView.width)
        let height = Int(targetView.height)

        if renderingTexture == nil {
            let textureDescriptor =
            MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.BGRA8Unorm, width: width, height: height, mipmapped: false)

            renderingTexture = context.device.newTextureWithDescriptor(textureDescriptor)
        }

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

            // Create up-to-date metaball buffer
            let metaballInfoBuffer = metaballBuffer(metaballs)

            // Send commands to metal and render
            let commandBuffer = context.commandQueue.commandBuffer()

            let commandEncoder = commandBuffer.computeCommandEncoder()
            commandEncoder.setComputePipelineState(pipeline)
            commandEncoder.setTexture(renderingTexture, atIndex: 0)
            commandEncoder.setBuffer(metaballInfoBuffer, offset: 0, atIndex: 0)
            commandEncoder.dispatchThreadgroups(threadGroups,
                threadsPerThreadgroup: threadGroupCounts)
            commandEncoder.endEncoding()

            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()

        } catch _ {
            print("Error!")
        }

        // Transform new metal texture into image
        targetView.image = image(texture: renderingTexture)
    }

    func image(texture texture: MTLTexture) -> UIImage {
        // Get image info
        let imageSize = CGSizeMake(CGFloat(texture.width),
            CGFloat(texture.height))
        let width = Int(imageSize.width)
        let height = Int(imageSize.height)
        let imageByteCount = width * height * 4
        let bytesPerRow = width * 4
        let region = MTLRegionMake2D(0, 0, width, height)

        // Allocate the buffer if needed
        if imageBuffer == nil {
            imageBuffer = malloc(imageByteCount)
        }

        // Transfer texture info into image buffer
        texture.getBytes(imageBuffer, bytesPerRow: bytesPerRow,
            fromRegion: region, mipmapLevel: 0)

        // Get info for UIImage
        let provider = CGDataProviderCreateWithData(nil, imageBuffer,
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

    func metaballBuffer(metaballs: [Metaball]) -> MTLBuffer {
        // Create Float array for buffer
        // Exclude metaballs far from the view's bounds
        let border: CGFloat = 100
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

    func updateFrame() {
        if imageBuffer != nil {
            free(imageBuffer)
        }
        imageBuffer = nil
    }

    deinit {
        free(imageBuffer)
    }
}
