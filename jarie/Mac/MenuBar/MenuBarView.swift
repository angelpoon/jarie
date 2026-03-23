import SwiftUI
import SwiftData
import JarieCore

/// SwiftUI content for the menu bar popover.
struct MenuBarView: View {
    @Environment(PermissionMonitor.self) private var permissionMonitor
    var onOpenDashboard: () -> Void = {}
    var onSetupPermissions: () -> Void = {}
    @State private var bannerDismissed = false
    @Query(
        filter: #Predicate<Capture> { !$0.isDeleted },
        sort: \Capture.createdAt,
        order: .reverse
    ) private var allCaptures: [Capture]

    private var todayCaptures: [Capture] {
        allCaptures.filter { DateFormatters.isToday($0.createdAt) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Permission banner
            if !permissionMonitor.allPermissionsGranted && !bannerDismissed {
                PermissionBannerView(
                    onSetup: onSetupPermissions,
                    onDismiss: { bannerDismissed = true }
                )
            }

            // Header
            Text("Jarie")
                .font(JarieFont.title)
                .foregroundStyle(.primary)

            Divider()

            // Today stats
            Text("Today: \(todayCaptures.count) captures")
                .font(JarieFont.body)

            // Last capture preview
            if let last = allCaptures.first {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(last.content)
                        .font(JarieFont.caption)
                        .lineLimit(2)
                        .foregroundStyle(.secondary)
                    Text(DateFormatters.time.string(from: last.createdAt))
                        .font(JarieFont.footnote)
                        .foregroundStyle(.tertiary)
                }
            }

            Divider()

            // Hotkey hint
            HStack {
                Text("New Capture")
                    .font(JarieFont.body)
                Spacer()
                Text("⌘⇧J")
                    .font(JarieFont.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Actions
            Button("Open Dashboard") {
                onOpenDashboard()
            }
            .font(JarieFont.body)
            .buttonStyle(.plain)

            SettingsLink {
                Text("Settings...")
                    .font(JarieFont.body)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                // LSUIElement apps don't auto-activate — bring Settings window to front
                NSApp.activate(ignoringOtherApps: true)
            })

            Button("Quit Jarie") {
                NSApplication.shared.terminate(nil)
            }
            .font(JarieFont.body)
            .buttonStyle(.plain)
        }
        .padding(Spacing.md)
        .frame(width: 260)
    }
}
