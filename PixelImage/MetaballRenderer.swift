
import UIKit

protocol MetaballDataSource {
    var metaballs: [Metaball] { get }
}

protocol MetaballRenderer {
    typealias TargetView: UIView

    static func updateTargetView(targetView: TargetView, dataSource: MetaballDataSource)
}

extension MetaballRenderer {
    static func createTargetView(frame frame: CGRect) -> TargetView {
        return TargetView(frame: frame)
    }
}
