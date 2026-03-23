import Testing
import SwiftData
import Foundation
@testable import JarieCore

@MainActor
struct CaptureModelTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Capture.self, DailyDigest.self, AIProfile.self, AIProfileVersion.self])
        let config = ModelConfiguration("test-\(UUID().uuidString)", schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test func captureCreation() throws {
        let capture = Capture(content: "Hello world", type: .text, method: .hotkey)

        #expect(capture.content == "Hello world")
        #expect(capture.type == .text)
        #expect(capture.method == .hotkey)
        #expect(capture.tags.isEmpty)
        #expect(capture.isFavorite == false)
        #expect(capture.isDeleted == false)
        #expect(capture.sourceURL == nil)
        #expect(capture.aiSummary == nil)
    }

    @Test func captureWithURL() throws {
        let capture = Capture(
            content: "Check this out",
            type: .url,
            method: .shareSheet,
            sourceURL: "https://example.com",
            sourceBundleID: "com.apple.Safari"
        )

        #expect(capture.type == .url)
        #expect(capture.sourceURL == "https://example.com")
        #expect(capture.sourceBundleID == "com.apple.Safari")
    }

    @Test func capturePersistence() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let capture = Capture(content: "Persisted", type: .text, method: .manual)
        context.insert(capture)
        try context.save()

        let descriptor = FetchDescriptor<Capture>()
        let fetched = try context.fetch(descriptor)

        #expect(fetched.count == 1)
        #expect(fetched.first?.content == "Persisted")
    }

    @Test func captureUniqueID() throws {
        let a = Capture(content: "A", type: .text, method: .hotkey)
        let b = Capture(content: "B", type: .text, method: .hotkey)
        #expect(a.id != b.id)
    }

    @Test func captureFavoriteToggle() throws {
        let capture = Capture(content: "Toggle me", type: .text, method: .manual)
        #expect(capture.isFavorite == false)
        capture.isFavorite = true
        #expect(capture.isFavorite == true)
    }

    @Test func captureSoftDelete() throws {
        let capture = Capture(content: "Delete me", type: .text, method: .manual)
        #expect(capture.isDeleted == false)
        capture.isDeleted = true
        #expect(capture.isDeleted == true)
    }

    @Test func captureQueryByPredicate() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let text = Capture(content: "Text capture", type: .text, method: .manual)
        let url = Capture(content: "URL capture", type: .url, method: .shareSheet, sourceURL: "https://example.com")
        context.insert(text)
        context.insert(url)
        try context.save()

        // SwiftData #Predicate cannot compare custom enums via captured local variables.
        // Use fetch-all + in-memory filter instead.
        let all = try context.fetch(FetchDescriptor<Capture>())
        let urls = all.filter { $0.type == .url }
        #expect(urls.count == 1)
        #expect(urls.first?.content == "URL capture")

        let favDescriptor = FetchDescriptor<Capture>(
            predicate: #Predicate { $0.isFavorite == true }
        )
        let favorites = try context.fetch(favDescriptor)
        #expect(favorites.isEmpty)
    }
}
