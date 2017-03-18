
import UIKit

// TODO: MTMVertex should probably be a struct
// <- Animations refactor
class MTMVertex {
    var color: UIColor
	var position: CGPoint

    init(position: CGPoint,
         color: UIColor = UIColor(randomFlatColorOf: .light)) {
        self.color = color
        self.position = position
    }
}

class EdgeAnimationParameters {
    let startDate: Date
    let duration: Float
    let fadeIn: Bool
    let i: Int
    let j: Int

    func unpack() -> (startDate: Date, duration: Float, fadeIn: Bool,
		i: Int, j: Int)
	{
        return (startDate, duration, fadeIn, i, j)
    }

    init(startDate: Date, duration: Float, fadeIn: Bool, i: Int, j: Int) {
        self.startDate = startDate
        self.duration = duration
        self.fadeIn = fadeIn
        self.i = i
        self.j = j
    }
}

class VertexAnimationParameters {
    let startDate: Date
    let duration: Float
    let origin: CGPoint
    let destination: CGPoint
    let metaball: MTMVertex

    func unpack() -> (startDate: Date, duration: Float, origin: CGPoint,
		destination: CGPoint, metaball: MTMVertex)
	{
        return (startDate, duration, origin, destination, metaball)
    }

    init(startDate: Date, duration: Float, origin: CGPoint,
         destination: CGPoint, metaball: MTMVertex)
	{
        self.startDate = startDate
        self.duration = duration
        self.origin = origin
        self.destination = destination
        self.metaball = metaball
    }
}
