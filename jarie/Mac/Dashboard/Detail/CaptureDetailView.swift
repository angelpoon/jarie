import SwiftUI
import SwiftData
import JarieCore

/// Detail view for a selected capture.
struct CaptureDetailView: View {
    let captureID: UUID
    @Query private var captures: [Capture]

    init(captureID: UUID) {
        self.captureID = captureID
        _captures = Query(filter: #Predicate<Capture> { capture in
            capture.id == captureID
        })
    }

    private var capture: Capture? { captures.first }

    var body: some View {
        if let capture {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Title
                    if let title = capture.sourceTitle {
                        Text(title)
                            .font(JarieFont.title)
                            .textSelection(.enabled)
                    }

                    // Content
                    Text(capture.content)
                        .font(JarieFont.body)
                        .textSelection(.enabled)

                    Divider()

                    // Metadata
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        metadataRow("Captured", value: capture.createdAt.formatted(date: .long, time: .shortened))
                        metadataRow("Method", value: capture.method.rawValue.capitalized)

                        if let url = capture.sourceURL {
                            HStack(alignment: .top) {
                                Text("URL")
                                    .font(JarieFont.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 80, alignment: .leading)
                                if let destination = URL(string: url) {
                                    Link(url, destination: destination)
                                        .font(JarieFont.caption)
                                        .lineLimit(1)
                                } else {
                                    Text(url)
                                        .font(JarieFont.caption)
                                        .lineLimit(1)
                                }
                            }
                        }

                        if let domain = capture.sourceDomain {
                            metadataRow("Source", value: domain)
                        }

                        if let bundleID = capture.sourceBundleID {
                            metadataRow("App", value: bundleID)
                        }

                        if !capture.tags.isEmpty {
                            metadataRow("Tags", value: capture.tags.joined(separator: ", "))
                        }

                        if let summary = capture.aiSummary {
                            metadataRow("AI Summary", value: summary)
                        }
                    }

                    Spacer()
                }
                .padding(Spacing.lg)
            }
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        capture.isFavorite.toggle()
                    } label: {
                        Image(systemName: capture.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(capture.isFavorite ? Color("JariePink") : .secondary)
                    }
                    .help(capture.isFavorite ? "Remove from favorites" : "Add to favorites")

                    if let url = capture.sourceURL, let destination = URL(string: url) {
                        Link(destination: destination) {
                            Image(systemName: "safari")
                        }
                        .help("Open in browser")
                    }

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(capture.content, forType: .string)
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .help("Copy content")
                }
            }
        } else {
            ContentUnavailableView(
                "Capture Not Found",
                systemImage: "questionmark.circle"
            )
        }
    }

    private func metadataRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(JarieFont.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(JarieFont.caption)
                .textSelection(.enabled)
        }
    }
}
