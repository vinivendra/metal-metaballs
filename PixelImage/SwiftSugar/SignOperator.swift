prefix operator ± { }

prefix func ± <T: Numeric>(number: T) -> T {

    if number > 0 {
        return 1
    } else if number == 0 {
        return 0
    } else {
        return -1
    }
}
