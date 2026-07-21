import AppKit
import ApplicationServices

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

// Posting synthetic mouse events requires Accessibility permission. Prompt for
// it on launch so the app appears in System Settings → Privacy & Security →
// Accessibility (and the user gets the standard "grant access" dialog).
let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
let trusted = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
Log.write("app launched — accessibility trusted=\(trusted)")
if !trusted {
    FileHandle.standardError.write(Data("TCMC: not yet trusted for Accessibility — grant access in System Settings, then relaunch.\n".utf8))
}

var statusItem: NSStatusItem?

func makeStatusItem() -> NSStatusItem {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    item.button?.title = "🖱️"
    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "Triple-Click Middle Click", action: nil, keyEquivalent: ""))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    item.menu = menu
    return item
}

statusItem = makeStatusItem()

// The event tap needs Accessibility, which may not be granted at first launch.
// Try now, and if it fails, keep retrying so it starts as soon as the user
// grants access — no relaunch required.
if !LeftClickSuppressor.start() {
    var attempts = 0
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
        attempts += 1
        if LeftClickSuppressor.start() || attempts > 120 {
            timer.invalidate()
        }
    }
}

let monitor = TouchMonitor {
    MiddleClickPoster.post()
}
monitor.start()

app.run()
