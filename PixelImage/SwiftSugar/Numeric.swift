protocol DoubleValuable {
    var toDouble: Double { get }

    static func fromDouble(double: Double) -> Self
}

postfix operator ++ { }

protocol Incrementable {
    postfix func ++ (inout _: Self) -> Self
}

protocol Numeric: DoubleValuable, Incrementable, Comparable,
    IntegerLiteralConvertible {

    @warn_unused_result func / (lhs: Self, rhs: Self) -> Self
    @warn_unused_result func - (lhs: Self, rhs: Self) -> Self
    @warn_unused_result func + (lhs: Self, rhs: Self) -> Self
    @warn_unused_result func * (lhs: Self, rhs: Self) -> Self
    postfix func ++ (inout _: Self) -> Self
}

protocol FastNumeric: Numeric {}

extension Double: FastNumeric {
    var toDouble: Double {
        get {
            return self
        }
    }

    static func fromDouble(double: Double) -> Double {
        return double
    }

}

extension Float: FastNumeric {
    var toDouble: Double {
        get {
            return Double(self)
        }
    }

    static func fromDouble(double: Double) -> Float {
        return Float(double)
    }

}

extension Int: FastNumeric {
    var toDouble: Double {
        get {
            return Double(self)
        }
    }

    static func fromDouble(double: Double) -> Int {
        return Int(double)
    }

}

//
extension Int {

    func times(@noescape block: () throws -> ()) rethrows {
        for _ in 1...self {
            try block()
        }
    }

}
