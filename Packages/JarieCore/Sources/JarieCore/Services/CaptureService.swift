import Foundation
import SwiftData
import os

/// Orchestrates the full capture pipeline: validate → save → markdown → enrich.
/// All platform-specific callers funnel through this single entry point.
public actor CaptureService {
    private let modelContainer: ModelContainer
    private let markdownActor: MarkdownFileActor?
    private let enrichment: MetadataFetcher
    private let logger = Logger(subsystem: "com.easyberry.jarie", category: "CaptureService")

    public init(modelContainer: ModelContainer, markdownRootURL: URL?) {
        self.modelContainer = modelContainer
        self.markdownActor = markdownRootURL.map { MarkdownFileActor(rootURL: $0) }
        self.enrichment = MetadataFetcher()
    }

    /// Saves a new capture. SwiftData write is critical; markdown and enrichment are best-effort.
    @discardableResult
    public func save(
        _ content: String,
        type: CaptureType,
        method: CaptureMethod,
        sourceURL: String? = nil,
        bundleID: String? = nil
    ) async throws -> PersistentIdentifier {
        let content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else {
            throw CaptureError.emptyContent
        }

        // Detect URL type if not explicitly set (W4: single scan, cached result)
        let detectedURL: URL? = (type == .text && sourceURL == nil) ? URLExtractor.firstURL(from: content) : nil
        let resolvedType: CaptureType = detectedURL != nil ? .url : type
        let resolvedSourceURL = sourceURL ?? detectedURL?.absoluteString
        let domain = resolvedSourceURL.flatMap { URLExtractor.domain(from: $0) }

        // CRITICAL: Persist to SwiftData and create snapshot on same MainActor hop.
        // This avoids a race where fire-and-forget tasks read a not-yet-flushed record.
        let (captureID, snapshot) = try await persistAndSnapshot(
            content: content,
            type: resolvedType,
            method: method,
            sourceURL: resolvedSourceURL,
            sourceDomain: domain,
            bundleID: bundleID
        )

        logger.info("Capture saved: \(String(describing: captureID))")

        // Fire-and-forget: unstructured Task inherits actor isolation.
        // Acceptable for best-effort work; revisit if lifecycle management
        // becomes important (e.g., Share Extension teardown in Phase 3).

        // BEST-EFFORT: Markdown export (fire-and-forget)
        if let markdownActor {
            Task {
                do {
                    try await markdownActor.appendCapture(snapshot)
                } catch {
                    self.logger.error("Markdown write failed: \(error.localizedDescription)")
                }
            }
        }

        // BEST-EFFORT: URL enrichment (fire-and-forget)
        if resolvedType == .url, let urlString = resolvedSourceURL {
            Task {
                await self.enrichCapture(id: captureID, urlString: urlString)
            }
        }

        return captureID
    }

    // MARK: - Private

    /// Persist and create snapshot in a single @MainActor hop to avoid race conditions.
    @MainActor
    private func persistAndSnapshot(
        content: String,
        type: CaptureType,
        method: CaptureMethod,
        sourceURL: String?,
        sourceDomain: String?,
        bundleID: String?
    ) throws -> (PersistentIdentifier, CaptureSnapshot) {
        let context = modelContainer.mainContext
        let capture = Capture(
            content: content,
            type: type,
            method: method,
            sourceURL: sourceURL,
            sourceBundleID: bundleID
        )
        capture.sourceDomain = sourceDomain
        context.insert(capture)
        try context.save()

        let snapshot = CaptureSnapshot(
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
        return (capture.persistentModelID, snapshot)
    }

    private func enrichCapture(id: PersistentIdentifier, urlString: String) async {
        let metadata = await enrichment.fetch(urlString: urlString)

        do {
            try await applyEnrichment(id: id, metadata: metadata)
            logger.info("Enriched capture \(String(describing: id))")
        } catch {
            logger.warning("Enrichment apply failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func applyEnrichment(id: PersistentIdentifier, metadata: MetadataFetcher.Metadata) throws {
        let context = modelContainer.mainContext
        guard let capture = context.model(for: id) as? Capture else { return }

        if let title = metadata.title, capture.sourceTitle == nil {
            capture.sourceTitle = title
        }
        if let domain = metadata.domain, capture.sourceDomain == nil {
            capture.sourceDomain = domain
        }
        if let favicon = metadata.faviconURL, capture.faviconURL == nil {
            capture.faviconURL = favicon
        }

        try context.save()
    }
}

public enum CaptureError: LocalizedError {
    case emptyContent
    case notFound

    public var errorDescription: String? {
        switch self {
        case .emptyContent: "Capture content cannot be empty"
        case .notFound: "Capture not found"
        }
    }
}
