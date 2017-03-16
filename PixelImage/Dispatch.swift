
import Dispatch

func delay(_ duration: Float = 1, block: @escaping () -> ()) {
	DispatchQueue.main.asyncAfter(
		deadline: DispatchTime.now() +
			Double(duration * Float(NSEC_PER_SEC)) /
			Double(NSEC_PER_SEC),
		execute: block)
}
