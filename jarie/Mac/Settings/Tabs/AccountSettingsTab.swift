import SwiftUI
import JarieCore

struct AccountSettingsTab: View {
    var body: some View {
        Form {
            Section("Account") {
                Text("Not signed in")
                    .foregroundStyle(.secondary)
                Text("Sign in to sync captures across devices and unlock AI features.")
                    .font(JarieFont.caption)
                    .foregroundStyle(.tertiary)
                // TODO: Phase 1.5A -- SignInView (SIWA + email/password)
                Button("Sign In") {}
                    .disabled(true)
            }

            Section("Subscription") {
                LabeledContent("Tier", value: "Free")
                LabeledContent("Status", value: "No subscription")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Account")
    }
}
