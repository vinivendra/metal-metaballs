
import UIKit

class Metaball: UIView {

    var color: UIColor

    init(position: CGPoint, color: UIColor = UIColor(randomFlatColorOfShadeStyle: .Light)) {
        self.color = color
        super.init(frame: CGRect.zero)

        size = CGSize(50)
        middle = position
    }

    required init?(coder aDecoder: NSCoder) {
        color = UIColor(randomFlatColorOfShadeStyle: .Light)
        super.init(coder: aDecoder)
    }
}
