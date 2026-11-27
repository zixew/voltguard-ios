import SwiftUI
import VoltGuardDomain

public struct ThemePalette: Equatable {
    public let isDark: Bool
    public let backgroundHex: String
    public let surfaceHex: String
    public let borderHex: String
    public let primaryTextHex: String
    public let secondaryTextHex: String
    public let accentHex: String
    public let warningHex: String
    public let dangerHex: String
    public let cornerRadius: Double
    public let surfaceOpacity: Double

    public var background: Color { Color(hex: backgroundHex) }
    public var surface: Color { Color(hex: surfaceHex).opacity(surfaceOpacity) }
    public var border: Color { Color(hex: borderHex) }
    public var primaryText: Color { Color(hex: primaryTextHex) }
    public var secondaryText: Color { Color(hex: secondaryTextHex) }
    public var accent: Color { Color(hex: accentHex) }
    public var warning: Color { Color(hex: warningHex) }
    public var danger: Color { Color(hex: dangerHex) }

    public static func resolve(_ config: ThemeConfig) -> ThemePalette {
        let spec: ThemeHexConstants.PaletteSpec
        switch config.preset {
        case .obsidianSlate: spec = ThemeHexConstants.obsidianSlate
        case .paperLight: spec = ThemeHexConstants.paperLight
        case .nordicMist: spec = ThemeHexConstants.nordicMist
        case .midnightAmber: spec = ThemeHexConstants.midnightAmber
        }

        let resolvedAccent = (config.customAccentHex?.isValidHex == true) ? config.customAccentHex! : spec.accent
        return ThemePalette(
            isDark: spec.isDark,
            backgroundHex: spec.background,
            surfaceHex: spec.surface,
            borderHex: spec.border,
            primaryTextHex: spec.primaryText,
            secondaryTextHex: spec.secondaryText,
            accentHex: resolvedAccent,
            warningHex: spec.warning,
            dangerHex: spec.danger,
            cornerRadius: config.cornerRadius,
            surfaceOpacity: config.surfaceOpacity
        )
    }
}

extension String {
    var isValidHex: Bool {
        let cleaned = trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        return cleaned.count == 6 && cleaned.allSatisfy(\.isHexDigit)
    }
}

public extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}
