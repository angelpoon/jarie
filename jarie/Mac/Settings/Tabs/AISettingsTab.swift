import SwiftUI
import JarieCore

struct AISettingsTab: View {
    @State private var apiKeyInput = ""
    @State private var hasStoredKey = KeychainStore.exists(.byokAPIKey)
    @State private var saveStatus: String?

    var body: some View {
        Form {
            Section("API Key (BYOK)") {
                if hasStoredKey {
                    LabeledContent("Status", value: "API key stored in Keychain")
                    Button("Remove API Key", role: .destructive) {
                        try? KeychainStore.delete(.byokAPIKey)
                        hasStoredKey = false
                        saveStatus = "Key removed"
                    }
                } else {
                    Text("Enter your Anthropic API key. It will be stored securely in the macOS Keychain and never transmitted to Jarie servers.")
                        .font(JarieFont.caption)
                        .foregroundStyle(.secondary)

                    SecureField("sk-ant-...", text: $apiKeyInput)
                        .textFieldStyle(.roundedBorder)

                    Button("Save to Keychain") {
                        guard !apiKeyInput.isEmpty else { return }
                        do {
                            // WARNING: Write to Keychain immediately, clear in-memory copy
                            try KeychainStore.save(apiKeyInput, for: .byokAPIKey)
                            apiKeyInput = ""
                            hasStoredKey = true
                            saveStatus = "Key saved securely"
                        } catch {
                            saveStatus = "Failed to save: \(error.localizedDescription)"
                        }
                    }
                    .disabled(apiKeyInput.isEmpty)
                }

                if let status = saveStatus {
                    Text(status)
                        .font(JarieFont.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Provider") {
                Text("Claude (Anthropic)")
                    .foregroundStyle(.secondary)
                Text("Additional providers coming in a future update.")
                    .font(JarieFont.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("AI")
    }
}
