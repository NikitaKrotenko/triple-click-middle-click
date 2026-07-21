import AppKit
import ApplicationServices

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

// Posting synthetic mouse events requires Accessibility permission. Prompt for
// it on launch so the app appears in System Settings → Privacy & Security →
// Accessibility (and the user gets the standard "grant access" dialog).
let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
let trusted = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
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

let monitor = TouchMonitor {
    MiddleClickPoster.post()
}
monitor.start()

app.run()
