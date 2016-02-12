
import UIKit

class Graph<T> {
    var adjacencyMatrix: Matrix
    var vertices: [T]

    var size: Int {
        get {
            return vertices.count
        }
    }

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
    var buffer: [Float]

    let size: Int

    init(size: Int) {
        buffer = [Float](count: size * size, repeatedValue: 0.0)
        self.size = size
    }

    func get(i: Int, j: Int) -> Float {
        return buffer[index(i, j)]
    }

    mutating func set(i: Int, _ j: Int, value: Float = 1.0) {
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

class EdgeAnimationParameters {
    let startDate: NSDate
    let duration: Float
    let fadeIn: Bool
    let i: Int
    let j: Int

    func unpack() -> (startDate: NSDate, duration: Float, fadeIn: Bool, i: Int, j: Int) {
        return (startDate, duration, fadeIn, i, j)
    }

    init(startDate: NSDate, duration: Float, fadeIn: Bool, i: Int, j: Int) {
        self.startDate = startDate
        self.duration = duration
        self.fadeIn = fadeIn
        self.i = i
        self.j = j
    }
}
