import AppKit
import SwiftUI
import SwiftData
import JarieCore

/// Owns the NSStatusItem and coordinates all Mac subsystems (popover, hotkey, toast, dashboard).
@MainActor
final class MenuBarController {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let modelContainer: ModelContainer
    private let captureService: CaptureService
    private let dashboardController: DashboardWindowController
    private let permissionMonitor: PermissionMonitor
    private let onboardingController: OnboardingWindowController

    init(
        modelContainer: ModelContainer,
        captureService: CaptureService,
        dashboardController: DashboardWindowController,
        permissionMonitor: PermissionMonitor,
        onboardingController: OnboardingWindowController
    ) {
        self.modelContainer = modelContainer
        self.captureService = captureService
        self.dashboardController = dashboardController
        self.permissionMonitor = permissionMonitor
        self.onboardingController = onboardingController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.popover = NSPopover()

        setupStatusItem()
        setupPopover()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "tray.and.arrow.down", accessibilityDescription: "Jarie")
        button.action = #selector(togglePopover)
        button.target = self
    }

    private func setupPopover() {
        popover.contentSize = NSSize(width: 280, height: 200)
        popover.behavior = .transient
        popover.animates = true

        let menuBarView = MenuBarView(
            onOpenDashboard: { [weak self] in
                self?.popover.performClose(nil)
                // Delay dashboard open to next run loop tick so popover dismissal completes first
                DispatchQueue.main.async {
                    MainActor.assumeIsolated {
                        self?.dashboardController.open()
                    }
                }
            },
            onSetupPermissions: { [weak self] in
                self?.popover.performClose(nil)
                self?.onboardingController.open()
            }
        )
            .environment(permissionMonitor)
            .modelContainer(modelContainer)
        popover.contentViewController = NSHostingController(rootView: menuBarView)
    }

    // MARK: - Actions

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Ensure popover window becomes key so it dismisses on click-outside
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
