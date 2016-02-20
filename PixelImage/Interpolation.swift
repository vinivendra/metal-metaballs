func interpolateCubeEaseIn<T: Numeric>(linear: T) -> T {
    return linear ^ 3
}

func interpolateSquareEaseIn<T: Numeric>(linear: T) -> T {
    return linear ^ 2
}

func interpolateSquareEaseOut<T: Numeric>(linear: T) -> T {
    return 1 - (1 - linear) * (1 - linear)
}

func interpolateSmooth<T: Numeric>(linear: T) -> T {
    return ((linear) * (linear) * (linear) * ((linear) * ((linear) * 6 - 15) + 10))
}
