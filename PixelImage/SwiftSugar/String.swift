extension String: DoubleValuable {
    var toDouble: Double {
        get { return Double(self) ?? Double(0) }
    }

    static func fromDouble(double: Double) -> String {
        return "\(double)"
    }
}
