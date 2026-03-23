import AppKit
import KeyboardShortcuts
import JarieCore

// Register the hotkey name as a static extension
extension KeyboardShortcuts.Name {
    static let captureHotkey = Self("captureHotkey", default: .init(.j, modifiers: [.command, .shift]))
}

/// Registers and manages the global capture hotkey (Cmd+Shift+J).
@MainActor
final class HotkeyManager {
    private let blocklist: AppBlocklist
    private let onTrigger: @MainActor () -> Void

    init(blocklist: AppBlocklist, onTrigger: @escaping @MainActor () -> Void) {
        self.blocklist = blocklist
        self.onTrigger = onTrigger

        KeyboardShortcuts.onKeyUp(for: .captureHotkey) { [weak self] in
            // KeyboardShortcuts calls back on main thread
            self?.handleHotkey()
        }
    }

    private func handleHotkey() {
        // Check if frontmost app is blocked
        let frontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        if blocklist.isBlocked(bundleID: frontmostBundleID) {
            return // Silently ignore in blocked apps
        }
        onTrigger()
    }
}
