import Testing
import Foundation
@testable import JarieCore

struct MetadataFetcherTests {

    @Test func domainExtractedFromURL() async {
        let fetcher = MetadataFetcher()
        // This will fail the network fetch (invalid URL), but should still extract the domain
        let metadata = await fetcher.fetch(urlString: "https://example.com/page")
        #expect(metadata.domain == "example.com")
    }

    @Test func invalidURLReturnsDomain() async {
        let fetcher = MetadataFetcher()
        let metadata = await fetcher.fetch(urlString: "not a valid url at all")
        // URLExtractor.domain will return nil for invalid URL
        #expect(metadata.domain == nil)
    }

    @Test func metadataStructFields() {
        let metadata = MetadataFetcher.Metadata(
            title: "Test Page",
            domain: "example.com",
            faviconURL: "https://example.com/favicon.ico"
        )
        #expect(metadata.title == "Test Page")
        #expect(metadata.domain == "example.com")
        #expect(metadata.faviconURL == "https://example.com/favicon.ico")
    }

    @Test func emptyURLString() async {
        let fetcher = MetadataFetcher()
        let metadata = await fetcher.fetch(urlString: "")
        #expect(metadata.title == nil)
    }
}
