import UIKit

class MTMGraph {

	var vertices: [MTMVertex] {
		didSet {
			if vertices.count != oldValue.count {
				self.resize(to: vertices.count)
			}
		}
	}
    private(set) var edges: MTMMatrix
	private(set) var size: Int

	init(size: Int) {
		self.size = size
		self.vertices = [MTMVertex](repeating: MTMVertex(), count: size)
		self.edges = MTMMatrix(size: size)
	}

	init(vertices: [MTMVertex]) {
		self.size = vertices.count
		self.vertices = vertices
		self.edges = MTMMatrix(size: size)
	}

	func addVertex(_ newVertex: MTMVertex) {
		vertices.append(newVertex)
		self.resize(to: vertices.count)
	}

	func addVertices(_ newVertices: [MTMVertex]) {
		vertices.append(contentsOf: newVertices)
		self.resize(to: vertices.count)
	}

    func addEdge(_ i: Int, _ j: Int) {
        setEdgeValue(i, j, value: 1.0)
    }

    func removeEdge(_ i: Int, _ j: Int) {
        setEdgeValue(i, j, value: 0.0)
    }

	func setEdgeValue(_ i: Int, _ j: Int, value: Float) {
		edges.set(i, j, value: value)
		edges.set(j, i, value: value)
	}

	private func resize(to newSize: Int) {
		size = newSize
		edges.resize(toCapacity: newSize)
	}
}

// TODO: MTMVertex should probably be a struct
// <- Animations refactor
class MTMVertex {
	var color: UIColor
	var position: CGPoint

	init(position: CGPoint = .zero,
	     color: UIColor = UIColor(randomFlatColorOf: .light)) {
		self.color = color
		self.position = position
	}
}

struct MTMMatrix: CustomStringConvertible {
    private(set) var buffer: [Float]
    private(set) var size: Int

    init(size: Int) {
        buffer = [Float](repeating: 0.0, count: size * size)
        self.size = size
    }

	//
	private func index(_ i: Int, _ j: Int) -> Int {
		return index(i, j, size: size)
	}

	private func index(_ i: Int, _ j: Int, size: Int) -> Int {
		return j * size + i
	}

	//
    func get(_ i: Int, _ j: Int) -> Float {
        return buffer[index(i, j)]
    }

    mutating func set(_ i: Int, _ j: Int, value: Float = 1.0) {
        buffer[index(i, j)] = value
    }

	//
	func resized(toCapacity newCapacity: Int) -> MTMMatrix {
		var newMatrix = MTMMatrix(size: newCapacity)
		let minSize = min(self.size, newCapacity)
		for (i, j) in zip(0..<minSize, 0..<minSize) {
			newMatrix.set(i, j, value: self.get(i, j))
		}
		return newMatrix
	}

	mutating func resize(toCapacity newSize: Int) {
		var newBuffer = [Float](repeating: 0.0,
		                        count: newSize * newSize)
		let minSize = min(self.size, newSize)
		for (i, j) in zip(0..<minSize, 0..<minSize) {
			newBuffer[index(i, j, size: newSize)] = self.get(i, j)
		}
		self.buffer = newBuffer
		self.size = newSize
	}

	//
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
