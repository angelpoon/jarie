import SwiftUI
import JarieCore

struct ExportSettingsTab: View {
    @AppStorage("markdownExportPath") private var exportPath = "~/mind/collected"

    var body: some View {
        Form {
            Section("Markdown Export Folder") {
                Text("Captures and digests are exported as markdown files to this folder.")
                    .font(JarieFont.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    TextField("Export path", text: $exportPath)
                        .textFieldStyle(.roundedBorder)

                    Button("Choose...") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.canCreateDirectories = true
                        panel.allowsMultipleSelection = false

                        if panel.runModal() == .OK, let url = panel.url {
                            exportPath = url.path(percentEncoded: false)
                        }
                    }
                }

                // Use the same DateFormatters as the actual export to ensure preview matches reality
                let today = Date()
                let year = DateFormatters.year.string(from: today)
                let month = DateFormatters.month.string(from: today)
                let isoDate = DateFormatters.isoDate.string(from: today)
                Text("Preview: \(exportPath)/\(year)/\(month)/\(isoDate).md")
                    .font(JarieFont.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Export")
    }
}
