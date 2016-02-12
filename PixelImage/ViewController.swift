
import UIKit

class ViewController: UIViewController, MetaballDataSource {

    var metaballView: UIImageView!
    var renderer: MetalMetaballRenderer!

    let width = 350
    let height = 600

    var metaballGraph: Graph<Metaball>!
    var previousLocation: CGPoint!

    var selectedMetaball: Metaball?

    override func viewDidLoad() {
        super.viewDidLoad()

        let recognizer = UIPanGestureRecognizer(target: self, action: "handlePan:")
        view.addGestureRecognizer(recognizer)

        let metaballs = [CGPoint(x: 70, y: 70), CGPoint(x: 270, y: 70), CGPoint(x: 270, y: 470), CGPoint(x: 70, y: 470)].map {
            Metaball(position: $0)
        }
        metaballGraph = Graph(vertices: metaballs)
        metaballGraph.addEdge(0, 1)
        metaballGraph.addEdge(0, 3)
        metaballGraph.addEdge(1, 2)
        metaballGraph.addEdge(2, 3)

        let border = 20
        let metaballViewFrame = CGRect(x: border/2, y: border/2, width: width, height: height)
        renderer = MetalMetaballRenderer(dataSource: self, frame: metaballViewFrame)
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

        if selectedMetaball == nil {
            for metaball in metaballs where
                abs(metaball.midX - location.x) < 50 && abs(metaball.midY - location.y) < 50 {
                    selectedMetaball = metaball
                    break
            }
        }

        guard selectedMetaball != nil else { return }

        selectedMetaball?.middle = location

        renderer.state = .Running

        if recognizer.state == .Ended {
            selectedMetaball = nil
        }
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
