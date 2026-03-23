import Foundation
import SwiftData
import os

/// Orchestrates daily digest generation with retry logic.
/// Trigger: on app launch if today's digest doesn't exist.
/// Retry: 3x exponential backoff (1s, 4s, 16s), then mark pending.
public actor DigestGenerator {
    private let modelContainer: ModelContainer
    private let aiService: AIService
    private let markdownActor: MarkdownFileActor?
    private let logger = Logger(subsystem: "com.easyberry.jarie", category: "DigestGenerator")

    /// Key for tracking pending digest date in UserDefaults
    private static let pendingDigestKey = "com.easyberry.jarie.pendingDigestDate"

    public init(modelContainer: ModelContainer, aiService: AIService, markdownActor: MarkdownFileActor?) {
        self.modelContainer = modelContainer
        self.aiService = aiService
        self.markdownActor = markdownActor
    }

    /// Check if today's digest needs generation and generate if so.
    /// Called on app launch.
    public func generateIfNeeded() async {
        let today = DateFormatters.calendarDate(from: Date())

        // Check if digest already exists for today
        let exists = await digestExists(for: today)
        if exists {
            logger.info("Today's digest already exists")
            return
        }

        // Check if there are captures to digest
        let captures = await fetchTodayCaptures()
        guard !captures.isEmpty else {
            logger.info("No captures today — skipping digest")
            return
        }

        // Generate with retry
        await generateWithRetry(captures: captures, date: today)
    }

    /// Retry any pending digest from a previous failed attempt
    public func retryPendingIfNeeded() async {
        guard let pendingDateStr = UserDefaults.standard.string(forKey: Self.pendingDigestKey),
              let pendingInterval = Double(pendingDateStr) else { return }

        let pendingDate = Date(timeIntervalSince1970: pendingInterval)
        let captures = await fetchCaptures(for: pendingDate)

        guard !captures.isEmpty else {
            UserDefaults.standard.removeObject(forKey: Self.pendingDigestKey)
            return
        }

        logger.info("Retrying pending digest for \(DateFormatters.isoDate.string(from: pendingDate))")
        await generateWithRetry(captures: captures, date: pendingDate)
    }

    // MARK: - Private

    private func generateWithRetry(captures: [CaptureSnapshot], date: Date) async {
        let delays: [Duration] = [.seconds(1), .seconds(4), .seconds(16)]

        for (attempt, delay) in delays.enumerated() {
            do {
                let response = try await aiService.generateDigest(captures: captures, date: date)
                try await saveDigest(response: response, captures: captures, date: date)

                // Clear pending flag on success
                UserDefaults.standard.removeObject(forKey: Self.pendingDigestKey)
                logger.info("Digest generated successfully on attempt \(attempt + 1)")
                return
            } catch {
                logger.warning("Digest attempt \(attempt + 1) failed: \(error.localizedDescription)")
                if attempt < delays.count - 1 {
                    try? await Task.sleep(for: delay)
                }
            }
        }

        // All retries exhausted — mark as pending for next launch
        let dateInterval = String(date.timeIntervalSince1970)
        UserDefaults.standard.set(dateInterval, forKey: Self.pendingDigestKey)
        logger.warning("Digest generation failed after 3 attempts — marked pending")
    }

    @MainActor
    private func digestExists(for date: Date) -> Bool {
        let context = modelContainer.mainContext
        let startOfDay = date
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: date)!

        let descriptor = FetchDescriptor<DailyDigest>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay }
        )

        return (try? context.fetchCount(descriptor)) ?? 0 > 0
    }

    @MainActor
    private func fetchTodayCaptures() -> [CaptureSnapshot] {
        fetchCaptures(for: DateFormatters.calendarDate(from: Date()))
    }

    @MainActor
    private func fetchCaptures(for date: Date) -> [CaptureSnapshot] {
        let context = modelContainer.mainContext
        let startOfDay = date
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: date)!

        let descriptor = FetchDescriptor<Capture>(
            predicate: #Predicate { $0.createdAt >= startOfDay && $0.createdAt < endOfDay && $0.isDeleted == false },
            sortBy: [SortDescriptor(\.createdAt)]
        )

        guard let captures = try? context.fetch(descriptor) else { return [] }

        return captures.map { capture in
            CaptureSnapshot(
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
        }
    }

    @MainActor
    private func saveDigest(response: AIResponse, captures: [CaptureSnapshot], date: Date) throws {
        let context = modelContainer.mainContext
        let digest = DailyDigest(
            date: date,
            summary: response.text,
            captureIds: captures.map(\.id),
            captureCount: captures.count
        )
        digest.modelUsed = response.modelUsed
        context.insert(digest)
        try context.save()

        // Best-effort markdown export
        if let markdownActor {
            let snapshot = DigestSnapshot(
                id: digest.id, date: digest.date, summary: digest.summary,
                captureIds: digest.captureIds, captureCount: digest.captureCount,
                generatedAt: digest.generatedAt, modelUsed: digest.modelUsed
            )
            Task { try? await markdownActor.writeDigest(snapshot) }
        }
    }
}
