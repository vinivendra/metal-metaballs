
import Darwin

func interpolateCubeEaseIn<T: Numeric>(_ linear: T) -> T {
    return linear ^ 3
}

func interpolateSquareEaseIn<T: Numeric>(_ linear: T) -> T {
    return linear ^ 2
}

func interpolateSquareEaseOut<T: Numeric>(_ linear: T) -> T {
    return 1 - (1 - linear) * (1 - linear)
}

func interpolateSmooth<T: Numeric>(_ linear: T) -> T {
    return ((linear) * (linear) * (linear) * ((linear) * ((linear) * 6 - 15) + 10))
}

func createStringKeyframes(_ bounces: Int = 2, elasticity: Double = 1.1, bounceSpeed: Double) -> [(time: Double, position: Double)] {
    // Setup keyframes
    var keyFrames: [(time: Double, position: Double)] = [(1, 1)]

    let overreach = elasticity - 1

    var currentBounceTime: Double = overreach / (bounceSpeed ^ Double(bounces))
    var bounceDirection = Double((bounces % 2) * 2 - 1)
    var bounceReach = overreach / (2 ^ Double(bounces - 1))
    var currentBouncePosition: Double = 1.0 + bounceDirection * bounceReach

    keyFrames.append((1.0 - currentBounceTime, currentBouncePosition))

    for i in (1..<bounces).reversed() {
        currentBounceTime += overreach / (bounceSpeed ^ Double(i + 1))
        currentBounceTime += overreach / (bounceSpeed ^ Double(i))
        bounceDirection = Double((i % 2) * 2 - 1)
        bounceReach = overreach / (2 ^ Double(i - 1))
        currentBouncePosition = 1.0 + bounceDirection * bounceReach

        keyFrames.append((1.0 - currentBounceTime, currentBouncePosition))
    }

    keyFrames.append((0, 0))

    var reversed = [(time: Double, position: Double)]()
    for keyFrame in keyFrames.reversed() {
        reversed.append(keyFrame)
    }

    return reversed
}

func interpolateSpring<T: Numeric>(_ linear: T, bounces: Int = 2, elasticity: Double = 1.1, bounceSpeed: Double = 1.0) -> T {
    let keyFrames: [(time: Double, position: Double)]
    keyFrames = createStringKeyframes(bounces, elasticity: elasticity, bounceSpeed: bounceSpeed)

    let x = linear.toDouble

    let startFrame = keyFrames.filter { $0.time < x }.last ?? (0, 0)
    let endFrame = keyFrames.filter { $0.time > x }.first ?? (1, 1)
    let adjustedX = (x - startFrame.time) / (endFrame.time - startFrame.time)
    let interpolatedX = interpolateSmooth(adjustedX)
    let position = startFrame.position + interpolatedX * (endFrame.position - startFrame.position)

    return T.fromDouble(position)
}
