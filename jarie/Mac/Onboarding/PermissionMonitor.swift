import AppKit
import os

/// Single source of truth for permission state. Polls Accessibility and probes browser automation.
@MainActor
@Observable
final class PermissionMonitor {
    private(set) var isAccessibilityGranted = false
    private(set) var isBrowserAccessTested = false
    private(set) var browserPermissions: [String: Bool] = [:]

    private var pollTimer: Timer?
    private let logger = Logger(subsystem: "com.easyberry.jarie", category: "PermissionMonitor")

    static let onboardingCompletedVersionKey = "onboardingCompletedVersion"
    static let onboardingDismissCountKey = "onboardingDismissCount"
    static let currentOnboardingVersion = 1

    private static let browserBundleIDs = [
        "com.apple.Safari",
        "com.google.Chrome",
        "company.thebrowser.Browser"
    ]

    var allPermissionsGranted: Bool {
        isAccessibilityGranted && isBrowserAccessTested && browserPermissions.values.allSatisfy { $0 }
    }

    var needsOnboarding: Bool {
        let completedVersion = UserDefaults.standard.integer(forKey: Self.onboardingCompletedVersionKey)
        let dismissCount = UserDefaults.standard.integer(forKey: Self.onboardingDismissCountKey)
        return completedVersion < Self.currentOnboardingVersion && dismissCount < 3 && !allPermissionsGranted
    }

    func startPolling() {
        checkAccessibility()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.checkAccessibility()
                if self?.allPermissionsGranted == true {
                    self?.pollTimer?.invalidate()
                    self?.pollTimer = nil
                }
            }
        }
        // Silent probe for automation on launch (no dialog triggered if already granted)
        Task { await probeBrowserPermissions() }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func requestAccessibility() {
        // AXIsProcessTrusted() is check-only. Open System Settings so the user can grant access;
        // the 2-second poll timer will detect the change.
        checkAccessibility()
        if !isAccessibilityGranted,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func requestBrowserAccess() {
        Task { await probeBrowserPermissions() }
    }

    func markOnboardingComplete() {
        UserDefaults.standard.set(Self.currentOnboardingVersion, forKey: Self.onboardingCompletedVersionKey)
    }

    func markOnboardingDismissed() {
        let count = UserDefaults.standard.integer(forKey: Self.onboardingDismissCountKey)
        UserDefaults.standard.set(count + 1, forKey: Self.onboardingDismissCountKey)
    }

    // MARK: - Private

    private func checkAccessibility() {
        isAccessibilityGranted = AXIsProcessTrusted()
    }

    /// Returns bundle IDs of browsers that are actually installed on this Mac.
    private func installedBrowserBundleIDs() -> [String] {
        Self.browserBundleIDs.filter { bundleID in
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil
        }
    }

    private func probeBrowserPermissions() async {
        let installed = installedBrowserBundleIDs()
        for bundleID in installed {
            let granted = await probeSingleBrowser(bundleID)
            browserPermissions[bundleID] = granted
        }
        // Mark uninstalled browsers as true (not applicable — don't block "all granted")
        for bundleID in Self.browserBundleIDs where !installed.contains(bundleID) {
            browserPermissions[bundleID] = true
        }
        isBrowserAccessTested = true
    }

    private nonisolated func probeSingleBrowser(_ bundleID: String) async -> Bool {
        let appName: String
        switch bundleID {
        case "com.apple.Safari": appName = "Safari"
        case "com.google.Chrome": appName = "Google Chrome"
        case "company.thebrowser.Browser": appName = "Arc"
        default: return false
        }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                let script = NSAppleScript(source: "tell application \"\(appName)\" to get name")
                _ = script?.executeAndReturnError(&error)
                continuation.resume(returning: error == nil)
            }
        }
    }
}
