import Foundation
import os

/// Thread-safe file I/O for markdown export. All writes serialized through this actor.
public actor MarkdownFileActor {
    private let fileWriter: DailyFileWriter
    private let logger = Logger(subsystem: "com.easyberry.jarie", category: "MarkdownFileActor")

    public init(rootURL: URL) {
        self.fileWriter = DailyFileWriter(rootURL: rootURL)
    }

    /// Appends a capture's markdown to the daily file.
    public func appendCapture(_ capture: CaptureSnapshot) async throws {
        let fileURL = fileWriter.dailyFileURL(for: capture.createdAt)
        try fileWriter.ensureDirectoryExists(for: fileURL)

        let markdown = MarkdownExporter.format(capture)
        try appendToFile(markdown, at: fileURL)

        logger.info("Appended capture \(capture.id) to \(fileURL.lastPathComponent)")
    }

    /// Writes a digest to its own markdown file.
    public func writeDigest(_ digest: DigestSnapshot) async throws {
        let fileURL = fileWriter.digestFileURL(for: digest.date)
        try fileWriter.ensureDirectoryExists(for: fileURL)

        let markdown = MarkdownExporter.formatDigest(digest)
        try markdown.write(to: fileURL, atomically: true, encoding: .utf8)

        logger.info("Wrote digest for \(DateFormatters.isoDate.string(from: digest.date))")
    }

    /// Writes (overwrites) the AI profile markdown file.
    public func writeProfile(_ profile: ProfileSnapshot) async throws {
        let fileURL = fileWriter.profileFileURL()
        try fileWriter.ensureDirectoryExists(for: fileURL)

        let markdown = MarkdownExporter.formatProfile(profile)
        try markdown.write(to: fileURL, atomically: true, encoding: .utf8)

        logger.info("Wrote AI profile")
    }

    // MARK: - Private

    private func appendToFile(_ content: String, at url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            try handle.seekToEnd()
            guard let data = content.data(using: .utf8) else { return }
            try handle.write(contentsOf: data)
        } else {
            // Add daily file header for new files
            let date = url.deletingPathExtension().lastPathComponent
            let header = "# Captures — \(date)\n\n"
            try (header + content).write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
