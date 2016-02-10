extension SequenceType {
    func unwrappedMap<T>
        (@noescape transform: (Self.Generator.Element) throws -> T?) rethrows
        -> [T] {
            return try self.reduce( [T]() ) {
                (var accumulator: [T], element: Self.Generator.Element) -> [T] in

                let transformed = try transform(element)
                if let unwrapped = transformed {
                    accumulator.append(unwrapped)
                }

                return accumulator
            }
    }
}
