import Foundation
import QuartzCore

/// Shared, thread-safe hand-off between the multitouch thread (which detects
/// three-finger activity) and the event-tap thread (which decides whether to
/// swallow a coincident left click). While three fingers are down — and for a
/// short window afterwards — any left click macOS generates from that gesture
/// is suppressed, so a three-finger tap produces only the middle click.
final class GestureState {
    static let shared = GestureState()

    private let lock = NSLock()
    private var suppressLeftUntil: Double = 0

    /// Called repeatedly while three fingers are down, and again on tap
    /// detection, to keep the suppression window open across the release.
    func markThreeFinger(window: Double = 0.35) {
        let deadline = CACurrentMediaTime() + window
        lock.lock()
        suppressLeftUntil = max(suppressLeftUntil, deadline)
        lock.unlock()
    }

    func shouldSuppressLeftClick() -> Bool {
        lock.lock()
        let deadline = suppressLeftUntil
        lock.unlock()
        return CACurrentMediaTime() < deadline
    }
}
