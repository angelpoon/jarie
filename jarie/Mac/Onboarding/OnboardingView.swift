import SwiftUI
import JarieCore

/// Main onboarding checklist UI with permission cards for Accessibility and Browser access.
struct OnboardingView: View {
    @Environment(PermissionMonitor.self) private var monitor

    var onDone: () -> Void
    var onSkip: () -> Void
    var onOpenSettings: () -> Void
    var onGrantBrowserAccess: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Header
            VStack(spacing: Spacing.xs) {
                Image(systemName: "tray.and.arrow.down")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.jarieTealFallback)

                Text("Welcome to Jarie")
                    .font(JarieFont.display)

                Text("Let's set up two quick things so \u{2318}\u{21E7}J works perfectly.")
                    .font(JarieFont.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Permission cards
            VStack(spacing: Spacing.sm) {
                PermissionCardView(
                    title: "Accessibility Access",
                    description: "Lets Jarie copy your selected text when you press \u{2318}\u{21E7}J. Without this, you'll need to press \u{2318}C first.",
                    isGranted: monitor.isAccessibilityGranted,
                    buttonLabel: "Open Settings",
                    onGrant: onOpenSettings
                )

                PermissionCardView(
                    title: "Browser Access",
                    description: "Lets Jarie capture the URL and page title from Safari, Chrome, and Arc. macOS will ask once per browser.",
                    isGranted: monitor.isBrowserAccessTested && monitor.browserPermissions.values.allSatisfy { $0 },
                    buttonLabel: "Enable",
                    onGrant: onGrantBrowserAccess
                )
            }

            Spacer()

            // Bottom buttons
            HStack {
                Button("Skip for now") {
                    onSkip()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Button(action: onDone) {
                    HStack(spacing: Spacing.xxs) {
                        if monitor.allPermissionsGranted {
                            Image(systemName: "checkmark")
                        }
                        Text(monitor.allPermissionsGranted ? "All set!" : "Done")
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.jarieTealFallback)
            }
        }
        .padding(Spacing.xl)
        .frame(width: 520, height: 420)
    }
}
