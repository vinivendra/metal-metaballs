let doubleMax: Double = 1E+37
let doubleMin: Double = -1E+37
let floatMax: Float = 1E+37
let floatMin: Float = -1E+37
let int32Max: Int = 0x7fffffff
let int32Min: Int = -0x7fffffff - 1

infix operator ≤ { associativity right precedence 131 }

func ≤ <T: Numeric>
    (left: T, right: T) -> T {

    if left < right {
        return left
    } else {
        return -0x7fffffff
    }
}

//
infix operator ≤= { associativity right precedence 131 }

func ≤= <T: Numeric>
    (left: T, right: T) -> T {

        if left <= right {
            return left
        } else {
            return -0x7fffffff
        }
}

//
infix operator ≥ { associativity right precedence 131 }

func ≥ <T: Numeric>
    (left: T, right: T) -> T {

        if left > right {
            return left
        } else {
            return 0x7fffffff
        }
}

//
infix operator ≥= { associativity right precedence 131 }

func ≥= <T: Numeric>
    (left: T, right: T) -> T {

        if left >= right {
            return left
        } else {
            return 0x7fffffff
        }
}
