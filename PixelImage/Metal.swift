import Metal
import UIKit

class MTLContext {
    let device: MTLDevice
    let library: MTLLibrary
    let commandQueue: MTLCommandQueue

    init(device: MTLDevice = MTLCreateSystemDefaultDevice()!) {
        self.device = device
        self.library = device.newDefaultLibrary()!
        self.commandQueue = device.makeCommandQueue()
    }
}

class MTLComputeContext {
    var texture: MTLTexture
    var imageBuffer: UnsafeMutableRawPointer

    init(size: CGSize, texture: MTLTexture) {
        let width = Int(size.width)
        let height = Int(size.height)
        let imageByteCount = width * height * 4
        imageBuffer = malloc(imageByteCount)

        self.texture = texture
    }

    func updateToSize(_ size: CGSize, texture: MTLTexture) {
        free(imageBuffer)

        let width = Int(size.width)
        let height = Int(size.height)
        let imageByteCount = width * height * 4
        imageBuffer = malloc(imageByteCount)

        self.texture = texture
    }

    deinit {
        free(imageBuffer)
    }
}
