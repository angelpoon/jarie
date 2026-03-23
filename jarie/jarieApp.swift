import SwiftUI
import JarieCore

@main
struct jarieApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Minimal scene — the app is a menu bar agent.
        // Settings scene enables ⌘, to open settings (wired in Batch 7).
        Settings {
            SettingsView()
        }
    }
}
