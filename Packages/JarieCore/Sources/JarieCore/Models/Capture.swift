import Foundation
import SwiftData

@Model
public final class Capture {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var content: String
    public var type: CaptureType
    public var method: CaptureMethod
    public var sourceURL: String?
    public var sourceTitle: String?
    public var sourceDomain: String?
    public var sourceBundleID: String?
    public var tags: [String]
    public var isFavorite: Bool
    public var aiSummary: String?
    public var isDeleted: Bool

    // Forward compat — Optional by convention
    public var faviconURL: String?
    public var imageData: Data?
    public var filePath: String?

    public init(
        content: String,
        type: CaptureType,
        method: CaptureMethod,
        sourceURL: String? = nil,
        sourceBundleID: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.content = content
        self.type = type
        self.method = method
        self.sourceURL = sourceURL
        self.sourceBundleID = sourceBundleID
        self.tags = []
        self.isFavorite = false
        self.isDeleted = false
    }
}
