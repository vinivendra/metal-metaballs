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
	var size: (width: Int, height: Int)

	init(width: Int, height: Int, texture: MTLTexture) {
        let imageByteCount = width * height * 4
        imageBuffer = malloc(imageByteCount)

        self.texture = texture

		self.size = (width, height)
    }

    deinit {
        free(imageBuffer)
    }
}
