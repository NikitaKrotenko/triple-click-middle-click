import CoreGraphics
import Foundation

/// Installs a global event tap that drops left-mouse down/up events which
/// happen during (or just after) a three-finger tap, so the gesture doesn't
/// also register as a normal click. Requires Accessibility permission — the
/// same grant the app already needs to post the middle click.
///
/// The tap callback is kept minimal (no I/O): macOS silently disables an event
/// tap whose callback is too slow, so the hot path just checks a flag. A
/// watchdog timer re-enables the tap if the system ever disables it.
enum LeftClickSuppressor {
    /// Returns true once the event tap is installed. Safe to call repeatedly:
    /// it no-ops if already installed, and fails quietly (returning false) if
    /// Accessibility isn't granted yet, so the caller can retry.
    @discardableResult
    static func start() -> Bool {
        if tap != nil { return true }

        let mask: CGEventMask =
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.leftMouseUp.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, _ in
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = LeftClickSuppressor.tap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
                return Unmanaged.passUnretained(event)
            }
            if GestureState.shared.shouldSuppressLeftClick() {
                return nil // swallow the event; keep this path allocation/IO free
            }
            return Unmanaged.passUnretained(event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: nil
        ) else {
            return false
        }
        LeftClickSuppressor.tap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        startWatchdog()
        Log.write("LeftClickSuppressor: event tap installed")
        return true
    }

    /// Periodically re-enable the tap if macOS disabled it (e.g. after a
    /// momentary slowdown), so suppression never silently stays off.
    private static func startWatchdog() {
        watchdog?.invalidate()
        watchdog = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            guard let tap = LeftClickSuppressor.tap else { return }
            if !CGEvent.tapIsEnabled(tap: tap) {
                CGEvent.tapEnable(tap: tap, enable: true)
                Log.write("LeftClickSuppressor: watchdog re-enabled the tap")
            }
        }
    }

    private static var tap: CFMachPort?
    private static var watchdog: Timer?
}
