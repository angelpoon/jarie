import SwiftUI
import KeyboardShortcuts

struct CaptureSettingsTab: View {
    var body: some View {
        Form {
            Section("Hotkey") {
                KeyboardShortcuts.Recorder("Capture Hotkey:", name: .captureHotkey)
            }

            Section("Blocked Apps") {
                Text("The capture hotkey is silently ignored in these apps for security.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(Array(AppBlocklist.defaultBlockedBundleIDs).sorted(), id: \.self) { bundleID in
                    Text(bundleID)
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Capture")
    }
}
