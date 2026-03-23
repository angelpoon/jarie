import SwiftUI

/// Custom text styles matching EasyBerry design system. All sizes scale with Dynamic Type.
public enum JarieFont {
    /// 28pt Bold — Dashboard header (scales with .largeTitle)
    public static let display: Font = .system(.largeTitle, design: .default, weight: .bold)

    /// 20pt Semibold — Section headers, digest title (scales with .title2)
    public static let title: Font = .system(.title2, design: .default, weight: .semibold)

    /// 17pt Semibold — Capture row title (scales with .headline)
    public static let headline: Font = .system(.headline, design: .default, weight: .semibold)

    /// 15pt Regular — Content text, profile text (scales with .body)
    public static let body: Font = .system(.body, design: .default)

    /// 13pt Regular — Source domain, timestamp (scales with .caption)
    public static let caption: Font = .system(.caption, design: .default)

    /// 11pt Regular — Metadata, counts (scales with .caption2)
    public static let footnote: Font = .system(.caption2, design: .default)
}

/// Elevation shadow for floating elements only (toast, dropdown, sheets).
public extension View {
    func jarieFloatingShadow() -> some View {
        self.shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}
