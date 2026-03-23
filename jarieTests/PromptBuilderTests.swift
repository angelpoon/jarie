import Testing
import Foundation
@testable import JarieCore

struct PromptBuilderTests {

    // MARK: - Helpers

    private func makeCapture(
        content: String,
        type: CaptureType = .text,
        sourceURL: String? = nil,
        sourceTitle: String? = nil,
        sourceDomain: String? = nil,
        tags: [String] = [],
        createdAt: Date = Date()
    ) -> CaptureSnapshot {
        CaptureSnapshot(
            id: UUID(),
            content: content,
            type: type,
            method: .manual,
            sourceURL: sourceURL,
            sourceTitle: sourceTitle,
            sourceDomain: sourceDomain,
            sourceBundleID: nil,
            tags: tags,
            aiSummary: nil,
            isFavorite: false,
            createdAt: createdAt
        )
    }

    // MARK: - DigestPromptBuilder

    @Test func digestPromptWithTextCaptures() {
        let captures = [
            makeCapture(content: "Swift concurrency is great"),
            makeCapture(content: "Need to refactor the network layer"),
        ]
        let date = Date()

        let prompt = DigestPromptBuilder.build(captures: captures, date: date)

        #expect(prompt.contains("Swift concurrency is great"))
        #expect(prompt.contains("Need to refactor the network layer"))
        #expect(prompt.contains("Number of captures: 2"))
        #expect(prompt.contains("daily digest"))
    }

    @Test func digestPromptWithURLCaptures() {
        let captures = [
            makeCapture(
                content: "https://swift.org",
                type: .url,
                sourceURL: "https://swift.org",
                sourceTitle: "Swift.org",
                sourceDomain: "swift.org"
            ),
        ]
        let date = Date()

        let prompt = DigestPromptBuilder.build(captures: captures, date: date)

        // URL captures should be formatted as markdown links
        #expect(prompt.contains("[Swift.org](https://swift.org)"))
        #expect(prompt.contains("(from swift.org)"))
        #expect(prompt.contains("Number of captures: 1"))
    }

    @Test func digestPromptURLWithoutTitleUsesContent() {
        let captures = [
            makeCapture(
                content: "https://example.com/article",
                type: .url,
                sourceURL: "https://example.com/article",
                sourceTitle: nil
            ),
        ]

        let prompt = DigestPromptBuilder.build(captures: captures, date: Date())

        // When no sourceTitle, content is used as the link text
        #expect(prompt.contains("[https://example.com/article](https://example.com/article)"))
    }

    @Test func digestPromptWithEmptyCaptures() {
        let captures: [CaptureSnapshot] = []
        let date = Date()

        let prompt = DigestPromptBuilder.build(captures: captures, date: date)

        #expect(prompt.contains("Number of captures: 0"))
        // Should still produce a valid prompt structure
        #expect(prompt.contains("daily digest"))
    }

    @Test func digestPromptIncludesDate() {
        let captures = [makeCapture(content: "test")]
        // Use a specific date
        let components = DateComponents(year: 2026, month: 3, day: 15)
        let date = Calendar.current.date(from: components)!

        let prompt = DigestPromptBuilder.build(captures: captures, date: date)

        let expectedDateStr = DateFormatters.fullDate.string(from: date)
        #expect(prompt.contains(expectedDateStr))
    }

    @Test func digestPromptIncludesTime() {
        let date = Date()
        let captures = [makeCapture(content: "timed capture", createdAt: date)]

        let prompt = DigestPromptBuilder.build(captures: captures, date: date)

        let expectedTime = DateFormatters.time.string(from: date)
        #expect(prompt.contains(expectedTime))
    }

    @Test func digestPromptNumbersCaptures() {
        let captures = [
            makeCapture(content: "First"),
            makeCapture(content: "Second"),
            makeCapture(content: "Third"),
        ]

        let prompt = DigestPromptBuilder.build(captures: captures, date: Date())

        #expect(prompt.contains("1. First"))
        #expect(prompt.contains("2. Second"))
        #expect(prompt.contains("3. Third"))
    }

    // MARK: - ProfilePromptBuilder — Generation

    @Test func profileGenerationWithNoExistingProfile() {
        let captures = [
            makeCapture(content: "Learning SwiftUI", tags: ["swift", "ui"]),
            makeCapture(content: "Docker setup guide", tags: ["devops"]),
        ]

        let prompt = ProfilePromptBuilder.buildGeneration(
            currentProfile: nil,
            recentCaptures: captures
        )

        #expect(prompt.contains("first profile generation"))
        #expect(prompt.contains("Create a comprehensive profile from scratch"))
        #expect(prompt.contains("Learning SwiftUI"))
        #expect(prompt.contains("[tags: swift, ui]"))
        #expect(prompt.contains("Docker setup guide"))
        #expect(prompt.contains("[tags: devops]"))
    }

    @Test func profileGenerationWithExistingProfile() {
        let existingProfile = "This person is a Swift developer interested in iOS apps."
        let captures = [
            makeCapture(content: "Kubernetes tutorial"),
        ]

        let prompt = ProfilePromptBuilder.buildGeneration(
            currentProfile: existingProfile,
            recentCaptures: captures
        )

        #expect(prompt.contains("current profile to update"))
        #expect(prompt.contains(existingProfile))
        #expect(prompt.contains("Preserve existing insights"))
        #expect(prompt.contains("Kubernetes tutorial"))
        // Should NOT contain first-generation language
        #expect(!prompt.contains("first profile generation"))
    }

    @Test func profileGenerationUsesURLTitles() {
        let captures = [
            makeCapture(
                content: "https://example.com",
                type: .url,
                sourceURL: "https://example.com",
                sourceTitle: "Example Article Title"
            ),
        ]

        let prompt = ProfilePromptBuilder.buildGeneration(
            currentProfile: nil,
            recentCaptures: captures
        )

        // For profile prompts, URL captures use sourceTitle
        #expect(prompt.contains("Example Article Title"))
    }

    @Test func profileGenerationTruncatesLongContent() {
        let longContent = String(repeating: "a", count: 500)
        let captures = [makeCapture(content: longContent)]

        let prompt = ProfilePromptBuilder.buildGeneration(
            currentProfile: nil,
            recentCaptures: captures
        )

        // Content should be truncated to 200 characters
        let truncated = String(longContent.prefix(200))
        #expect(prompt.contains(truncated))
        #expect(!prompt.contains(longContent))
    }

    @Test func profileGenerationLimitsTo50Captures() {
        let captures = (0..<100).map { i in
            makeCapture(content: "Capture \(i)")
        }

        let prompt = ProfilePromptBuilder.buildGeneration(
            currentProfile: nil,
            recentCaptures: captures
        )

        // Should include capture 49 but not capture 50
        #expect(prompt.contains("Capture 49"))
        #expect(!prompt.contains("Capture 50"))
    }

    // MARK: - ProfilePromptBuilder — Rewrite

    @Test func profileRewriteIncludesUserPrompt() {
        let profile = "A developer focused on mobile apps."
        let userPrompt = "Make it focused on hiring managers"

        let prompt = ProfilePromptBuilder.buildRewrite(
            currentProfile: profile,
            userPrompt: userPrompt
        )

        #expect(prompt.contains(profile))
        #expect(prompt.contains(userPrompt))
        #expect(prompt.contains("Rewrite the profile"))
    }

    @Test func profileRewritePreservesProfileContent() {
        let profile = "Interests: Swift, Rust, distributed systems.\nTools: Xcode, VS Code."
        let userPrompt = "Make it casual"

        let prompt = ProfilePromptBuilder.buildRewrite(
            currentProfile: profile,
            userPrompt: userPrompt
        )

        #expect(prompt.contains("Swift, Rust, distributed systems"))
        #expect(prompt.contains("Xcode, VS Code"))
    }

    @Test func profileGenerationIncludesStructureGuidelines() {
        let prompt = ProfilePromptBuilder.buildGeneration(
            currentProfile: nil,
            recentCaptures: [makeCapture(content: "test")]
        )

        #expect(prompt.contains("Interests & Focus Areas"))
        #expect(prompt.contains("Professional Context"))
        #expect(prompt.contains("Tools & Technologies"))
        #expect(prompt.contains("Communication Style"))
        #expect(prompt.contains("Current Projects"))
    }
}
