
import UIKit

class Metaball: UIView {

    var color: UIColor

    init(position: CGPoint,
         color: UIColor = UIColor(randomFlatColorOf: .light)) {
        self.color = color
        super.init(frame: CGRect.zero)

        size = CGSize(50)
        middle = position
    }

    required init?(coder aDecoder: NSCoder) {
        self.color = UIColor(randomFlatColorOf: .light)
        super.init(coder: aDecoder)
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
    let metaball: Metaball

    func unpack() -> (startDate: Date, duration: Float, origin: CGPoint,
		destination: CGPoint, metaball: Metaball)
	{
        return (startDate, duration, origin, destination, metaball)
    }

    init(startDate: Date, duration: Float, origin: CGPoint,
         destination: CGPoint, metaball: Metaball)
	{
        self.startDate = startDate
        self.duration = duration
        self.origin = origin
        self.destination = destination
        self.metaball = metaball
    }
}
