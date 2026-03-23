import Foundation

public enum CaptureType: String, Codable, Sendable {
    case text
    case url
    case image  // Forward compat — not implemented in v1
    case file   // Forward compat — not implemented in v1
}
