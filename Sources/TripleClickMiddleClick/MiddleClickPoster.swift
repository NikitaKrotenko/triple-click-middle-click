import ApplicationServices
import CoreGraphics
import Foundation

enum MiddleClickPoster {
    private static let debug = ProcessInfo.processInfo.environment["TCMC_DEBUG"] == "1"

    static func post() {
        if debug {
            let trusted = AXIsProcessTrusted()
            FileHandle.standardError.write(Data("TCMC: posting middle click (accessibility trusted=\(trusted))\n".utf8))
        }
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
