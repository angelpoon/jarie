import Foundation
import SwiftData

@MainActor
public final class PersistenceController {
    public static let shared = PersistenceController()

    public let container: ModelContainer

    private init() {
        let schema = Schema([
            Capture.self,
            DailyDigest.self,
            AIProfile.self,
            AIProfileVersion.self,
        ])

        // Detect test environment: use .none for CloudKit to avoid entitlement issues
        // in the test runner process. Production uses .automatic for CloudKit sync.
        let isTestEnvironment = NSClassFromString("XCTestCase") != nil
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: isTestEnvironment ? .none : .automatic
        )

        do {
            container = try ModelContainer(
                for: schema,
                migrationPlan: JarieMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    /// In-memory container for previews and tests. Throws instead of fatalError
    /// to avoid tearing down the entire test process on failure.
    public static func preview() throws -> ModelContainer {
        let schema = Schema([
            Capture.self,
            DailyDigest.self,
            AIProfile.self,
            AIProfileVersion.self,
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// In-memory container for unit tests
    public static func test() throws -> ModelContainer {
        try preview()
    }
}
