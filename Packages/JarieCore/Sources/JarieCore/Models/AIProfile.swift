import Foundation
import SwiftData

@Model
public final class AIProfile {
    @Attribute(.unique) public var id: UUID
    public var updatedAt: Date
    public var fullText: String
    public var lastCaptureCountAtGeneration: Int

    public init(fullText: String, captureCount: Int) {
        self.id = UUID()
        self.updatedAt = Date()
        self.fullText = fullText
        self.lastCaptureCountAtGeneration = captureCount
    }
}
