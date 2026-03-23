import SwiftUI
import JarieCore

struct AboutSettingsTab: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "tray.and.arrow.down")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.jarieTealFallback)

                    Text("Jarie AI")
                        .font(JarieFont.title)

                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(JarieFont.caption)
                        .foregroundStyle(.secondary)

                    Text("Frictionless content capture with AI-powered synthesis")
                        .font(JarieFont.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
            }

            Section {
                LabeledContent("Developer", value: "EasyBerry LLC")
                LabeledContent("Website", value: "easyberry.com")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("About")
    }
}
