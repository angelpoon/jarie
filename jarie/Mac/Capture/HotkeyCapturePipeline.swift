import AppKit
import JarieCore

/// Orchestrates the full hotkey capture: clipboard capture, browser detection, save, toast.
@MainActor
final class HotkeyCapturePipeline {
    private let captureService: CaptureService
    private let browserDetector: BrowserURLDetector
    private let toastCoordinator: ToastCoordinator
    private let blocklist: AppBlocklist

    /// Bundle IDs where simulating Cmd+C would be destructive (e.g., SIGINT in terminals).
    /// These apps skip the CGEvent path entirely and use clipboard-only capture.
    private static let simulateCopyBlockedBundleIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
    ]

    init(captureService: CaptureService, browserDetector: BrowserURLDetector, toastCoordinator: ToastCoordinator, blocklist: AppBlocklist) {
        self.captureService = captureService
        self.browserDetector = browserDetector
        self.toastCoordinator = toastCoordinator
        self.blocklist = blocklist
    }

    func execute() {
        Task { @MainActor in
            let frontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier

            // Step 1: Get clipboard content
            let clipboardContent: String?
            let canSimulateCopy = AXIsProcessTrusted()
                && !Self.simulateCopyBlockedBundleIDs.contains(frontmostBundleID ?? "")
            if canSimulateCopy {
                clipboardContent = await simulateCopyAndReadClipboard()
            } else {
                // Fallback: read current clipboard (user must Cmd+C first)
                clipboardContent = NSPasteboard.general.string(forType: .string)
            }

            guard let content = clipboardContent,
                  !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return // Nothing to capture
            }

            // Step 2: Browser detection (parallel-safe, async)
            let browserInfo = await browserDetector.detect(frontmostBundleID: frontmostBundleID)

            // Step 3: Determine type and save
            let sourceURL = browserInfo?.url
            let type: CaptureType = sourceURL != nil
                ? .url
                : (URLExtractor.firstURL(from: content) != nil ? .url : .text)

            do {
                try await captureService.save(
                    content,
                    type: type,
                    method: .hotkey,
                    sourceURL: sourceURL,
                    bundleID: frontmostBundleID
                )

                // Step 4: Show toast
                toastCoordinator.show(
                    content: String(content.prefix(80)),
                    sourceURL: browserInfo?.url,
                    title: browserInfo?.title
                )
            } catch {
                print("[Jarie] Capture failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Private

    /// Simulates Cmd+C via CGEvent and reads the clipboard after polling for change.
    /// Returns nil explicitly if clipboard didn't change (no stale content returned).
    private func simulateCopyAndReadClipboard() async -> String? {
        let pasteboard = NSPasteboard.general
        let changeCountBefore = pasteboard.changeCount

        // Simulate Cmd+C: key down then key up for 'C' (virtual key 0x08) with Command modifier
        let source = CGEventSource(stateID: .combinedSessionState)

        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cgAnnotatedSessionEventTap)
        }
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cgAnnotatedSessionEventTap)
        }

        // Poll for clipboard change (handles slow Electron apps up to ~400ms)
        for _ in 0..<8 {
            try? await Task.sleep(for: .milliseconds(50))
            if pasteboard.changeCount != changeCountBefore {
                return pasteboard.string(forType: .string)
            }
        }

        // Clipboard never changed — the simulated copy failed (nothing selected, or app didn't respond)
        return nil
    }
}
