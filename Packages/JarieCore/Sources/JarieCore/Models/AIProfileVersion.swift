import Foundation
import SwiftData

@Model
public final class AIProfileVersion {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var prompt: String?
    public var text: String
    public var profileId: UUID  // Manual foreign key — no SwiftData relationship

    public init(text: String, profileId: UUID, prompt: String? = nil) {
        self.id = UUID()
        self.createdAt = Date()
        self.text = text
        self.profileId = profileId
        self.prompt = prompt
    }
}
