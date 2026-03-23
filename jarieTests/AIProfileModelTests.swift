import Testing
import SwiftData
import Foundation
@testable import JarieCore

struct AIProfileModelTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Capture.self, DailyDigest.self, AIProfile.self, AIProfileVersion.self])
        let config = ModelConfiguration("test-\(UUID().uuidString)", schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test func profileCreation() throws {
        let profile = AIProfile(fullText: "Angel is a developer...", captureCount: 50)

        #expect(profile.fullText.contains("developer"))
        #expect(profile.lastCaptureCountAtGeneration == 50)
    }

    @MainActor
    @Test func profilePersistence() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let profile = AIProfile(fullText: "Profile text", captureCount: 10)
        context.insert(profile)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<AIProfile>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.fullText == "Profile text")
    }

    @Test func profileVersionCreation() throws {
        let profileId = UUID()
        let version = AIProfileVersion(
            text: "Rewritten for recruiter",
            profileId: profileId,
            prompt: "Rewrite for a tech recruiter"
        )

        #expect(version.profileId == profileId)
        #expect(version.prompt == "Rewrite for a tech recruiter")
        #expect(version.text.contains("recruiter"))
    }

    @MainActor
    @Test func profileVersionManualForeignKey() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let profile = AIProfile(fullText: "Original", captureCount: 20)
        context.insert(profile)
        try context.save()

        let version = AIProfileVersion(text: "Snapshot", profileId: profile.id)
        context.insert(version)
        try context.save()

        // Query versions by profileId (manual foreign key)
        let pid = profile.id
        let descriptor = FetchDescriptor<AIProfileVersion>(
            predicate: #Predicate { $0.profileId == pid }
        )
        let versions = try context.fetch(descriptor)
        #expect(versions.count == 1)
        #expect(versions.first?.text == "Snapshot")
    }
}
