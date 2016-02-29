![Example Animation](https://raw.githubusercontent.com/vinivendra/metal-metaballs/master/Examples/Animation.gif)

# Metal Metaballs

Metal Metaballs is a framework for rendering graphs in an aesthetically pleasing way. It uses an adapted version of [metaball](https://en.wikipedia.org/wiki/Metaballs) math to create fluid graphics, allow vertices to merge with each other and allow edges to flow and animate smoothly.

Vertices and edges may be added and removed at will and can interact with gestures. Rendering a fullscreen view continuously uses only about 19% of the CPU at 60 fps, though normally the view will only be updated when needed. All rendering is done in a background thread, so the main thread remains almost completely free. These measurements were done using an iPhone 6S Plus (which has more pixels to calculate but more power to do so), so YMMV.

This framework is being developed to make me learn several different design patters, APIs and features used in iOS and in graphics applications. So far, it uses:

- [**Metaball**](https://en.wikipedia.org/wiki/Metaballs) math, in an adapted version, to render the graphics.
- [**Metal**](https://developer.apple.com/metal/) compute shaders to draw the metaballs dynamically.
- [**Grand Central Dispatch**](https://developer.apple.com/library/ios/documentation/Performance/Reference/GCD_libdispatch_Ref/) for doing CPU and GPU calculations simultaneously.
- [**Double buffering**](https://en.wikipedia.org/wiki/Multiple_buffering), to speed up rendering times.
- Different [**interpolations**](http://flexmonkey.blogspot.ca/2016/01/playing-with-interpolation-functions-in.html) for animations.

## Installation

Just download the app and run it on your metal-enabled device of choice :)
