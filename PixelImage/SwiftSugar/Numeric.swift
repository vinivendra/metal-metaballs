protocol DoubleValuable {
    var toDouble: Double { get }

    static func fromDouble(_ double: Double) -> Self
}

postfix operator ++ { }

protocol Incrementable {
    postfix func ++ (_: inout Self) -> Self
}

protocol Numeric: DoubleValuable, Incrementable, Comparable,
    ExpressibleByIntegerLiteral {

    @warn_unused_result func / (lhs: Self, rhs: Self) -> Self
    @warn_unused_result func - (lhs: Self, rhs: Self) -> Self
    @warn_unused_result func + (lhs: Self, rhs: Self) -> Self
    @warn_unused_result func * (lhs: Self, rhs: Self) -> Self
    postfix func ++ (_: inout Self) -> Self
}

protocol FastNumeric: Numeric {}

extension Double: FastNumeric {
    var toDouble: Double {
        get {
            return self
        }
    }

    static func fromDouble(_ double: Double) -> Double {
        return double
    }

}

extension Float: FastNumeric {
    var toDouble: Double {
        get {
            return Double(self)
        }
    }

    static func fromDouble(_ double: Double) -> Float {
        return Float(double)
    }

}

extension Int: FastNumeric {
    var toDouble: Double {
        get {
            return Double(self)
        }
    }

    static func fromDouble(_ double: Double) -> Int {
        return Int(double)
    }

}
