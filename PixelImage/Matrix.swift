
import UIKit

class Graph<T> {
    var adjacencyMatrix: Matrix
    var vertices: [T]

    init(vertices: [T]) {
        let size = vertices.count

        self.vertices = vertices
        self.adjacencyMatrix = Matrix(size: size)
    }

    func addEdge(i: Int, _ j: Int) {
        adjacencyMatrix.set(i, j)
        adjacencyMatrix.set(j, i)
    }

    func removeEdge(i: Int, _ j: Int) {
        adjacencyMatrix.reset(i, j)
        adjacencyMatrix.reset(j, i)
    }
}

struct Matrix: CustomStringConvertible {
    private var buffer: [CGFloat]

    let size: Int

    init(size: Int) {
        buffer = [CGFloat](count: size * size, repeatedValue: 0.0)
        self.size = size
    }

    func get(i: Int, j: Int) -> CGFloat {
        return buffer[index(i, j)]
    }

    mutating func set(i: Int, _ j: Int, value: CGFloat = 1.0) {
        buffer[index(i, j)] = value
    }

    mutating func reset(i: Int, _ j: Int) {
        buffer[index(i, j)] = 0.0
    }

    private func index(i: Int, _ j: Int) -> Int {
        return j * size + i
    }

    var description: String {
        get {
            var result = ""
            for (index, value) in buffer.enumerate() {
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
