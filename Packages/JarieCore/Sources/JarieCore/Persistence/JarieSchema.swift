import Foundation
import SwiftData

/// V1 schema — captures the initial model shape for future migration support.
/// When iOS/macOS 26.1 changes array storage for [String] and [UUID],
/// add JarieSchemaV2 and a migration stage here.
public enum JarieSchemaV1: VersionedSchema {
    nonisolated(unsafe) public static var versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [Capture.self, DailyDigest.self, AIProfile.self, AIProfileVersion.self]
    }
}

public enum JarieMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [JarieSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        // No migrations yet — v1 is the baseline.
        // Future: add .lightweight(fromVersion:toVersion:) or .custom() stages here.
        []
    }
}
