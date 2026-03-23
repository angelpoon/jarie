import Testing
import Foundation
@testable import JarieCore

struct MarkdownExporterTests {

    @Test func formatTextCapture() {
        let capture = CaptureSnapshot(
            id: UUID(), content: "Hello world", type: .text, method: .hotkey,
            sourceURL: nil, sourceTitle: nil, sourceDomain: nil, sourceBundleID: nil,
            tags: [], aiSummary: nil, isFavorite: false, createdAt: Date()
        )
        let markdown = MarkdownExporter.format(capture)

        #expect(markdown.contains("Hello world"))
        #expect(markdown.contains("Method: hotkey"))
        #expect(markdown.contains("---"))
    }

    @Test func formatURLCapture() {
        let capture = CaptureSnapshot(
            id: UUID(), content: "Article title", type: .url, method: .shareSheet,
            sourceURL: "https://example.com/article", sourceTitle: "Example Article",
            sourceDomain: "example.com", sourceBundleID: nil,
            tags: [], aiSummary: nil, isFavorite: false, createdAt: Date()
        )

        let markdown = MarkdownExporter.format(capture)

        #expect(markdown.contains("[Example Article](https://example.com/article)"))
        #expect(markdown.contains("Source: example.com"))
    }

    @Test func formatCaptureWithTags() {
        let capture = CaptureSnapshot(
            id: UUID(), content: "Tagged content", type: .text, method: .manual,
            sourceURL: nil, sourceTitle: nil, sourceDomain: nil, sourceBundleID: nil,
            tags: ["ai", "swift"], aiSummary: nil, isFavorite: false, createdAt: Date()
        )

        let markdown = MarkdownExporter.format(capture)
        #expect(markdown.contains("Tags: ai, swift"))
    }

    @Test func formatCaptureWithAISummary() {
        let capture = CaptureSnapshot(
            id: UUID(), content: "Long content", type: .text, method: .hotkey,
            sourceURL: nil, sourceTitle: nil, sourceDomain: nil, sourceBundleID: nil,
            tags: [], aiSummary: "Brief summary", isFavorite: false, createdAt: Date()
        )

        let markdown = MarkdownExporter.format(capture)
        #expect(markdown.contains("AI: Brief summary"))
    }

    @Test func formatDigest() {
        let digest = DigestSnapshot(
            id: UUID(), date: Date(),
            summary: "Today you focused on AI and Swift.",
            captureIds: [UUID(), UUID()],
            captureCount: 2,
            generatedAt: Date(),
            modelUsed: "claude-haiku-4-5-20251001"
        )

        let markdown = MarkdownExporter.formatDigest(digest)

        #expect(markdown.contains("# Daily Digest"))
        #expect(markdown.contains("2 captures"))
        #expect(markdown.contains("Today you focused on AI and Swift."))
        #expect(markdown.contains("claude-haiku-4-5-20251001"))
    }

    @Test func formatProfile() {
        let profile = ProfileSnapshot(
            id: UUID(), updatedAt: Date(),
            fullText: "Angel is a developer who loves Swift.",
            lastCaptureCountAtGeneration: 100
        )

        let markdown = MarkdownExporter.formatProfile(profile)

        #expect(markdown.contains("# AI Profile"))
        #expect(markdown.contains("100 captures"))
        #expect(markdown.contains("Angel is a developer"))
    }
}
