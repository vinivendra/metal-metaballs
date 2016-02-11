
import UIKit

class ViewController: UIViewController, MetaballDataSource {

    typealias Renderer = MetalMetaballRenderer // ImageMetaballRenderer // MetalMetaballRenderer
    typealias TargetView = Renderer.TargetView

    var metaballView: TargetView!
    var renderer: Renderer!

    let width = 350
    let height = 600

    var metaballs = [CGPoint(x: 70, y: 70), CGPoint(x: 270, y: 470), CGPoint(x: 270, y: 70), CGPoint(x: 70, y: 470)].map {
        Metaball(position: $0)
    }
    var previousLocation: CGPoint!

    override func viewDidLoad() {
        super.viewDidLoad()

        let recognizer = UIPanGestureRecognizer(target: self, action: "handlePan:")
        view.addGestureRecognizer(recognizer)

        let border = 20
        let metaballViewFrame = CGRect(x: border/2, y: border/2, width: width, height: height)
        renderer = Renderer(dataSource: self, frame: metaballViewFrame)
        metaballView = renderer.targetView

        let bigView = UIView(frame: CGRect(x: 10, y: 70, width: width + border, height: height + border))
        bigView.backgroundColor = UIColor.redColor()
        bigView.addSubview(metaballView)
        view.addSubview(bigView)

        for metaball in metaballs {
            metaballView.addSubview(metaball)
        }

        renderer.state = .Running
    }

    func handlePan(recognizer: UIPanGestureRecognizer) {
        let location = recognizer.locationInView(metaballView)

        var selectedMetaball: UIView?

        for metaball in metaballs where
            abs(metaball.midX - location.x) < 50 && abs(metaball.midY - location.y) < 50 {
                selectedMetaball = metaball
                break
        }

        selectedMetaball?.middle = location

        renderer.state = .Running
    }
}

class Metaball: UIView {

    init(position: CGPoint) {
        super.init(frame: CGRect.zero)

        size = CGSize(50)
        middle = position
        backgroundColor = UIColor(red: 0.1306, green: 0.7522, blue: 0.0307, alpha: 0.3)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
