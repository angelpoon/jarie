import SwiftUI
import JarieCore

/// Dismissable banner shown in the menu bar popover when permissions are not fully granted.
struct PermissionBannerView: View {
    let onSetup: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.jarieYellowFallback)

            VStack(alignment: .leading, spacing: 2) {
                Text("Limited mode")
                    .font(JarieFont.caption)
                    .fontWeight(.medium)
                Text("Grant permissions for full \u{2318}\u{21E7}J capture.")
                    .font(JarieFont.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Set up") {
                onSetup()
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.jarieYellowFallback.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.jarieYellowFallback.opacity(0.3), lineWidth: 1)
        )
    }
}
