import Testing
import SwiftData
import Foundation
@testable import JarieCore

@MainActor
struct CaptureServiceTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Capture.self, DailyDigest.self, AIProfile.self, AIProfileVersion.self])
        let config = ModelConfiguration("test-\(UUID().uuidString)", schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test func emptyContentThrows() async throws {
        let container = try makeContainer()
        let service = CaptureService(modelContainer: container, markdownRootURL: nil)

        await #expect(throws: CaptureError.self) {
            try await service.save("", type: .text, method: .manual)
        }
    }

    @Test func whitespaceOnlyContentThrows() async throws {
        let container = try makeContainer()
        let service = CaptureService(modelContainer: container, markdownRootURL: nil)

        await #expect(throws: CaptureError.self) {
            try await service.save("   \n  ", type: .text, method: .manual)
        }
    }

    @Test func saveTextCapture() async throws {
        let container = try makeContainer()
        let service = CaptureService(modelContainer: container, markdownRootURL: nil)

        let id = try await service.save("Hello world", type: .text, method: .hotkey)

        let context = container.mainContext
        guard let capture = context.model(for: id) as? Capture else {
            Issue.record("Capture not found after save")
            return
        }
        #expect(capture.content == "Hello world")
        #expect(capture.type == .text)
        #expect(capture.method == .hotkey)
    }

    @Test func urlAutoDetection() async throws {
        let container = try makeContainer()
        let service = CaptureService(modelContainer: container, markdownRootURL: nil)

        let id = try await service.save(
            "Check out https://example.com for details",
            type: .text,
            method: .manual
        )

        let context = container.mainContext
        guard let capture = context.model(for: id) as? Capture else {
            Issue.record("Capture not found")
            return
        }
        #expect(capture.type == .url)
        #expect(capture.sourceURL == "https://example.com")
    }

    @Test func explicitSourceURLPreserved() async throws {
        let container = try makeContainer()
        let service = CaptureService(modelContainer: container, markdownRootURL: nil)

        let id = try await service.save(
            "Article about Swift",
            type: .url,
            method: .shareSheet,
            sourceURL: "https://swift.org/blog",
            bundleID: "com.apple.Safari"
        )

        let context = container.mainContext
        guard let capture = context.model(for: id) as? Capture else {
            Issue.record("Capture not found")
            return
        }
        #expect(capture.sourceURL == "https://swift.org/blog")
        #expect(capture.sourceBundleID == "com.apple.Safari")
        #expect(capture.sourceDomain == "swift.org")
    }

    @Test func markdownWrittenOnSave() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("jarie-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let container = try makeContainer()
        let service = CaptureService(modelContainer: container, markdownRootURL: tempDir)

        _ = try await service.save("Markdown test", type: .text, method: .manual)

        // Give fire-and-forget Task time to complete
        try await Task.sleep(for: .seconds(1))

        // Check that a markdown file was created in the date-based directory
        let contents = try FileManager.default.contentsOfDirectory(
            at: tempDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
        )
        #expect(!contents.isEmpty, "Expected markdown directory to be created")
    }
}
