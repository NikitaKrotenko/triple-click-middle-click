# Triple-Click Middle Click

A tiny macOS menu-bar app that turns a **three-finger tap** on your trackpad
into a **middle mouse click** — handy for opening links in new background
tabs, closing tabs, or anything else bound to middle-click.

It works by reading raw multitouch frames from Apple's private
`MultitouchSupport.framework` (the same private API used by tools like
MiddleClick/BetterTouchTool), detecting a quick, low-movement three-finger
touch-and-release, and then synthesizing an `otherMouseDown`/`otherMouseUp`
event pair via `CGEvent`. A real three-finger *swipe* (larger movement) is
left untouched, so Mission Control / app-switching gestures keep working.

## Build

Requires Xcode Command Line Tools (Swift 5.9+) on macOS 12+.

```bash
swift build -c release
```

## Package as an app and install

```bash
./Scripts/build_app.sh
open dist/
# Drag TripleClickMiddleClick.app into /Applications
```

Launch the app from `/Applications`. macOS will prompt you to grant it
**Accessibility** permission under System Settings → Privacy & Security →
Accessibility (required to post synthetic mouse events) — enable it there,
then relaunch the app.

## Run at login (optional)

```bash
cp com.nikitakrotenko.tripleclickmiddleclick.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.nikitakrotenko.tripleclickmiddleclick.plist
```

To stop it from running at login:

```bash
launchctl unload ~/Library/LaunchAgents/com.nikitakrotenko.tripleclickmiddleclick.plist
rm ~/Library/LaunchAgents/com.nikitakrotenko.tripleclickmiddleclick.plist
```

## Uninstall

Quit the app from its menu-bar icon, remove it from `/Applications`, and
remove the LaunchAgent (see above) if you installed it.

## How tap detection works

`Sources/TripleClickMiddleClick/TouchMonitor.swift` tracks multitouch frames
and looks for exactly three fingers touching down together, with total
movement under a small threshold and a release within ~200ms — a "tap" as
opposed to a drag or swipe. On a match, `MiddleClickPoster.swift` posts the
middle-click event pair at the current cursor location.

## Caveats

- Uses a private, undocumented Apple framework (`MultitouchSupport`). It has
  been stable across macOS releases for years but is not guaranteed by Apple
  and could break in a future OS update.
- Requires accessibility permission to synthesize mouse events.
