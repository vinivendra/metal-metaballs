
import UIKit

class ImageMetaballRenderer: MetaballRenderer {
    
    typealias TargetView = UIImageView

    var supportsDynamicRendering: Bool { get {
        return false
        }
    }

    let targetView = TargetView()

    let dataSource: MetaballDataSource

    required init(dataSource: MetaballDataSource) {
        self.dataSource = dataSource
    }

    func updateTargetView() {
        let width = Int(targetView.width)
        let height = Int(targetView.height)
        let metaballs = dataSource.metaballs

        let bytesPerPixel = 4;
        let bytesPerRow = bytesPerPixel * width;
        let bitsPerComponent = 8;

        var matrix = PixelMatrix(width: width, height: height)
        for i in 0..<width {
            for j in 0..<height {
                let pixelPosition = CGPoint(x: i, y: j)

                var sum: CGFloat = 0

                for combo in metaballs.combos() {
                    let metaball1 = combo[0].middle
                    let metaball2 = combo[1].middle

                    let metaball1Vector = metaball1 - pixelPosition
                    let metaball2Vector = metaball2 - pixelPosition

                    let direction1 = metaball1Vector.normalized
                    let direction2 = metaball2Vector.normalized

                    let cos = direction1 * direction2

                    let value1 = 255000 / (metaball1Vector * metaball1Vector + 1)
                    let value2 = 255000 / (metaball2Vector * metaball2Vector + 1)

                    let v = gradient(value1 + value2)
                    let link = ((1 - cos) * 0.5) ^ 50

                    let weightedLink = 128 * CGFloat(link)
                    let weightedValue = 0.6 * CGFloat(v)

                    sum += weightedValue + weightedLink
                }

                let result = threshold(sum)

                matrix.set(x: i, y: j, r:0, g:result/2, b:result)
            }
        }

        let buffer: UnsafeMutablePointer<Void> = UnsafeMutablePointer(matrix.pixels)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGBitmapContextCreate(buffer, width, height, bitsPerComponent, bytesPerRow, colorSpace, CGImageAlphaInfo.PremultipliedLast.rawValue | CGBitmapInfo.ByteOrder32Big.rawValue);
        
        let cgImage = CGBitmapContextCreateImage(context)
        let image = UIImage(CGImage: cgImage!)
        targetView.image = image
    }
}

struct PixelMatrix {
    var pixels: [UInt8]

    let width: Int
    let height: Int

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        pixels = [UInt8](count: (4 * width * height), repeatedValue: 255)
    }

    mutating func set(x x: Int, y: Int, r: UInt8, g: UInt8, b: UInt8) {
        let index = 4 * (y * width + x)
        pixels[index    ] = r
        pixels[index + 1] = g
        pixels[index + 2] = b
    }

    mutating func set(x x: Int, y: Int, white: UInt8) {
        let index = 4 * (y * width + x)
        pixels[index    ] = white
        pixels[index + 1] = white
        pixels[index + 2] = white
    }
}

func threshold(value: CGFloat) -> UInt8 {
    return value < 128 ? 0 : 255
}

func gradient(value: CGFloat) -> UInt8 {
    return UInt8(min(max(value, 0), CGFloat(255)))
}

func thresholdf(value value: CGFloat, cap: CGFloat = 0.5) -> CGFloat {
    return value < cap ? 0 : 1.0
}
