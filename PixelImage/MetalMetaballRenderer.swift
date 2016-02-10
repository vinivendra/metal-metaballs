// TODO: Optimize resources (don't allocate textures and images every frame)
// TODO: Remove references to view size from shader
// TODO: Make shader ignore metaballs that are outside a certain area of tolerance (eg ±100 from borders)

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
            let metaballInfoTexture = metaballTexture(metaballs)

            //
            let commandBuffer = context.commandQueue.commandBuffer()

            let commandEncoder = commandBuffer.computeCommandEncoder()
            commandEncoder.setComputePipelineState(pipeline)
            commandEncoder.setTexture(renderingTexture, atIndex: 0)
            commandEncoder.setTexture(metaballInfoTexture, atIndex: 1)
            commandEncoder.dispatchThreadgroups(threadGroups,
                threadsPerThreadgroup: threadGroupCounts)
            commandEncoder.endEncoding()

            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()

        } catch _ {
            print("Error!")
        }

        targetView.image = image(texture: renderingTexture)
    }

    func image(texture texture: MTLTexture) -> UIImage {
        let imageSize = CGSizeMake(CGFloat(texture.width),
            CGFloat(texture.height))
        let width = Int(imageSize.width)
        let height = Int(imageSize.height)
        let imageByteCount = width * height * 4

        if imageBuffer == nil {
            imageBuffer = malloc(imageByteCount)
        }

        let bytesPerRow = width * 4
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.getBytes(imageBuffer, bytesPerRow: bytesPerRow,
            fromRegion: region, mipmapLevel: 0)

        let provider = CGDataProviderCreateWithData(nil, imageBuffer,
            imageByteCount, nil)

        let bitsPerComponent = 8
        let bitsperPixel = 32
        let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue:
            CGImageAlphaInfo.PremultipliedLast.rawValue |
                CGBitmapInfo.ByteOrder32Big.rawValue)
        let renderingIntent = CGColorRenderingIntent.RenderingIntentDefault
        let imageRef = CGImageCreate(width, height,
            bitsPerComponent, bitsperPixel, bytesPerRow,
            colorSpaceRef, bitmapInfo, provider,
            nil, false, renderingIntent)
        let image = UIImage(CGImage: imageRef!, scale: 0.0,
            orientation: UIImageOrientation.DownMirrored)

        return image
    }

    func metaballTexture(metaballs: [Metaball]) -> MTLTexture {
        let floats: [Float] = metaballs.reduce([Float(metaballs.count)]) { (var array, metaball) -> [Float] in
            array.append(Float(metaball.midX))
            array.append(Float(metaball.midY))
            return array
        }
        let size = floats.count

        let textureDescriptor =
        MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
            .R32Float, width: size, height: 1, mipmapped: false)

        let texture = context.device.newTextureWithDescriptor(textureDescriptor)

        let region = MTLRegionMake2D(0, 0, size, 1)
        
        texture.replaceRegion(region, mipmapLevel: 0, withBytes: floats,
            bytesPerRow: sizeof(Float) * size)
        
        return texture
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

