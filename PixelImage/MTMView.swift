import UIKit

class MTMView: UIView {
	var renderer: MetalMetaballRenderer!

	var targetView: UIImageView!

	override func layoutSubviews() {
		super.layoutSubviews()
		renderer?.updateSize(to: frame.size)
	}

	func commonInit(size: CGSize? = nil) {
		self.renderer = MetalMetaballRenderer(size: size)
		self.targetView = renderer.targetView

		backgroundColor = .orange
		targetView.backgroundColor = .blue

		addSubview(targetView)
		fillWithSubview(targetView)
	}

	init() {
		super.init(frame: .zero)
		commonInit()
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit(size: frame.size)
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}
}
