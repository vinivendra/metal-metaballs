func iterate<C, R>(collection: C, block: (String?, Any) -> R) {
    let mirror = Mirror(reflecting: collection)
    for child in mirror.children {
        block(child.0, child.1)
    }
}
