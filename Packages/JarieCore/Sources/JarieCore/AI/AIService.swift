import Foundation

/// Errors from AI service calls
public enum AIServiceError: LocalizedError, Sendable {
    case noAPIKey
    case notAuthenticated
    case rateLimitExceeded
    case networkError(String)
    case invalidResponse
    case serverError(statusCode: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .noAPIKey: "No API key configured"
        case .notAuthenticated: "Not authenticated"
        case .rateLimitExceeded: "Rate limit exceeded"
        case .networkError(let msg): "Network error: \(msg)"
        case .invalidResponse: "Invalid AI response"
        case .serverError(let code, let msg): "Server error \(code): \(msg)"
        }
    }
}

/// Response from an AI generation call
public struct AIResponse: Sendable {
    public let text: String
    public let modelUsed: String
    public let inputTokens: Int?
    public let outputTokens: Int?

    public init(text: String, modelUsed: String, inputTokens: Int?, outputTokens: Int?) {
        self.text = text
        self.modelUsed = modelUsed
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
    }
}

/// Protocol for AI service providers (BYOK and Proxy)
public protocol AIService: Sendable {
    /// Generate a daily digest from captures
    func generateDigest(captures: [CaptureSnapshot], date: Date) async throws -> AIResponse

    /// Regenerate/update the AI profile
    func generateProfile(
        currentProfile: String?,
        recentCaptures: [CaptureSnapshot]
    ) async throws -> AIResponse

    /// Rewrite profile for a specific audience/purpose
    func rewriteProfile(
        currentProfile: String,
        prompt: String
    ) async throws -> AIResponse
}
