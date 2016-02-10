import Foundation

extension NSNumber: DoubleValuable {
    var toDouble: Double {
        get { return self.doubleValue }
    }

    static func fromDouble(double: Double) -> Self {
        return self.init(double: double)
    }
}
