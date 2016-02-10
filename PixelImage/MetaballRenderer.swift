
import UIKit

protocol MetaballDataSource {
    var metaballs: [Metaball] { get }
}

protocol MetaballRenderer {
    typealias TargetView: UIView

    var targetView: TargetView { get }

    init(dataSource: MetaballDataSource)

    func updateTargetView()
}
