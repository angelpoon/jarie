import Foundation

/// Manages the YYYY/MM/YYYY-MM-DD.md file structure for markdown export.
public struct DailyFileWriter: Sendable {
    public let rootURL: URL

    public init(rootURL: URL) {
        self.rootURL = rootURL
    }

    /// Returns the file URL for a given date: root/YYYY/MM/YYYY-MM-DD.md
    public func dailyFileURL(for date: Date) -> URL {
        let year = DateFormatters.year.string(from: date)
        let month = DateFormatters.month.string(from: date)
        let filename = DateFormatters.isoDate.string(from: date) + ".md"
        return rootURL
            .appendingPathComponent(year)
            .appendingPathComponent(month)
            .appendingPathComponent(filename)
    }

    /// Returns the digest file URL: root/digest/YYYY-MM-DD-digest.md
    public func digestFileURL(for date: Date) -> URL {
        let filename = DateFormatters.isoDate.string(from: date) + "-digest.md"
        return rootURL
            .appendingPathComponent("digest")
            .appendingPathComponent(filename)
    }

    /// Returns the profile file URL: root/profile/ai-profile.md
    public func profileFileURL() -> URL {
        rootURL
            .appendingPathComponent("profile")
            .appendingPathComponent("ai-profile.md")
    }

    /// Ensures the directory for a file URL exists.
    public func ensureDirectoryExists(for fileURL: URL) throws {
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
}
