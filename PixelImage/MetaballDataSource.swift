import Metal

protocol MetaballDataSource {
    var metaballGraph: Graph<Metaball>! { get }
}

extension MetaballDataSource {
    var metaballs: [Metaball]! {
        get {
            return metaballGraph.vertices
        }
    }

}
