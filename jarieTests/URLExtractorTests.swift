import Testing
import Foundation
@testable import JarieCore

struct URLExtractorTests {

    @Test func extractSingleURL() {
        let text = "Check out https://example.com for more info"
        let url = URLExtractor.firstURL(from: text)
        #expect(url?.host == "example.com")
    }

    @Test func extractMultipleURLs() {
        let text = "Visit https://a.com and https://b.com"
        let urls = URLExtractor.allURLs(from: text)
        #expect(urls.count == 2)
    }

    @Test func noURLInText() {
        let text = "Just plain text with no links"
        #expect(URLExtractor.firstURL(from: text) == nil)
        #expect(URLExtractor.containsURL(text) == false)
    }

    @Test func containsURL() {
        #expect(URLExtractor.containsURL("See https://example.com") == true)
        #expect(URLExtractor.containsURL("No URL here") == false)
    }

    @Test func domainExtraction() {
        #expect(URLExtractor.domain(from: "https://www.example.com/path") == "www.example.com")
        #expect(URLExtractor.domain(from: "not a url") == nil)
    }

    @Test func emptyString() {
        #expect(URLExtractor.firstURL(from: "") == nil)
        #expect(URLExtractor.allURLs(from: "").isEmpty)
    }
}
