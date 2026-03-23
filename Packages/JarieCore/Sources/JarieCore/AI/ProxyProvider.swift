import Foundation
import os

/// Routes AI requests through Jarie backend proxy for AI-included tier users.
/// JWT-validated. Input discarded post-response. See tech-arch Section 3.
public struct ProxyProvider: AIService {
    private let session: URLSession
    private let logger = Logger(subsystem: "com.easyberry.jarie", category: "ProxyProvider")

    // TODO: Phase 1.5A — set real proxy URL after backend deployment
    private let proxyBaseURL = URL(string: "https://api.easyberry.com/proxy")!

    /// Closure to get current JWT — injected from AccountManager
    private let getJWT: @Sendable () async throws -> String

    public init(jwtProvider: @escaping @Sendable () async throws -> String) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
        self.getJWT = jwtProvider
    }

    public func generateDigest(captures: [CaptureSnapshot], date: Date) async throws -> AIResponse {
        let prompt = DigestPromptBuilder.build(captures: captures, date: date)
        return try await callProxy(endpoint: "digest", prompt: prompt)
    }

    public func generateProfile(currentProfile: String?, recentCaptures: [CaptureSnapshot]) async throws -> AIResponse {
        let prompt = ProfilePromptBuilder.buildGeneration(
            currentProfile: currentProfile,
            recentCaptures: recentCaptures
        )
        return try await callProxy(endpoint: "profile", prompt: prompt)
    }

    public func rewriteProfile(currentProfile: String, prompt: String) async throws -> AIResponse {
        let fullPrompt = ProfilePromptBuilder.buildRewrite(
            currentProfile: currentProfile,
            userPrompt: prompt
        )
        return try await callProxy(endpoint: "profile/rewrite", prompt: fullPrompt)
    }

    // MARK: - Private

    private func callProxy(endpoint: String, prompt: String) async throws -> AIResponse {
        let jwt = try await getJWT()
        let url = proxyBaseURL.appendingPathComponent(endpoint)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = ["prompt": prompt]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw AIServiceError.notAuthenticated
        }
        if httpResponse.statusCode == 429 {
            throw AIServiceError.rateLimitExceeded
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIServiceError.serverError(statusCode: httpResponse.statusCode, message: message)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else {
            throw AIServiceError.invalidResponse
        }

        return AIResponse(
            text: text,
            modelUsed: json["model"] as? String ?? "unknown",
            inputTokens: json["input_tokens"] as? Int,
            outputTokens: json["output_tokens"] as? Int
        )
    }
}
