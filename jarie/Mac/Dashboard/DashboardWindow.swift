import AppKit
import SwiftUI
import SwiftData
import JarieCore

/// Manages the dashboard NSWindow lifecycle. Opens, focuses, or creates the window.
@MainActor
final class DashboardWindowController {
    private var window: NSWindow?
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func open() {
        if let window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let dashboardView = DashboardView()
            .modelContainer(modelContainer)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Jarie"
        window.minSize = NSSize(width: 600, height: 400)
        window.isReleasedWhenClosed = false // Prevent dangling pointer after close
        window.contentView = NSHostingView(rootView: dashboardView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }
}
