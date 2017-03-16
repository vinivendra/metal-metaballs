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

		view.backgroundColor = UIColor.white

		let recognizer = UIPanGestureRecognizer(target: self,
		                                        action: "handlePan:")
		view.addGestureRecognizer(recognizer)

		var positions = [CGPoint]()
		positions.append(CGPoint(
			x: Double(screenWidth) / 2,
			y: Double(screenHeight) / 2))
		for i in 1...5 {
			let sine = sin(Double(i) * 2 * M_PI / 5)
			let cosine = cos(Double(i) * 2 * M_PI / 5)
			let radius: Double = 150
			let x = Double(screenWidth) / 2 + sine * radius
			let y = Double(screenHeight) / 2 + cosine * radius
			positions.append(CGPoint(x: x, y: y))
		}

		let colors =
			[UIColor(red255: 110, green: 220, blue: 220, alpha: 1.0),
			 UIColor(red255: 250, green: 235, blue: 50, alpha: 1.0),
			 UIColor(red255: 110, green: 220, blue: 220, alpha: 1.0),
			 UIColor(red255: 90, green: 170, blue: 170, alpha: 1.0),
			 UIColor(red255: 90, green: 170, blue: 170, alpha: 1.0),
			 UIColor(red255: 110, green: 220, blue: 220, alpha: 1.0)]
		let metaballs = zip(positions, colors).map {
			Metaball(position: $0.0, color: $0.1)
		}

		metaballGraph = Graph(vertices: metaballs)

		let metaballViewFrame = screenRect
		renderer = MetalMetaballRenderer(dataSource: self,
		                                 frame: metaballViewFrame)
		metaballView = renderer.targetView
		view.addSubview(metaballView)

		for metaball in metaballs {
			metaballView.addSubview(metaball)
		}

		delay(1.0) {
			self.addEdge(0, 1)
			self.addEdge(0, 2)
			self.addEdge(0, 3)
			self.addEdge(0, 4)
			self.addEdge(0, 5)
		}

		delay(2.3) {
			self.removeEdge(0, 1)
			self.removeEdge(0, 2)
			self.removeEdge(0, 3)
			self.removeEdge(0, 4)
			self.removeEdge(0, 5)
		}

		delay(4) {
			for i in 1...5 {
				UIView.animate(withDuration: 1.0, delay: 0,
				                           options: UIViewAnimationOptions(),
				                           animations: { () -> Void in
					let sine = sin(Double(i) * 2 * M_PI / 5)
					let cosine = cos(Double(i) * 2 * M_PI / 5)
					let radius: Double = 85
					let x = Double(screenWidth) / 2 + sine * radius
					let y = Double(screenHeight) / 2 + cosine * radius
					let metaball = metaballs[i]
					self.animateMetaball(metaball, toPoint: CGPoint(x: x, y: y))
					}, completion: nil)
			}
		}

		delay(6) { () -> () in
			for i in 1...5 {
				UIView.animate(withDuration: 1.0, delay: 0,
				                           usingSpringWithDamping: 0.5,
				                           initialSpringVelocity: 0,
				                           options: UIViewAnimationOptions(),
				                           animations: { () -> Void in
					let sine = sin(Double(i) * 2 * M_PI / 5)
					let cosine = cos(Double(i) * 2 * M_PI / 5)
					let radius: Double = 150
					let x = Double(screenWidth) / 2 + sine * radius
					let y = Double(screenHeight) / 2 + cosine * radius
					let metaball = metaballs[i]
					self.animateMetaball(metaball, toPoint: CGPoint(x: x, y: y))
					}, completion: nil)
			}
		}

		renderer.state = .running
	}

	func addEdge(_ i: Int, _ j: Int) {
		animateEdge(i, j, fadeIn: true)
	}

	func removeEdge(_ i: Int, _ j: Int) {
		animateEdge(i, j, fadeIn: false)
	}

	func animateMetaball(_ metaball: Metaball, toPoint destination: CGPoint) {
		let parameters = VertexAnimationParameters(startDate: Date(),
		                                           duration: 1.0,
		                                           origin: metaball.center,
		                                           destination: destination,
		                                           metaball: metaball)
		Timer.scheduledTimer(
			timeInterval: 1.0 / 60.0,
			target: self,
			selector: "animateMetaballWithTimer:",
			userInfo: parameters,
			repeats: true)
	}

	func animateMetaball(withTimer timer: Timer) {
		guard let userInfo = timer.userInfo as? VertexAnimationParameters else {
			preconditionFailure()
		}
		let (animationStart, duration, origin, destination, metaball) =
			(userInfo).unpack()

		let now = Date()
		var timeElapsed = Float(now.timeIntervalSince(animationStart))

		if timeElapsed > duration {
			timer.invalidate()
			timeElapsed = duration
		}

		let linearValue = timeElapsed / duration
		let interpolatedValue = interpolateSmooth(linearValue)
		print(interpolatedValue)

		let position = origin + ((destination - origin) * interpolatedValue)
		metaball.center = position

		renderer.state = .running
	}

	func animateEdge(_ i: Int, _ j: Int, fadeIn: Bool) {
		let parameters = EdgeAnimationParameters(startDate: Date(),
		                                         duration: edgeAnimationDuration,
		                                         fadeIn: fadeIn,
		                                         i: i,
		                                         j: j)
		Timer.scheduledTimer(
			timeInterval: 1.0 / 60.0,
			target: self,
			selector: "animateEdgeWithTimer:",
			userInfo: parameters,
			repeats: true)
	}

	func animateEdge(withTimer timer: Timer) {
		guard let userInfo = timer.userInfo as? EdgeAnimationParameters else {
			preconditionFailure()
		}
		let (animationStart, duration, fadeIn, i, j) = (userInfo).unpack()

		let now = Date()
		var timeElapsed = Float(now.timeIntervalSince(animationStart))

		if timeElapsed > duration {
			timer.invalidate()
			timeElapsed = duration
		}

		let linearValue = timeElapsed / duration
		let interpolatedValue = fadeIn ?
			interpolateSquareEaseOut(linearValue) :
			(1 - interpolateSquareEaseIn(linearValue))

		metaballGraph.adjacencyMatrix.set(i, j, value: interpolatedValue)
		metaballGraph.adjacencyMatrix.set(j, i, value: interpolatedValue)

		renderer.state = .running
	}

	func handlePan(_ recognizer: UIPanGestureRecognizer) {
		let location = recognizer.location(in: metaballView)

		if selectedMetaball == nil {
			for metaball in metaballs where
				abs(metaball.midX - location.x) < 50 &&
					abs(metaball.midY - location.y) < 50
			{
				selectedMetaball = metaball
				break
			}
		}

		guard selectedMetaball != nil else { return }

		selectedMetaball?.middle = location

		renderer.state = .running

		if recognizer.state == .ended {
			selectedMetaball = nil
		}
	}

}
