import Testing
import SwiftData
import Foundation
@testable import JarieCore

/// Mock AI service for testing
struct MockAIService: AIService {
    var digestResponse: AIResponse?
    var profileResponse: AIResponse?
    var shouldThrow: Bool = false

    func generateDigest(captures: [CaptureSnapshot], date: Date) async throws -> AIResponse {
        if shouldThrow { throw AIServiceError.networkError("mock error") }
        return digestResponse ?? AIResponse(text: "Mock digest", modelUsed: "mock-model", inputTokens: 100, outputTokens: 50)
    }

    func generateProfile(
        currentProfile: String?,
        recentCaptures: [CaptureSnapshot]
    ) async throws -> AIResponse {
        if shouldThrow { throw AIServiceError.networkError("mock error") }
        return profileResponse ?? AIResponse(text: "Mock profile", modelUsed: "mock-model", inputTokens: 200, outputTokens: 100)
    }

    func rewriteProfile(
        currentProfile: String,
        prompt: String
    ) async throws -> AIResponse {
        if shouldThrow { throw AIServiceError.networkError("mock error") }
        return AIResponse(text: "Mock rewritten profile for: \(prompt)", modelUsed: "mock-model", inputTokens: 150, outputTokens: 75)
    }
}

@MainActor
struct DigestGeneratorTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Capture.self, DailyDigest.self, AIProfile.self, AIProfileVersion.self])
        let config = ModelConfiguration("test-\(UUID().uuidString)", schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    // MARK: - generateIfNeeded with no captures

    @Test func generateIfNeededDoesNothingWithNoCaptures() async throws {
        let container = try makeContainer()
        let mockAI = MockAIService()
        let generator = DigestGenerator(modelContainer: container, aiService: mockAI, markdownActor: nil)

        // No captures inserted — should return without crashing
        await generator.generateIfNeeded()

        // Verify no digest was created
        let descriptor = FetchDescriptor<DailyDigest>()
        let digests = try container.mainContext.fetch(descriptor)
        #expect(digests.isEmpty)
    }

    // MARK: - generateIfNeeded with captures

    @Test func generateIfNeededCreatesDigestWhenCapturesExist() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        // Insert a capture for today
        let capture = Capture(content: "Test capture for digest", type: .text, method: .manual)
        context.insert(capture)
        try context.save()

        let mockAI = MockAIService(
            digestResponse: AIResponse(
                text: "Today you captured a test note.",
                modelUsed: "gpt-4",
                inputTokens: 50,
                outputTokens: 30
            )
        )
        let generator = DigestGenerator(modelContainer: container, aiService: mockAI, markdownActor: nil)

        await generator.generateIfNeeded()

        // Verify digest was created
        let descriptor = FetchDescriptor<DailyDigest>()
        let digests = try context.fetch(descriptor)
        #expect(digests.count == 1)
        #expect(digests.first?.summary == "Today you captured a test note.")
        #expect(digests.first?.modelUsed == "gpt-4")
        #expect(digests.first?.captureCount == 1)
    }

    // MARK: - generateIfNeeded skips when digest exists

    @Test func generateIfNeededSkipsWhenDigestAlreadyExists() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        // Insert a capture for today
        let capture = Capture(content: "Existing capture", type: .text, method: .manual)
        context.insert(capture)

        // Insert a digest for today
        let today = DateFormatters.calendarDate(from: Date())
        let existingDigest = DailyDigest(
            date: today,
            summary: "Already generated",
            captureIds: [capture.id],
            captureCount: 1
        )
        context.insert(existingDigest)
        try context.save()

        let mockAI = MockAIService(
            digestResponse: AIResponse(
                text: "This should not appear",
                modelUsed: "mock",
                inputTokens: 10,
                outputTokens: 5
            )
        )
        let generator = DigestGenerator(modelContainer: container, aiService: mockAI, markdownActor: nil)

        await generator.generateIfNeeded()

        // Verify only the original digest exists
        let descriptor = FetchDescriptor<DailyDigest>()
        let digests = try context.fetch(descriptor)
        #expect(digests.count == 1)
        #expect(digests.first?.summary == "Already generated")
    }

    // MARK: - Soft-deleted captures are excluded

    @Test func generateIfNeededIgnoresSoftDeletedCaptures() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        // Insert a soft-deleted capture (the only one for today)
        let capture = Capture(content: "Deleted capture", type: .text, method: .manual)
        capture.isDeleted = true
        context.insert(capture)
        try context.save()

        let mockAI = MockAIService()
        let generator = DigestGenerator(modelContainer: container, aiService: mockAI, markdownActor: nil)

        await generator.generateIfNeeded()

        // No digest should be created since all captures are deleted
        let descriptor = FetchDescriptor<DailyDigest>()
        let digests = try context.fetch(descriptor)
        #expect(digests.isEmpty)
    }

    // MARK: - MockAIService tests

    @Test func mockAIServiceReturnsConfiguredResponse() async throws {
        let customResponse = AIResponse(text: "Custom digest", modelUsed: "custom-model", inputTokens: 42, outputTokens: 21)
        let mock = MockAIService(digestResponse: customResponse)

        let result = try await mock.generateDigest(captures: [], date: Date())
        #expect(result.text == "Custom digest")
        #expect(result.modelUsed == "custom-model")
        #expect(result.inputTokens == 42)
        #expect(result.outputTokens == 21)
    }

    @Test func mockAIServiceThrowsWhenConfigured() async {
        let mock = MockAIService(shouldThrow: true)

        do {
            _ = try await mock.generateDigest(captures: [], date: Date())
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is AIServiceError)
        }
    }

    @Test func mockAIServiceProfileGeneration() async throws {
        let mock = MockAIService()
        let result = try await mock.generateProfile(currentProfile: nil, recentCaptures: [])
        #expect(result.text == "Mock profile")
    }

    @Test func mockAIServiceProfileRewrite() async throws {
        let mock = MockAIService()
        let result = try await mock.rewriteProfile(currentProfile: "existing", prompt: "make it casual")
        #expect(result.text == "Mock rewritten profile for: make it casual")
    }

    // MARK: - AIResponse

    @Test func aiResponseProperties() {
        let response = AIResponse(text: "Hello", modelUsed: "gpt-4", inputTokens: 100, outputTokens: nil)
        #expect(response.text == "Hello")
        #expect(response.modelUsed == "gpt-4")
        #expect(response.inputTokens == 100)
        #expect(response.outputTokens == nil)
    }

    // MARK: - AIServiceError

    @Test func aiServiceErrorDescriptions() {
        #expect(AIServiceError.noAPIKey.errorDescription == "No API key configured")
        #expect(AIServiceError.notAuthenticated.errorDescription == "Not authenticated")
        #expect(AIServiceError.rateLimitExceeded.errorDescription == "Rate limit exceeded")
        #expect(AIServiceError.networkError("timeout").errorDescription == "Network error: timeout")
        #expect(AIServiceError.invalidResponse.errorDescription == "Invalid AI response")
        #expect(AIServiceError.serverError(statusCode: 500, message: "Internal").errorDescription == "Server error 500: Internal")
    }
}
