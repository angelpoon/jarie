import SwiftUI
import KeyboardShortcuts
import JarieCore

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label("General", systemImage: "gear") }
            AccountSettingsTab()
                .tabItem { Label("Account", systemImage: "person.circle") }
            CaptureSettingsTab()
                .tabItem { Label("Capture", systemImage: "keyboard") }
            AISettingsTab()
                .tabItem { Label("AI", systemImage: "brain") }
            AppearanceSettingsTab()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
            ExportSettingsTab()
                .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
            AboutSettingsTab()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 500)
    }
}
