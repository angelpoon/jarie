import Foundation
import os

/// Resolves URL metadata: page title, domain, favicon URL. 10-second timeout, failures are silent.
public actor MetadataFetcher {
    private let session: URLSession
    private let logger = Logger(subsystem: "com.easyberry.jarie", category: "MetadataFetcher")

    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 10
        self.session = URLSession(configuration: config)
    }

    public struct Metadata: Sendable {
        public var title: String?
        public var domain: String?
        public var faviconURL: String?

        public init(title: String? = nil, domain: String? = nil, faviconURL: String? = nil) {
            self.title = title
            self.domain = domain
            self.faviconURL = faviconURL
        }
    }

    /// Fetches metadata for a URL. Returns partial results on failure — never throws.
    public func fetch(urlString: String) async -> Metadata {
        guard let url = URL(string: urlString) else {
            return Metadata(domain: URLExtractor.domain(from: urlString))
        }

        let domain = url.host(percentEncoded: false)

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode),
                  let html = String(data: data, encoding: .utf8) else {
                return Metadata(domain: domain)
            }

            let title = extractTitle(from: html)
            let faviconURL = extractFaviconURL(from: html, baseURL: url)

            return Metadata(title: title, domain: domain, faviconURL: faviconURL)
        } catch {
            logger.warning("Metadata fetch failed for \(urlString): \(error.localizedDescription)")
            return Metadata(domain: domain)
        }
    }

    // MARK: - HTML Parsing (lightweight, no dependencies)

    private func extractTitle(from html: String) -> String? {
        // TODO: HTML entity decoding not implemented. Titles like "Swift &amp; Concurrency"
        // will appear with raw entities. Address before shipping. (Review item S4)
        // Match <title>...</title> (case-insensitive, across newlines)
        guard let titleRange = html.range(
            of: "<title[^>]*>(.*?)</title>",
            options: [.regularExpression, .caseInsensitive]
        ) else { return nil }

        let match = String(html[titleRange])
        // Strip tags
        let cleaned = match
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? nil : cleaned
    }

    private func extractFaviconURL(from html: String, baseURL: URL) -> String? {
        // Look for <link rel="icon" href="..."> or rel="shortcut icon"
        guard let linkRange = html.range(
            of: #"<link[^>]*rel=["'](?:shortcut )?icon["'][^>]*>"#,
            options: [.regularExpression, .caseInsensitive]
        ) else {
            // Default favicon path
            return baseURL.scheme.map { "\($0)://\(baseURL.host(percentEncoded: false) ?? "")/favicon.ico" }
        }

        let linkTag = String(html[linkRange])

        guard let hrefRange = linkTag.range(
            of: #"href=["']([^"']+)["']"#,
            options: .regularExpression
        ) else { return nil }

        let hrefMatch = String(linkTag[hrefRange])
        let href = hrefMatch
            .replacingOccurrences(of: #"href=["']"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"["']$"#, with: "", options: .regularExpression)

        // Resolve relative URLs
        if href.hasPrefix("http") {
            return href
        } else if href.hasPrefix("//") {
            return (baseURL.scheme ?? "https") + ":" + href
        } else {
            return URL(string: href, relativeTo: baseURL)?.absoluteString
        }
    }
}
