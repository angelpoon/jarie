import Foundation
import os

/// Direct Anthropic API calls for BYOK tier users.
/// API key retrieved from Keychain — never logged or transmitted to Jarie backend.
/// WARNING: API key access is security-critical. See tech-arch Section 6.
public struct ClaudeProvider: AIService {
    private let session: URLSession
    private let logger = Logger(subsystem: "com.easyberry.jarie", category: "ClaudeProvider")

    /// Model to use for digest generation (cost-efficient)
    private let digestModel = "claude-haiku-4-5-20251001"
    /// Model to use for profile generation (higher quality)
    private let profileModel = "claude-sonnet-4-5-20241022"

    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let apiVersion = "2023-06-01"

    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }

    public func generateDigest(captures: [CaptureSnapshot], date: Date) async throws -> AIResponse {
        let prompt = DigestPromptBuilder.build(captures: captures, date: date)
        return try await callClaude(prompt: prompt, model: digestModel)
    }

    public func generateProfile(currentProfile: String?, recentCaptures: [CaptureSnapshot]) async throws -> AIResponse {
        let prompt = ProfilePromptBuilder.buildGeneration(
            currentProfile: currentProfile,
            recentCaptures: recentCaptures
        )
        return try await callClaude(prompt: prompt, model: profileModel)
    }

    public func rewriteProfile(currentProfile: String, prompt: String) async throws -> AIResponse {
        let fullPrompt = ProfilePromptBuilder.buildRewrite(
            currentProfile: currentProfile,
            userPrompt: prompt
        )
        return try await callClaude(prompt: fullPrompt, model: profileModel)
    }

    // MARK: - Private

    private func callClaude(prompt: String, model: String) async throws -> AIResponse {
        guard let apiKey = try KeychainStore.read(.byokAPIKey) else {
            throw AIServiceError.noAPIKey
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        if httpResponse.statusCode == 429 {
            throw AIServiceError.rateLimitExceeded
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIServiceError.serverError(statusCode: httpResponse.statusCode, message: message)
        }

        // Parse Anthropic Messages API response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            throw AIServiceError.invalidResponse
        }

        let usage = json["usage"] as? [String: Any]
        return AIResponse(
            text: text,
            modelUsed: model,
            inputTokens: usage?["input_tokens"] as? Int,
            outputTokens: usage?["output_tokens"] as? Int
        )
    }
}
