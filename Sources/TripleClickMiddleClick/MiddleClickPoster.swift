import ApplicationServices
import CoreGraphics
import Foundation

enum MiddleClickPoster {
    static func post() {
        let trusted = AXIsProcessTrusted()
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            Log.write("post FAILED — could not create event source (trusted=\(trusted))")
            return
        }
        let location = CGEvent(source: source)?.location ?? .zero
        Log.write("posting middle click at \(Int(location.x)),\(Int(location.y)) (trusted=\(trusted))")

        let down = CGEvent(
            mouseEventSource: source,
            mouseType: .otherMouseDown,
            mouseCursorPosition: location,
            mouseButton: .center
        )
        let up = CGEvent(
            mouseEventSource: source,
            mouseType: .otherMouseUp,
            mouseCursorPosition: location,
            mouseButton: .center
        )
        // Some apps ignore a middle click unless the button number and click
        // state fields are explicitly set on the event.
        for event in [down, up] {
            event?.setIntegerValueField(.mouseEventButtonNumber, value: 2)
        }
        down?.setIntegerValueField(.mouseEventClickState, value: 1)
        up?.setIntegerValueField(.mouseEventClickState, value: 1)

        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}
