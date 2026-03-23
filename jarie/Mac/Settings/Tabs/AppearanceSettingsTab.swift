import SwiftUI

struct AppearanceSettingsTab: View {
    var body: some View {
        Form {
            Section("Theme") {
                Text("Jarie follows your system appearance (Light / Dark).")
                    .foregroundStyle(.secondary)
            }

            Section("Coming Soon") {
                Text("Accent color customization and list density options will be available in a future update.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Appearance")
    }
}
