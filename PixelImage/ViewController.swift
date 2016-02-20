import UIKit

class ViewController: UIViewController, MetaballDataSource {

    var metaballView: UIImageView!
    var renderer: MetalMetaballRenderer!

    let width = 350
    let height = 600

    var metaballGraph: Graph<Metaball>!
    var previousLocation: CGPoint!

    var selectedMetaball: Metaball?

    let edgeAnimationDuration: Float = 1

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
        metaballGraph.addEdge(1, 3)
        metaballGraph.addEdge(2, 3)

        let border = 20
        let metaballViewFrame = CGRect(x: border / 2, y: border / 2, width: width, height: height)
        renderer = MetalMetaballRenderer(dataSource: self, frame: metaballViewFrame)
        metaballView = renderer.targetView

        let bigView = UIView(frame: CGRect(x: 10, y: 70, width: width + border, height: height + border))
        bigView.backgroundColor = UIColor.redColor()
        bigView.addSubview(metaballView)
        view.addSubview(bigView)

        for metaball in metaballs {
            metaballView.addSubview(metaball)
        }

        addEdge(0, 2)

        renderer.state = .Running
    }

    func addEdge(i: Int, _ j: Int) {
        animateEdge(i, j, fadeIn: true)
    }

    func removeEdge(i: Int, _ j: Int) {
        animateEdge(i, j, fadeIn: false)
    }

    func animateEdge(i: Int, _ j: Int, fadeIn: Bool) {
        let parameters = EdgeAnimationParameters(startDate: NSDate(), duration: edgeAnimationDuration, fadeIn: fadeIn, i: i, j: j)
        NSTimer.scheduledTimerWithTimeInterval(1.0 / 60.0, target: self, selector: "animateEdgeWithTimer:", userInfo: parameters, repeats: true)
    }

    func animateEdge(withTimer timer: NSTimer) {
        guard let userInfo = timer.userInfo as? EdgeAnimationParameters else { preconditionFailure() }
        let (animationStart, duration, fadeIn, i, j) = (userInfo).unpack()

        let now = NSDate()
        var timeElapsed = Float(now.timeIntervalSinceDate(animationStart))

        if timeElapsed > duration {
            timer.invalidate()
            timeElapsed = duration
        }

        let linearValue = timeElapsed / duration
        let interpolatedValue = fadeIn ? interpolateSquareEaseOut(linearValue) : (1 - interpolateSquareEaseIn(linearValue))

        metaballGraph.adjacencyMatrix.set(i, j, value: interpolatedValue)
        metaballGraph.adjacencyMatrix.set(j, i, value: interpolatedValue)

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
        backgroundColor = UIColor(randomFlatColorOfShadeStyle: .Light)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
