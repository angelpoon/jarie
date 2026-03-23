# Lessons Learned

## 2026-03-17: Swift 6 is opt-in, not automatic
New Xcode projects default to "Unspecified" Swift Language Version which falls back to Swift 5 mode. Swift 6 strict concurrency must be explicitly enabled in Build Settings. Always verify this at project creation time — don't assume it's set.

## 2026-03-19: Don't build on top of unconfigured capabilities
PersistenceController had `cloudKitDatabase: .automatic` but the iCloud capability was never added to the Xcode project. This caused silent data loss — captures weren't persisting to the local SQLite store. Rule: if a capability isn't configured in Xcode, the code must use a working fallback (`.none` for CloudKit) — never leave `.automatic` assuming someone else will configure it later. Verify the full stack works end-to-end at each phase, not just "does it compile."

## 2026-03-19: Check if apps are installed before running AppleScript
Running AppleScript for an uninstalled app (e.g., `tell application "Arc" to get name`) triggers a macOS "Where is Arc?" dialog. Always check `NSWorkspace.shared.urlForApplication(withBundleIdentifier:)` before executing AppleScript for any app.

## 2026-03-19: LSUIElement apps need explicit activation
Menu bar agent apps (LSUIElement = YES) don't auto-activate when opening windows. Every `window.makeKeyAndOrderFront()` must be followed by `NSApp.activate(ignoringOtherApps: true)`. Without it, windows appear behind other apps or don't show at all. Also, popover close + window open in the same run loop tick causes issues — use `DispatchQueue.main.async` to sequence them.
