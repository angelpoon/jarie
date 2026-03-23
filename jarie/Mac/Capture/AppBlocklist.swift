import Foundation

/// Manages the list of app bundle IDs where the capture hotkey is silently ignored.
/// Security-sensitive apps (password managers, terminals, banking) are blocked by default.
struct AppBlocklist: Sendable {
    private static let userDefaultsKey = "com.easyberry.jarie.appBlocklist"

    /// Default blocked bundle IDs -- conservative list per tech-architecture.md Section 10.
    static let defaultBlockedBundleIDs: Set<String> = [
        "com.1password.1password",
        "com.agilebits.onepassword7",
        "com.apple.keychainaccess",
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "com.bitwarden.desktop",
        "com.lastpass.LastPass",
    ]

    /// Returns true if the given bundle ID is blocked.
    func isBlocked(bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        let blocked = Self.loadBlockedIDs()
        // Check exact match and prefix match (e.g., "com.1password.*")
        return blocked.contains(bundleID) || blocked.contains(where: { pattern in
            pattern.hasSuffix(".*") && bundleID.hasPrefix(String(pattern.dropLast(2)))
        })
    }

    /// Returns the current full blocklist (defaults + user customizations).
    func allBlockedIDs() -> Set<String> {
        Self.loadBlockedIDs()
    }

    /// Adds a bundle ID to the user's custom blocklist.
    func addToBlocklist(_ bundleID: String) {
        var custom = Self.loadCustomIDs()
        custom.insert(bundleID)
        Self.saveCustomIDs(custom)
    }

    /// Removes a bundle ID from the user's custom blocklist.
    /// Cannot remove default blocked IDs.
    func removeFromBlocklist(_ bundleID: String) {
        var custom = Self.loadCustomIDs()
        custom.remove(bundleID)
        Self.saveCustomIDs(custom)
    }

    // MARK: - Private

    private static func loadBlockedIDs() -> Set<String> {
        defaultBlockedBundleIDs.union(loadCustomIDs())
    }

    private static func loadCustomIDs() -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: userDefaultsKey) ?? []
        return Set(array)
    }

    private static func saveCustomIDs(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids).sorted(), forKey: userDefaultsKey)
    }
}
