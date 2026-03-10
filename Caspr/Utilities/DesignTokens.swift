import SwiftUI

// MARK: - Color(hex:) Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Design Tokens

enum DesignTokens {

    // MARK: Core Surfaces

    static let bgApp        = Color(hex: "#1A1A1E")
    static let bgPanel      = Color(hex: "#222226")
    static let bgSurface    = Color(hex: "#2A2A2E")
    static let bgSidebar    = Color(hex: "#1E1E22")
    static let bgHeader     = Color(hex: "#1C1C20")
    static let borderSubtle = Color(hex: "#333338")
    static let borderStrong = Color(hex: "#444448")

    // MARK: Text Hierarchy

    static let textPrimary   = Color(hex: "#E8E8EC")
    static let textSecondary = Color(hex: "#8E8E96")
    static let textMuted     = Color(hex: "#5A5A62")
    static let textMono      = Color(hex: "#C8C8CC")

    // MARK: Status LEDs

    static let ledRecording = Color(hex: "#EF4444")
    static let ledLive      = Color(hex: "#22C55E")
    static let ledStandby   = Color(hex: "#A3A3A3")
    static let ledPro       = Color(hex: "#8B5CF6")
    static let ledWarning   = Color(hex: "#F59E0B")

    // MARK: Speaker Colours (diarisation)

    static let speaker1 = Color(hex: "#EF4444")
    static let speaker2 = Color(hex: "#3B82F6")
    static let speaker3 = Color(hex: "#22C55E")
    static let speaker4 = Color(hex: "#F59E0B")
    static let speaker5 = Color(hex: "#8B5CF6")

    static let speakerColors: [Color] = [speaker1, speaker2, speaker3, speaker4, speaker5]

    // MARK: Accent

    static let accentPrimary = Color(hex: "#6366F1")
    static let accentHover   = Color(hex: "#818CF8")

    // MARK: Typography Helpers

    static let fontBody    = Font.system(.body, design: .default)
    static let fontDisplay = Font.system(.title, design: .default)
    static let fontMono    = Font.system(.body, design: .monospaced)
}
