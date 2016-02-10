import Metal

class MTLContext {
    let device: MTLDevice
    let library: MTLLibrary
    let commandQueue: MTLCommandQueue

    init(device: MTLDevice = MTLCreateSystemDefaultDevice()!) {
        self.device = device
        self.library = device.newDefaultLibrary()!
        self.commandQueue = device.newCommandQueue()
    }
}
