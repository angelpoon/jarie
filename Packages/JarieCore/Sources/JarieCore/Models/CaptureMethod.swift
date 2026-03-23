import Foundation

public enum CaptureMethod: String, Codable, Sendable {
    case hotkey
    case shareSheet
    case clipboard
    case services
    case manual
    case widget
}
