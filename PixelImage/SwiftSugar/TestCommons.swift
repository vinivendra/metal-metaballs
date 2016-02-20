// TODO: Preconditions
// TODO: Test memoization
// TODO: Reorganize Swift Sugar folders
// TODO: Sugar documentation
// TODO: Add Swift Sugar to git
// TODO: Add LINT to EngineKit
// TODO: Add @warnunusedresult where appropriate

import Darwin

class Random<T: Numeric> {

    let max: Double = Double(INT32_MAX)
    let exponent: Double = 7

    init(example: T) {
        setupRandomSeed()
    }

    private func expRandom() -> Double {
        let rawRandom = Double(rand()) / max
        let exponentiated = (3 * rawRandom) ^ exponent
        return exponentiated
    }

    private func uniRandom() -> Double {
        return Double(rand()) / max
    }

    private func setupRandomSeed() {
        var now = time(nil)
        var date = tm()
        localtime_r(&now, &date)
        let day = date.tm_yday
        let year = date.tm_year
        srand(UInt32(365 * year + day))
    }

    func nonnegativeRandomNumber() -> T {
        let random = expRandom()
        return T.fromDouble(random)
    }

    func positiveRandomNumber() -> T {
        let random = expRandom()
        let result = T.fromDouble(random)

        guard result != 0 else {
            return positiveRandomNumber()
        }

        return result
    }

    func randomNumber() -> T {
        let random = expRandom()
        let signed = random * ±(Double(rand()) - max)
        return T.fromDouble(signed)
    }

    func uniformRandomNumber(from tStart: T, to tEnd: T) -> T {
        let start = tStart.toDouble
        let end = tEnd.toDouble

        let rawRandom = uniRandom()
        let interval = end - start
        let result = start + (rawRandom * interval)
        return T.fromDouble(result)
    }

    func uniformRandomNumber(start tStart: T, interval tInterval: T)
        -> T {
            let start = tStart.toDouble
            let interval = tInterval.toDouble

            let rawRandom = uniRandom()
            let result = start + (rawRandom * interval)
            return T.fromDouble(result)
    }

    func uniformRandomNumber(center tCenter: T,
        maxDeviation tInterval: T) -> T {
            let center = tCenter.toDouble
            let interval = tInterval.toDouble
            let start = T.fromDouble(center - interval / 2)

            return uniformRandomNumber(start: start, interval: tInterval)
    }

    func randomSign() -> T {
        let rawRandom = rand() % 2
        let result = Double((2 * rawRandom) - 1)
        return T.fromDouble(result)
    }

}
