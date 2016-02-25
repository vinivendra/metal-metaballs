import UIKit

func - (left: CGPoint, right: CGPoint) -> CGVector {
    return CGVector(dx: left.x - right.x, dy: left.y - right.y)
}

func * (left: CGVector, right: CGVector) -> CGFloat {
    return (left.dx * right.dx) + (left.dy * right.dy)
}

func / (vector: CGVector, scalar: CGFloat) -> CGVector {
    return CGVector(dx: vector.dx / scalar, dy: vector.dy / scalar)
}

extension CGVector {
    var norm: CGFloat {
        get {
            let dot = self * self
            return sqrt(dot)
        }
    }

    var normalized: CGVector {
        get {
            return self / norm
        }
    }

    mutating func normalize() {
        let norm = self.norm
        dx = dx / norm
        dy = dy / norm
    }

}

extension CGFloat: DoubleValuable {
    var toDouble: Double { get {
        return Double(self)
        }
    }

    static func fromDouble(double: Double) -> CGFloat {
        return CGFloat(double)
    }

}

extension CGFloat: Numeric {}

extension CGRect {
    var x: CGFloat {
        get {
            return origin.x
        }
        set {
            origin.x = newValue
        }
    }

    var y: CGFloat {
        get {
            return origin.y
        }
        set {
            origin.y = newValue
        }
    }
}

extension CGSize {
    init(_ squareSize: CGFloat) {
        self.init(width: squareSize, height: squareSize)
    }
}

extension UIView {
    var origin: CGPoint {
        get {
            return frame.origin
        }
        set {
            frame.origin = newValue
        }
    }

    var size: CGSize {
        get {
            return frame.size
        }
        set {
            frame.size = newValue
        }
    }

    var width: CGFloat {
        get {
            return frame.width
        }
        set {
            frame.size = CGSize(width: newValue, height: height)
        }
    }

    var height: CGFloat {
        get {
            return frame.height
        }
        set {
            frame.size = CGSize(width: width, height: newValue)
        }
    }

    var middle: CGPoint {
        get {
            return CGPoint(x: origin.x + width / 2, y: origin.y + height / 2)
        }
        set {
            origin = CGPoint(x: newValue.x - width / 2, y: newValue.y - height / 2)
        }
    }

    var midX: CGFloat {
        get {
            return middle.x
        }
        set {
            middle = CGPoint(x: newValue, y: midY)
        }
    }

    var midY: CGFloat {
        get {
            return middle.y
        }
        set {
            middle = CGPoint(x: midX, y: newValue)
        }
    }
}

let screenRect = UIScreen.mainScreen().bounds
let screenWidth = screenRect.size.width
let screenHeight = screenRect.size.height
