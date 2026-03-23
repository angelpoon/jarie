import Testing
import Foundation
@testable import JarieCore

struct DailyFileWriterTests {

    @Test func dailyFileURL() {
        let root = URL(fileURLWithPath: "/tmp/mind/collected")
        let writer = DailyFileWriter(rootURL: root)

        // Create a known date: 2026-03-15
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 15
        let date = Calendar.current.date(from: components)!

        let url = writer.dailyFileURL(for: date)
        #expect(url.path.contains("2026/03/2026-03-15.md"))
    }

    @Test func digestFileURL() {
        let root = URL(fileURLWithPath: "/tmp/mind/collected")
        let writer = DailyFileWriter(rootURL: root)

        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 15
        let date = Calendar.current.date(from: components)!

        let url = writer.digestFileURL(for: date)
        #expect(url.path.contains("digest/2026-03-15-digest.md"))
    }

    @Test func profileFileURL() {
        let root = URL(fileURLWithPath: "/tmp/mind/collected")
        let writer = DailyFileWriter(rootURL: root)

        let url = writer.profileFileURL()
        #expect(url.path.contains("profile/ai-profile.md"))
    }
}
