import Metal

protocol MetaballDataSource {
    var metaballGraph: MTMGraph! { get }
	var metaballs: [MTMVertex]! { get }
}
