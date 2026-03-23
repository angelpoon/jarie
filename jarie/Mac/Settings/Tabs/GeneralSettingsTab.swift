import SwiftUI
import ServiceManagement

struct GeneralSettingsTab: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @AppStorage("showInDock") private var showInDock = false

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch Jarie at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue // Revert on failure
                        }
                    }
            }

            Section("Dock") {
                Toggle("Show Jarie in Dock", isOn: $showInDock)
                    .onChange(of: showInDock) { _, newValue in
                        NSApp.setActivationPolicy(newValue ? .regular : .accessory)
                    }

                Text("When hidden from Dock, Jarie lives in the menu bar only. Access it by clicking the icon in the top-right of your screen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
    }
}
