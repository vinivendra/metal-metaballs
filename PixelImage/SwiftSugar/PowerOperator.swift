import Darwin

precedencegroup PowerPrecedence {
	higherThan: MultiplicationPrecedence
	associativity: right
}

//
infix operator ^: PowerPrecedence

func ^ <T: DoubleValuable>(left: T, right: T) -> T {
    return T.fromDouble(pow(left.toDouble, right.toDouble))
}

func ^ (left: Double, right: Double) -> Double {
    return pow(left, right)
}

func ^ (left: Float, right: Float) -> Float {
    return powf(left, right)
}
