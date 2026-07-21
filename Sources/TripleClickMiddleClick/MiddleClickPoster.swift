import CoreGraphics

enum MiddleClickPoster {
    static func post() {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        let location = CGEvent(source: source)?.location ?? .zero

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

        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}
