import Testing
import SwiftData
import Foundation
@testable import JarieCore

struct DigestModelTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Capture.self, DailyDigest.self, AIProfile.self, AIProfileVersion.self])
        let config = ModelConfiguration("test-\(UUID().uuidString)", schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test func digestCreation() throws {
        let ids = [UUID(), UUID(), UUID()]
        let digest = DailyDigest(
            date: Date(),
            summary: "Today you explored AI tools and Swift concurrency.",
            captureIds: ids,
            captureCount: 3
        )

        #expect(digest.summary.contains("AI tools"))
        #expect(digest.captureIds.count == 3)
        #expect(digest.captureCount == 3)
        #expect(digest.modelUsed == nil)
    }

    @MainActor
    @Test func digestPersistence() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let digest = DailyDigest(
            date: Date(),
            summary: "Summary",
            captureIds: [UUID()],
            captureCount: 1
        )
        context.insert(digest)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<DailyDigest>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.summary == "Summary")
    }

    @Test func digestModelUsed() throws {
        let digest = DailyDigest(date: Date(), summary: "Test", captureIds: [], captureCount: 0)
        digest.modelUsed = "claude-haiku-4-5-20251001"
        #expect(digest.modelUsed == "claude-haiku-4-5-20251001")
    }
}
