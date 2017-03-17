func interpolateEaseIn(_ x: Float) -> Float {
    return x ^ 2
}

func interpolateEaseOut(_ x: Float) -> Float {
    return 1 - (1 - x) * (1 - x)
}

func interpolateSmooth(_ x: Float) -> Float {
    return ((x) * (x) * (x) * ((x) * ((x) * 6 - 15) + 10))
}
