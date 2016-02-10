import Darwin

infix operator ==~ { associativity right precedence 130 }

func ==~ (left: DoubleValuable, right: DoubleValuable) -> Bool {
    let leftDouble = left.toDouble
    let rightDouble = right.toDouble
    let epsilon = abs(leftDouble/10000)

    return (leftDouble <= rightDouble + epsilon) &&
        (leftDouble >= rightDouble - epsilon)
}
