import Darwin

infix operator ^ { associativity right precedence 131 }

func ^ <T: DoubleValuable>(left: T, right: T) -> T {
    return T.fromDouble(pow(left.toDouble, right.toDouble))
}

func ^ (left: Double, right: Double) -> Double {
    return pow(left, right)
}

func ^ (left: Float, right: Float) -> Float {
    return powf(left, right)
}
