import SwiftUI
import JarieCore

/// Toast notification content shown after a successful capture.
struct ToastView: View {
    let content: String
    let sourceURL: String?
    let title: String?

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.jarieTealFallback)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Copied & Saved")
                    .font(JarieFont.headline)
                    .foregroundStyle(.primary)

                Text(title ?? content)
                    .font(JarieFont.caption)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)

                if let sourceURL {
                    if let domain = URLExtractor.domain(from: sourceURL) {
                        Text(domain)
                            .font(JarieFont.footnote)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(Spacing.sm)
        .frame(width: 260, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}
