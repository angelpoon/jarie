import AppKit
import SwiftData
import JarieCore

/// Composition root for the Mac app. Owns all subsystem references and injects dependencies downward.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController!
    private var hotkeyManager: HotkeyManager!
    private var dashboardController: DashboardWindowController!
    private var pipeline: HotkeyCapturePipeline!
    private var servicesHandler: ServicesHandler!
    private var permissionMonitor: PermissionMonitor!
    private var onboardingController: OnboardingWindowController!
    private let appBlocklist = AppBlocklist()
    private let persistenceController = PersistenceController.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Skip full app initialization when running as a test host
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return
        }

        // Restore Dock visibility preference
        let showInDock = UserDefaults.standard.bool(forKey: "showInDock")
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)

        let container = persistenceController.container
        let markdownRootURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("mind/collected")
        let captureService = CaptureService(modelContainer: container, markdownRootURL: markdownRootURL)

        // Dashboard
        dashboardController = DashboardWindowController(modelContainer: container)

        // Permissions & onboarding
        permissionMonitor = PermissionMonitor()
        permissionMonitor.startPolling()
        onboardingController = OnboardingWindowController(permissionMonitor: permissionMonitor)

        // Menu bar
        menuBarController = MenuBarController(
            modelContainer: container,
            captureService: captureService,
            dashboardController: dashboardController,
            permissionMonitor: permissionMonitor,
            onboardingController: onboardingController
        )

        // Capture pipeline: browser detection → clipboard → save → toast
        let browserDetector = BrowserURLDetector()
        let toastCoordinator = ToastCoordinator()
        pipeline = HotkeyCapturePipeline(
            captureService: captureService,
            browserDetector: browserDetector,
            toastCoordinator: toastCoordinator,
            blocklist: appBlocklist
        )

        // Hotkey: ⌘⇧J → blocklist check → capture pipeline
        hotkeyManager = HotkeyManager(blocklist: appBlocklist) { [weak self] in
            self?.pipeline.execute()
        }

        // Services menu: "Copy & Capture to Jarie" right-click action
        let servicesHandler = ServicesHandler(captureService: captureService)
        self.servicesHandler = servicesHandler
        NSApp.servicesProvider = servicesHandler
        NSUpdateDynamicServices()

        // Show onboarding if needed (after all subsystems are ready)
        onboardingController.openIfNeeded()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
