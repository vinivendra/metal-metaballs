
import Dispatch

func delay(duration: Float = 1, block: () -> ()) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(duration * Float(NSEC_PER_SEC))), dispatch_get_main_queue(), block)
}
