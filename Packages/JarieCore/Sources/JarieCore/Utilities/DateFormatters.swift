import Foundation

/// Shared date formatters. Thread-safe per Apple documentation (iOS 7+ / macOS 10.9+).
/// Marked @unchecked Sendable because DateFormatter is not formally Sendable
/// but is documented as safe for concurrent reads.
public enum DateFormatters: @unchecked Sendable {
    /// "March 15, 2026"
    public static let fullDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }() // Uses device-local timezone (intentional — matches user's calendar day)

    /// "4:12 PM"
    public static let time: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }() // Uses device-local timezone (intentional — matches user's calendar day)

    /// "2026-03-15" — used in markdown file naming
    public static let isoDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }() // Uses device-local timezone (intentional — matches user's calendar day)

    /// "2026" — year directory name
    public static let year: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }() // Uses device-local timezone (intentional — matches user's calendar day)

    /// "03" — month directory name
    public static let month: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }() // Uses device-local timezone (intentional — matches user's calendar day)

    /// "4 min ago", "2 hours ago" — relative timestamps
    /// RelativeDateTimeFormatter is not formally Sendable — same rationale as DateFormatter above.
    nonisolated(unsafe) public static let relative: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    /// Calendar date (no time) for digest date comparisons
    public static func calendarDate(from date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    /// Check if a date is today
    public static func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}
