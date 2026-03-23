import Foundation

/// URL detection utilities. Thread-safe: NSDataDetector is immutable after init.
/// Marked @unchecked Sendable for cross-actor access.
public nonisolated enum URLExtractor: @unchecked Sendable {
    private static let detector: NSDataDetector? = {
        try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    }()

    /// Extracts the first URL found in the given text.
    public static func firstURL(from text: String) -> URL? {
        guard let detector else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        return detector.firstMatch(in: text, range: range)?.url
    }

    /// Extracts all URLs found in the given text.
    public static func allURLs(from text: String) -> [URL] {
        guard let detector else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return detector.matches(in: text, range: range).compactMap(\.url)
    }

    /// Returns true if the text contains at least one URL.
    public static func containsURL(_ text: String) -> Bool {
        firstURL(from: text) != nil
    }

    /// Extracts the domain (host) from a URL string.
    public static func domain(from urlString: String) -> String? {
        URL(string: urlString)?.host(percentEncoded: false)
    }
}
