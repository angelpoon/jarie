import Foundation
import SwiftData

@Model
public final class DailyDigest {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var summary: String
    public var captureIds: [UUID]       // Non-queryable blob — display-only, not a relationship. See tech-arch.md Section 1.
    public var captureCount: Int
    public var generatedAt: Date
    public var modelUsed: String?

    public init(date: Date, summary: String, captureIds: [UUID], captureCount: Int) {
        self.id = UUID()
        self.date = date
        self.summary = summary
        self.captureIds = captureIds
        self.captureCount = captureCount
        self.generatedAt = Date()
    }
}
