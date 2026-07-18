import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

enum AuroraColor {
    static let brandRed = Color(hex: 0xFF2D78)
    static let brandRedLight = Color(hex: 0xFF5C97)
    static let brandRedDeep = Color(hex: 0x9A1150)
    static let auroraMaroon = Color(hex: 0x3A0A2A)

    static let deepBlack = Color(hex: 0x09090C)
    static let surfaceDark = Color(hex: 0x14141B)
    static let surfaceElevated = Color(hex: 0x1E1E26)
    static let cardDark = Color(hex: 0x16161C)

    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0xB3B3BC)
    static let textMuted = Color(hex: 0x7A7A85)

    static let goldStar = Color(hex: 0xFFC93C)
    static let successGreen = Color(hex: 0x22C55E)
    static let warningYellow = Color(hex: 0xCA8A04)
    static let imdbGold = Color(hex: 0xF5C518)

    static let rankGold = Color(hex: 0xF5A623)
    static let rankGreen = Color(hex: 0x2ECC71)
    static let rankCrimson = Color(hex: 0xE8305A)
    static let fireOrange = Color(hex: 0xFF6B35)

    static let categoryDotColors: [Color] = [
        Color(hex: 0x2ED8C3),
        Color(hex: 0x8B5CF6),
        Color(hex: 0xFF2D78),
        Color(hex: 0xFFC93C),
        Color(hex: 0x3B9EFF)
    ]

    static func categoryAccent(for title: String) -> Color {
        let idx = abs(title.hashValue) % categoryDotColors.count
        return categoryDotColors[idx]
    }

    static func categoryIcon(for key: String?) -> String {
        switch key {
        case "trending": return "flame.fill"
        case "latest": return "sparkles"
        case "movies": return "film.fill"
        case "series": return "tv.fill"
        case "kdrama": return "theatermasks.fill"
        case "anime": return "wand.and.stars"
        default: return "sparkles"
        }
    }
}
