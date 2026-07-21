import CMultitouchSupport
import Foundation

/// Watches raw trackpad multitouch frames and fires `onTripleTap` when it sees
/// a clean three-finger tap: three fingers touching down together, minimal
/// movement while down, and a quick release — as opposed to a three-finger
/// swipe (large movement) or a resting rest-and-drag (long duration).
final class TouchMonitor {
    private var device: MTDeviceRef?
    private let onTripleTap: () -> Void

    private let requiredFingerCount: Int32 = 3
    private let maxTapDuration: Double = 0.2
    private let maxMovement: Float = 0.03

    private var gestureStartTime: Double?
    private var gestureMaxMovement: Float = 0
    private var startPositions: [Int32: MTPoint] = [:]
    private var wasCandidateGesture = false

    init(onTripleTap: @escaping () -> Void) {
        self.onTripleTap = onTripleTap
    }

    func start() {
        guard let device = MTDeviceCreateDefault() else { return }
        self.device = device

        let callback: MTContactCallbackFunction = { _, touchData, numFingers, timestamp, _ in
            TouchMonitor.shared?.handleFrame(touches: touchData, count: numFingers, timestamp: timestamp)
        }
        TouchMonitor.shared = self

        MTRegisterContactFrameCallback(device, callback)
        MTDeviceStart(device, 0)
    }

    func stop() {
        guard let device else { return }
        MTDeviceStop(device)
        MTDeviceRelease(device)
        self.device = nil
    }

    // The C callback has no user-data pointer in this shim, so we keep a
    // single active-instance reference (there's only ever one monitor).
    private static var shared: TouchMonitor?

    private func handleFrame(touches: UnsafeMutablePointer<MTTouch>?, count: Int32, timestamp: Double) {
        guard let touches else { return }
        let buffer = UnsafeBufferPointer(start: touches, count: Int(count))

        if count == requiredFingerCount {
            if gestureStartTime == nil {
                gestureStartTime = timestamp
                gestureMaxMovement = 0
                startPositions.removeAll()
                for touch in buffer {
                    startPositions[touch.identifier] = touch.normalizedVector.position
                }
                wasCandidateGesture = true
            } else {
                for touch in buffer {
                    guard let start = startPositions[touch.identifier] else { continue }
                    let dx = touch.normalizedVector.position.x - start.x
                    let dy = touch.normalizedVector.position.y - start.y
                    let movement = (dx * dx + dy * dy).squareRoot()
                    gestureMaxMovement = max(gestureMaxMovement, movement)
                }
                if gestureMaxMovement > maxMovement {
                    wasCandidateGesture = false
                }
            }
        } else if count == 0 {
            if wasCandidateGesture, let start = gestureStartTime {
                let duration = timestamp - start
                if duration < maxTapDuration && gestureMaxMovement <= maxMovement {
                    onTripleTap()
                }
            }
            gestureStartTime = nil
            wasCandidateGesture = false
            startPositions.removeAll()
        } else {
            // Finger count changed mid-gesture (e.g. 2 or 4 fingers involved) — abandon it.
            wasCandidateGesture = false
        }
    }
}
