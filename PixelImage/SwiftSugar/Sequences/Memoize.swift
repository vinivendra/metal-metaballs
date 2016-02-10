protocol MemoizedSequence: LazySequenceType {
    typealias IndexType: Hashable
    typealias ReturnType

    init(first: IndexType,
        incrementer: ((inout IndexType) -> Void),
        memoizedFunction: (IndexType -> ReturnType))
}


struct HashMemoizedSequence <IndexType: Hashable, ReturnType>:
MemoizedSequence {

    let memoizedFunction: (IndexType -> ReturnType)
    let increment: ((inout IndexType) -> Void)
    let firstIndex: IndexType

    var index: IndexType

    init(first: IndexType,
        incrementer: ((inout IndexType) -> Void),
        memoizedFunction: (IndexType -> ReturnType)) {

            self.firstIndex = first

            self.index = first
            self.increment = incrementer
            self.memoizedFunction = memoizedFunction
    }

    init(first: IndexType,
        incrementer: ((inout IndexType) -> Void),
        closure: ((IndexType -> ReturnType, IndexType) -> ReturnType)) {
            let memoizedFunction = memoize(closure)

            self.init(first: first, incrementer: incrementer,
                memoizedFunction: memoizedFunction)
    }

    init(first: IndexType,
        incrementer: ((inout IndexType) -> Void),
        function: (IndexType -> ReturnType)) {

            let memoizedFunction = memoize(function)

            self.init(first: first, incrementer: incrementer,
                memoizedFunction: memoizedFunction)
    }
}

extension HashMemoizedSequence: GeneratorType {
    mutating func next() -> ReturnType? {
        let result = memoizedFunction(index)
        increment(&index)
        return result
    }
}

extension HashMemoizedSequence: LazySequenceType {
    func generate() -> HashMemoizedSequence {
        return self
    }
}

extension HashMemoizedSequence where ReturnType: Comparable {
    @warn_unused_result
    func contains(element: ReturnType) -> Bool {
        var index = firstIndex

        while true {
            let value = memoizedFunction(index)

            if value == element {
                return true
            } else if value > element {
                return false
            }

            increment(&index)
        }
    }
}

extension HashMemoizedSequence where IndexType: Incrementable {
    init(first: IndexType,
        closure: ((IndexType -> ReturnType, IndexType) -> ReturnType)) {
            self.firstIndex = first
            self.index = first
            self.increment = { (inout index: IndexType) in
                index++
            }
            self.memoizedFunction = memoize(closure)
    }

    init(first: IndexType,
        function: (IndexType -> ReturnType)) {
            self.firstIndex = first
            self.index = first
            self.increment = { (inout index: IndexType) in
                index++
            }
            self.memoizedFunction = memoize(function)
    }
}

extension HashMemoizedSequence where IndexType: Incrementable,
    IndexType: IntegerLiteralConvertible {
    init(_ closure: ((IndexType -> ReturnType, IndexType) -> ReturnType)) {
            self.firstIndex = 1
            self.index = 1
            self.increment = { (inout index: IndexType) in
                index++
            }
            self.memoizedFunction = memoize(closure)
    }

    init(_ function: (IndexType -> ReturnType)) {
            self.firstIndex = 1
            self.index = 1
            self.increment = { (inout index: IndexType) in
                index++
            }
            self.memoizedFunction = memoize(function)
    }
}

func memoize <H: Hashable, R> (closure: ((H -> R, H) -> R) ) -> (H -> R) {

    var table = [H : R]()

    var auxiliaryFunction: (H -> R)!
    auxiliaryFunction = { index in
        if let result = table[index] {
            return result
        }

        let result = closure(auxiliaryFunction, index)
        table[index] = result

        return result
    }

    return auxiliaryFunction
}

func memoize <H: Hashable, R> (function: (H -> R) ) -> (H -> R) {

    var table = [H : R]()

    let result: (H -> R) = { index in
        if let result = table[index] {
            return result
        }

        let result = function(index)
        table[index] = result

        return result
    }

    return result
}
