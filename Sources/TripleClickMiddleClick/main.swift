import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

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
