
import UIKit

protocol MetaballDataSource {
    var metaballs: [Metaball] { get }
}

protocol MetaballRenderer {
    typealias TargetView: UIView

    func updateTargetView(targetView: TargetView, dataSource: MetaballDataSource)
}

extension MetaballRenderer {
    func createTargetView(frame frame: CGRect) -> TargetView {
        return TargetView(frame: frame)
    }
}
