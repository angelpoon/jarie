import Foundation
import SwiftData
import os

/// Orchestrates AI profile generation and rewriting.
/// Trigger: when capture count > lastCaptureCountAtGeneration + threshold.
public actor ProfileGenerator {
    private let modelContainer: ModelContainer
    private let aiService: AIService
    private let markdownActor: MarkdownFileActor?
    private let logger = Logger(subsystem: "com.easyberry.jarie", category: "ProfileGenerator")

    /// Minimum new captures before regenerating profile
    private static let regenerationThreshold = 20

    public init(modelContainer: ModelContainer, aiService: AIService, markdownActor: MarkdownFileActor?) {
        self.modelContainer = modelContainer
        self.aiService = aiService
        self.markdownActor = markdownActor
    }

    /// Sendable snapshot of profile data for cross-actor transfer.
    private struct ProfileState: Sendable {
        let id: UUID
        let fullText: String
        let lastCaptureCountAtGeneration: Int
    }

    /// Check if profile needs regeneration and generate if so.
    public func generateIfNeeded() async {
        let (currentProfile, totalCaptures) = await getCurrentState()

        // Check threshold
        let lastCount = currentProfile?.lastCaptureCountAtGeneration ?? 0
        guard totalCaptures >= lastCount + Self.regenerationThreshold else {
            logger.info("Profile generation threshold not met (\(totalCaptures) captures, last at \(lastCount))")
            return
        }

        // Fetch recent captures for context
        let recentCaptures = await fetchRecentCaptures(limit: 50)
        guard !recentCaptures.isEmpty else { return }

        do {
            let response = try await aiService.generateProfile(
                currentProfile: currentProfile?.fullText,
                recentCaptures: recentCaptures
            )
            try await saveProfile(response: response, captureCount: totalCaptures)
            logger.info("Profile generated/updated at \(totalCaptures) captures")
        } catch {
            logger.error("Profile generation failed: \(error.localizedDescription)")
        }
    }

    /// Rewrite the profile for a specific audience/purpose
    public func rewrite(prompt: String) async throws -> String {
        guard let current = await getCurrentProfileState() else {
            throw ProfileError.noProfile
        }

        let response = try await aiService.rewriteProfile(
            currentProfile: current.fullText,
            prompt: prompt
        )

        // Save as a new version
        try await saveProfileVersion(
            text: response.text,
            profileId: current.id,
            prompt: prompt
        )

        return response.text
    }

    // MARK: - Private

    @MainActor
    private func getCurrentState() -> (ProfileState?, Int) {
        let context = modelContainer.mainContext

        let profileDescriptor = FetchDescriptor<AIProfile>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let profile = try? context.fetch(profileDescriptor).first
        let state = profile.map {
            ProfileState(id: $0.id, fullText: $0.fullText, lastCaptureCountAtGeneration: $0.lastCaptureCountAtGeneration)
        }

        let captureDescriptor = FetchDescriptor<Capture>(
            predicate: #Predicate { $0.isDeleted == false }
        )
        let count = (try? context.fetchCount(captureDescriptor)) ?? 0

        return (state, count)
    }

    @MainActor
    private func getCurrentProfileState() -> ProfileState? {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<AIProfile>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        guard let profile = try? context.fetch(descriptor).first else { return nil }
        return ProfileState(id: profile.id, fullText: profile.fullText, lastCaptureCountAtGeneration: profile.lastCaptureCountAtGeneration)
    }

    @MainActor
    private func fetchRecentCaptures(limit: Int) -> [CaptureSnapshot] {
        let context = modelContainer.mainContext
        var descriptor = FetchDescriptor<Capture>(
            predicate: #Predicate { $0.isDeleted == false },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        guard let captures = try? context.fetch(descriptor) else { return [] }

        return captures.map { capture in
            CaptureSnapshot(
                id: capture.id,
                content: capture.content,
                type: capture.type,
                method: capture.method,
                sourceURL: capture.sourceURL,
                sourceTitle: capture.sourceTitle,
                sourceDomain: capture.sourceDomain,
                sourceBundleID: capture.sourceBundleID,
                tags: capture.tags,
                aiSummary: capture.aiSummary,
                isFavorite: capture.isFavorite,
                createdAt: capture.createdAt
            )
        }
    }

    @MainActor
    private func saveProfile(response: AIResponse, captureCount: Int) throws {
        let context = modelContainer.mainContext

        // Create or update the profile (there should only be one)
        let descriptor = FetchDescriptor<AIProfile>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let existing = try? context.fetch(descriptor).first

        if let existing {
            existing.fullText = response.text
            existing.updatedAt = Date()
            existing.lastCaptureCountAtGeneration = captureCount

            // Save version snapshot
            let version = AIProfileVersion(
                text: response.text,
                profileId: existing.id
            )
            context.insert(version)
        } else {
            let profile = AIProfile(fullText: response.text, captureCount: captureCount)
            context.insert(profile)

            let version = AIProfileVersion(
                text: response.text,
                profileId: profile.id
            )
            context.insert(version)
        }

        try context.save()

        // Best-effort markdown export
        if let markdownActor {
            let profile = (try? context.fetch(descriptor).first)!
            let snapshot = ProfileSnapshot(
                id: profile.id, updatedAt: profile.updatedAt,
                fullText: profile.fullText,
                lastCaptureCountAtGeneration: profile.lastCaptureCountAtGeneration
            )
            Task { try? await markdownActor.writeProfile(snapshot) }
        }
    }

    @MainActor
    private func saveProfileVersion(text: String, profileId: UUID, prompt: String) throws {
        let context = modelContainer.mainContext
        let version = AIProfileVersion(text: text, profileId: profileId, prompt: prompt)
        context.insert(version)
        try context.save()
    }
}

public enum ProfileError: LocalizedError {
    case noProfile

    public var errorDescription: String? {
        switch self {
        case .noProfile: "No AI profile exists yet"
        }
    }
}
