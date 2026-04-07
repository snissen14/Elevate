import SwiftUI

// MARK: - Unified Color Palette

enum AppTheme {

    // MARK: Background layers (darkest → lightest)
    static let backgroundPrimary   = Color(hex: "0A0E1A")   // deep navy – screen bg
    static let backgroundCard      = Color(hex: "141929")   // card surface
    static let backgroundElevated  = Color(hex: "1C2137")   // raised elements (buttons)

    // MARK: Borders & separators
    static let border              = Color(hex: "2A3050")   // subtle card outlines
    static let borderActive        = Color(hex: "3D4A6E")   // focused / pressed

    // MARK: Accent
    static let accent              = Color(hex: "34D399")   // emerald-green – primary accent
    static let accentMuted         = Color(hex: "34D399").opacity(0.25)

    // MARK: Text
    static let textPrimary         = Color.white
    static let textSecondary       = Color(hex: "8892B0")   // muted slate-blue
    static let textTertiary        = Color(hex: "5A6380")

    // MARK: Semantic
    static let connected           = accent
    static let destructive         = Color(hex: "F87171")   // soft red (stop)

    // MARK: Glow / overlay
    static let glowAccent          = accent.opacity(0.15)

    // MARK: Corner radii
    static let radiusSmall:  CGFloat = 14
    static let radiusMedium: CGFloat = 20
    static let radiusLarge:  CGFloat = 24
}

// MARK: - Hex convenience

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8)  & 0xFF) / 255
            b = Double(int         & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}
