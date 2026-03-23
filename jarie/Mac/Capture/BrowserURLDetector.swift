import Foundation
import os

/// Browser metadata extracted via AppleScript.
struct BrowserInfo: Sendable {
    let url: String
    let title: String?
}

/// Extracts the current URL and page title from the frontmost browser tab.
/// Uses AppleScript -- requires per-browser Automation permission grants from macOS.
/// WARNING: Bundle ID validated before AppleScript runs. See CLAUDE.md security requirements.
actor BrowserURLDetector {

    /// Browsers with known AppleScript interfaces.
    private static let supportedBrowsers: [String: BrowserAppleScript] = [
        "com.apple.Safari": BrowserAppleScript(
            urlScript: "tell application \"Safari\" to get URL of current tab of front window",
            titleScript: "tell application \"Safari\" to get name of current tab of front window"
        ),
        "com.google.Chrome": BrowserAppleScript(
            urlScript: "tell application \"Google Chrome\" to get URL of active tab of front window",
            titleScript: "tell application \"Google Chrome\" to get title of active tab of front window"
        ),
        "company.thebrowser.Browser": BrowserAppleScript(
            urlScript: "tell application \"Arc\" to get URL of active tab of front window",
            titleScript: "tell application \"Arc\" to get title of active tab of front window"
        ),
    ]

    private struct BrowserAppleScript: Sendable {
        let urlScript: String
        let titleScript: String
    }

    /// Serial queue for AppleScript execution. Limits to one concurrent call
    /// to prevent thread pileup from unresponsive browsers.
    /// NOTE: NSAppleScript.executeAndReturnError is a blocking, non-cancellable C call.
    /// Swift task cancellation does not interrupt it. The serial queue ensures at most
    /// one AppleScript call is in-flight at any time.
    private static let appleScriptQueue = DispatchQueue(label: "com.easyberry.jarie.applescript")

    /// Detect the current browser URL for the given frontmost app.
    /// Returns nil if the app is not a supported browser or AppleScript fails/times out (2s).
    func detect(frontmostBundleID: String?) async -> BrowserInfo? {
        guard let bundleID = frontmostBundleID,
              let scripts = Self.supportedBrowsers[bundleID] else {
            return nil
        }

        let urlSource = scripts.urlScript
        let titleSource = scripts.titleScript

        // Run AppleScript on a dedicated serial queue with a 2-second timeout.
        // Late results are discarded via the `completed` flag.
        return await withCheckedContinuation { continuation in
            let completed = LockedFlag()

            // Timeout on a separate queue so it's not blocked behind queued AppleScript work
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                if completed.setIfFirst() {
                    continuation.resume(returning: nil)
                }
            }

            // Actual work
            Self.appleScriptQueue.async {
                let url = Self.runAppleScript(urlSource)
                guard let url, !url.isEmpty else {
                    if completed.setIfFirst() {
                        continuation.resume(returning: nil)
                    }
                    return
                }
                let title = Self.runAppleScript(titleSource)
                if completed.setIfFirst() {
                    continuation.resume(returning: BrowserInfo(url: url, title: title))
                }
            }
        }
    }

    /// Check if a bundle ID is a supported browser.
    nonisolated func isBrowser(_ bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return Self.supportedBrowsers.keys.contains(bundleID)
    }

    // MARK: - Private

    /// Execute an AppleScript string and return the result.
    /// Returns nil on any error (permission denied, app not running, etc).
    private static func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        let script = NSAppleScript(source: source)
        let result = script?.executeAndReturnError(&error)
        if let error {
            Logger(subsystem: "com.easyberry.jarie", category: "BrowserURLDetector")
                .debug("AppleScript failed: \(error)")
            return nil
        }
        return result?.stringValue
    }
}

/// Thread-safe one-shot flag for racing completion handlers.
private final class LockedFlag: @unchecked Sendable {
    private var _completed = false
    private let lock = NSLock()

    /// Returns true if this is the first call; false on subsequent calls.
    func setIfFirst() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if _completed { return false }
        _completed = true
        return true
    }
}
