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

func * (vector: CGVector, scalar: Float) -> CGVector {
	return CGVector(dx: vector.dx * CGFloat(scalar), dy: vector.dy * CGFloat(scalar))
}

func + (point: CGPoint, vector: CGVector) -> CGPoint {
	return CGPoint(x: point.x + vector.dx, y: point.y + vector.dy)
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
