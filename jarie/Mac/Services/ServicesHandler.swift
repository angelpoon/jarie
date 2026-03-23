import AppKit
import JarieCore

/// Handles macOS Services menu integration for right-click capture.
/// Registered via NSApp.servicesProvider in AppDelegate.
@MainActor
final class ServicesHandler: NSObject {
    private let captureService: CaptureService

    init(captureService: CaptureService) {
        self.captureService = captureService
        super.init()
    }

    /// Called by macOS Services when user selects "Copy & Capture to Jarie".
    /// The pasteboard contains the selected text from the frontmost app.
    @objc func captureSelection(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) {
        guard let text = pasteboard.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        // Also copy to system clipboard (matches "Copy & Capture" behavior)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        Task { @MainActor in
            do {
                try await captureService.save(
                    text,
                    type: .text,
                    method: .services,
                    sourceURL: nil,
                    bundleID: nil
                )
            } catch {
                print("[Jarie] Services capture failed: \(error.localizedDescription)")
            }
        }
    }
}
