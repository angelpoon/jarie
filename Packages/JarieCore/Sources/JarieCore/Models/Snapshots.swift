import Foundation

/// Sendable value types for passing model data across actor isolation boundaries.
/// SwiftData @Model objects are not Sendable — these snapshots are.
/// See tech-architecture.md Section 13.

public struct CaptureSnapshot: Sendable {
    public let id: UUID
    public let content: String
    public let type: CaptureType
    public let method: CaptureMethod
    public let sourceURL: String?
    public let sourceTitle: String?
    public let sourceDomain: String?
    public let sourceBundleID: String?
    public let tags: [String]
    public let aiSummary: String?
    public let isFavorite: Bool
    public let createdAt: Date

    public init(
        id: UUID,
        content: String,
        type: CaptureType,
        method: CaptureMethod,
        sourceURL: String?,
        sourceTitle: String?,
        sourceDomain: String?,
        sourceBundleID: String?,
        tags: [String],
        aiSummary: String?,
        isFavorite: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.content = content
        self.type = type
        self.method = method
        self.sourceURL = sourceURL
        self.sourceTitle = sourceTitle
        self.sourceDomain = sourceDomain
        self.sourceBundleID = sourceBundleID
        self.tags = tags
        self.aiSummary = aiSummary
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }
}

public struct DigestSnapshot: Sendable {
    public let id: UUID
    public let date: Date
    public let summary: String
    public let captureIds: [UUID]
    public let captureCount: Int
    public let generatedAt: Date
    public let modelUsed: String?

    public init(
        id: UUID,
        date: Date,
        summary: String,
        captureIds: [UUID],
        captureCount: Int,
        generatedAt: Date,
        modelUsed: String?
    ) {
        self.id = id
        self.date = date
        self.summary = summary
        self.captureIds = captureIds
        self.captureCount = captureCount
        self.generatedAt = generatedAt
        self.modelUsed = modelUsed
    }
}

public struct ProfileSnapshot: Sendable {
    public let id: UUID
    public let updatedAt: Date
    public let fullText: String
    public let lastCaptureCountAtGeneration: Int

    public init(
        id: UUID,
        updatedAt: Date,
        fullText: String,
        lastCaptureCountAtGeneration: Int
    ) {
        self.id = id
        self.updatedAt = updatedAt
        self.fullText = fullText
        self.lastCaptureCountAtGeneration = lastCaptureCountAtGeneration
    }
}
