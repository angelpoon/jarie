import SwiftUI

// NOTE: Primary color properties (jarieBackground, jarieTeal, etc.) are auto-generated
// by Xcode from the Asset Catalog color sets. Do NOT redeclare them here.

// MARK: - Programmatic fallbacks (used if Asset Catalog not yet configured)

public extension Color {
    static let jarieTealFallback = Color(light: .init(hex: 0x1CB6C5), dark: .init(hex: 0x2DD4E3))
    static let jariePinkFallback = Color(light: .init(hex: 0xF2809D), dark: .init(hex: 0xF599B2))
    static let jarieYellowFallback = Color(light: .init(hex: 0xF9B114), dark: .init(hex: 0xFBBF3A))
    static let jarieBlueFallback = Color(light: .init(hex: 0x75A4D8), dark: .init(hex: 0x8FB8E8))
    static let jarieBackgroundFallback = Color(light: .init(hex: 0xFFFFFF), dark: .init(hex: 0x1A1A24))
    static let jarieTextPrimaryFallback = Color(light: .init(hex: 0x39383A), dark: .init(hex: 0xE8E8EC))
    static let jarieTextSecondaryFallback = Color(light: .init(hex: 0x6B6F83), dark: .init(hex: 0x9B9FB3))
}

// MARK: - Helpers

private extension Color {
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
        #elseif canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(dark)
                : NSColor(light)
        })
        #endif
    }
}

private extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
