import SwiftUI
import JarieCore

/// Reusable permission card showing grant status and an action button.
struct PermissionCardView: View {
    let title: String
    let description: String
    let isGranted: Bool
    let buttonLabel: String
    let onGrant: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Status icon
            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundStyle(isGranted ? Color.jarieTealFallback : .secondary)
                .contentTransition(.symbolEffect(.replace))

            // Text
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(JarieFont.headline)
                Text(description)
                    .font(JarieFont.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Action
            if isGranted {
                Text("Granted")
                    .font(JarieFont.caption)
                    .foregroundStyle(Color.jarieTealFallback)
            } else {
                Button(buttonLabel) {
                    onGrant()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isGranted ? Color.jarieTealFallback.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}
