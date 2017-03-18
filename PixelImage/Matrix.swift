import UIKit

class MTMGraph {
    var adjacencyMatrix: Matrix

	var size: Int {
		return adjacencyMatrix.size
	}

	init(size: Int) {
        self.adjacencyMatrix = Matrix(size: size)
    }

    func addEdge(_ i: Int, _ j: Int) {
        adjacencyMatrix.set(i, j)
        adjacencyMatrix.set(j, i)
    }

    func removeEdge(_ i: Int, _ j: Int) {
        adjacencyMatrix.reset(i, j)
        adjacencyMatrix.reset(j, i)
    }
}

struct Matrix: CustomStringConvertible {
    var buffer: [Float]

    let size: Int

    init(size: Int) {
        buffer = [Float](repeating: 0.0, count: size * size)
        self.size = size
    }

    func get(_ i: Int, j: Int) -> Float {
        return buffer[index(i, j)]
    }

    mutating func set(_ i: Int, _ j: Int, value: Float = 1.0) {
        buffer[index(i, j)] = value
    }

    mutating func reset(_ i: Int, _ j: Int) {
        buffer[index(i, j)] = 0.0
    }

    fileprivate func index(_ i: Int, _ j: Int) -> Int {
        return j * size + i
    }

    var description: String {
        get {
            var result = ""
            for (index, value) in buffer.enumerated() {
                result = result + "\(value)"
                if index % size == size - 1 {
                    result = result + "\n"
                } else {
                    result = result + " "
                }
            }
            return result
        }
    }
}
