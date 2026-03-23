import AppKit
import SwiftUI

/// Manages the onboarding NSWindow lifecycle following the DashboardWindowController pattern.
@MainActor
final class OnboardingWindowController {
    private var window: NSWindow?
    private let permissionMonitor: PermissionMonitor

    init(permissionMonitor: PermissionMonitor) {
        self.permissionMonitor = permissionMonitor
    }

    /// Opens the onboarding window only if the user still needs onboarding.
    func openIfNeeded() {
        guard permissionMonitor.needsOnboarding else { return }
        open()
    }

    /// Always opens (or focuses) the onboarding window.
    func open() {
        if let window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let onboardingView = OnboardingView(
            onDone: { [weak self] in self?.completeAndClose() },
            onSkip: { [weak self] in self?.skipAndClose() },
            onOpenSettings: { [weak self] in self?.permissionMonitor.requestAccessibility() },
            onGrantBrowserAccess: { [weak self] in self?.permissionMonitor.requestBrowserAccess() }
        )
        .environment(permissionMonitor)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Jarie"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: onboardingView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }

    // MARK: - Private

    private func completeAndClose() {
        permissionMonitor.markOnboardingComplete()
        window?.close()
    }

    private func skipAndClose() {
        permissionMonitor.markOnboardingDismissed()
        window?.close()
    }
}
