import SwiftUI
import JarieCore

/// A single capture row in the dashboard list.
struct CaptureRowView: View {
    let capture: Capture

    var body: some View {
        HStack(spacing: Spacing.xs) {
            // Star indicator
            Image(systemName: capture.isFavorite ? "star.fill" : "star")
                .font(.system(size: 12))
                .foregroundStyle(capture.isFavorite ? Color("JariePink") : .clear)
                .frame(width: 16)

            // Content
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(displayTitle)
                    .font(JarieFont.headline)
                    .lineLimit(1)

                HStack(spacing: Spacing.xxs) {
                    if let domain = capture.sourceDomain {
                        Text(domain)
                            .font(JarieFont.footnote)
                            .foregroundStyle(Color("JarieBlue"))
                    }

                    if capture.sourceDomain != nil {
                        Text("\u{00B7}")
                            .font(JarieFont.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Text(capture.createdAt, style: .time)
                        .font(JarieFont.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Type badge
            Image(systemName: capture.type == .url ? "link" : "doc.text")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, Spacing.xxs)
    }

    private var displayTitle: String {
        capture.sourceTitle ?? String(capture.content.prefix(100))
    }
}
