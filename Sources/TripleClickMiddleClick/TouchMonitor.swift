import CMultitouchSupport
import Foundation

/// Watches raw trackpad multitouch frames and fires `onTripleTap` when it sees
/// a clean three-finger tap: three fingers touching down together, minimal
/// movement while down, and a quick release — as opposed to a three-finger
/// swipe (large movement) or a rest-and-drag (long duration).
final class TouchMonitor {
    private var device: MTDeviceRef?
    private let onTripleTap: () -> Void

    private let requiredFingerCount = 3
    private let maxTapDuration: Double = 0.6
    private let maxMovement: Float = 0.08

    /// A gesture spans from the first finger touching down until all fingers
    /// have lifted (a frame with 0 fingers). We don't evaluate anything until
    /// that full release, because fingers land and lift a few frames apart —
    /// the count naturally passes through 1 and 2 on the way to/from 3.
    private var gestureStartTime: Double?
    private var gestureMaxFingers = 0
    private var gestureMaxMovement: Float = 0
    private var startPositions: [Int32: MTPoint] = [:]

    private let debug = ProcessInfo.processInfo.environment["TCMC_DEBUG"] == "1"

    init(onTripleTap: @escaping () -> Void) {
        self.onTripleTap = onTripleTap
    }

    func start() {
        guard let device = MTDeviceCreateDefault() else {
            FileHandle.standardError.write(Data("TCMC: MTDeviceCreateDefault returned nil — no multitouch device found.\n".utf8))
            return
        }
        self.device = device

        let callback: MTContactCallbackFunction = { _, touchData, numFingers, timestamp, _ in
            TouchMonitor.shared?.handleFrame(touches: touchData, count: numFingers, timestamp: timestamp)
        }
        TouchMonitor.shared = self

        MTRegisterContactFrameCallback(device, callback)
        MTDeviceStart(device, 0)
        if debug {
            FileHandle.standardError.write(Data("TCMC: monitoring started (device found).\n".utf8))
        }
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

    private func log(_ message: @autoclosure () -> String) {
        guard debug else { return }
        FileHandle.standardError.write(Data("TCMC: \(message())\n".utf8))
    }

    private func handleFrame(touches: UnsafeMutablePointer<MTTouch>?, count: Int32, timestamp: Double) {
        let fingerCount = Int(count)
        let buffer: UnsafeBufferPointer<MTTouch>
        if let touches {
            buffer = UnsafeBufferPointer(start: touches, count: fingerCount)
        } else {
            buffer = UnsafeBufferPointer(start: nil, count: 0)
        }

        if fingerCount > 0 {
            if gestureStartTime == nil {
                // First contact of a new gesture.
                gestureStartTime = timestamp
                gestureMaxFingers = 0
                gestureMaxMovement = 0
                startPositions.removeAll()
            }
            gestureMaxFingers = max(gestureMaxFingers, fingerCount)

            for touch in buffer {
                let pos = touch.normalizedVector.position
                if let start = startPositions[touch.identifier] {
                    let dx = pos.x - start.x
                    let dy = pos.y - start.y
                    gestureMaxMovement = max(gestureMaxMovement, (dx * dx + dy * dy).squareRoot())
                } else {
                    startPositions[touch.identifier] = pos
                }
            }
        } else {
            // Full release — evaluate the gesture that just ended.
            if let start = gestureStartTime {
                let duration = timestamp - start
                let isTap = gestureMaxFingers == requiredFingerCount
                    && duration < maxTapDuration
                    && gestureMaxMovement <= maxMovement
                log("release: maxFingers=\(gestureMaxFingers) duration=\(String(format: "%.3f", duration)) movement=\(String(format: "%.4f", gestureMaxMovement)) -> \(isTap ? "TAP" : "ignored")")
                if isTap {
                    onTripleTap()
                }
            }
            gestureStartTime = nil
            gestureMaxFingers = 0
            gestureMaxMovement = 0
            startPositions.removeAll()
        }
    }
}
