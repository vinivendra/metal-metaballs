extension Dictionary {
    subscript(keys: [Key]) -> [Value] {
        get {
            return keys.unwrappedMap { self[$0] }
        }
        set (values) {
            for (key, value) in zip(keys, values) {
                self[key] = value
            }
        }
    }
}
