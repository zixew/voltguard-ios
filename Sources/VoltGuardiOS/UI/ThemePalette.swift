import SwiftUI
import VoltGuardDomain

public struct ThemePalette: Equatable, Sendable {
    public let background: Color
    public let cardBackground: Color
    public let primaryText: Color
    public let secondaryText: Color
    public let accent: Color
    public let warning: Color
    public let danger: Color
    public let border: Color

    public static func resolve(_ theme: AppThemeID) -> ThemePalette {
        switch theme {
        case .obsidianSlate:
            return ThemePalette(
                background: Color(red: 0.08, green: 0.09, blue: 0.11),
                cardBackground: Color(red: 0.12, green: 0.14, blue: 0.17),
                primaryText: Color(red: 0.95, green: 0.96, blue: 0.98),
                secondaryText: Color(red: 0.62, green: 0.66, blue: 0.72),
                accent: Color(red: 0.18, green: 0.65, blue: 0.98),
                warning: Color(red: 1.0, green: 0.73, blue: 0.20),
                danger: Color(red: 0.98, green: 0.33, blue: 0.33),
                border: Color.white.opacity(0.12)
            )
        case .cyberLime:
            return ThemePalette(
                background: Color(red: 0.07, green: 0.10, blue: 0.08),
                cardBackground: Color(red: 0.11, green: 0.15, blue: 0.12),
                primaryText: Color(red: 0.94, green: 0.98, blue: 0.94),
                secondaryText: Color(red: 0.60, green: 0.75, blue: 0.62),
                accent: Color(red: 0.45, green: 0.92, blue: 0.25),
                warning: Color(red: 0.98, green: 0.75, blue: 0.20),
                danger: Color(red: 0.98, green: 0.32, blue: 0.32),
                border: Color.white.opacity(0.12)
            )
        case .hyperNeon:
            return ThemePalette(
                background: Color(red: 0.09, green: 0.08, blue: 0.13),
                cardBackground: Color(red: 0.14, green: 0.12, blue: 0.20),
                primaryText: Color(red: 0.97, green: 0.95, blue: 1.00),
                secondaryText: Color(red: 0.68, green: 0.64, blue: 0.78),
                accent: Color(red: 0.75, green: 0.35, blue: 0.98),
                warning: Color(red: 1.0, green: 0.72, blue: 0.25),
                danger: Color(red: 0.98, green: 0.30, blue: 0.45),
                border: Color.white.opacity(0.14)
            )
        case .crimsonForge:
            return ThemePalette(
                background: Color(red: 0.11, green: 0.08, blue: 0.08),
                cardBackground: Color(red: 0.17, green: 0.12, blue: 0.12),
                primaryText: Color(red: 0.98, green: 0.95, blue: 0.95),
                secondaryText: Color(red: 0.74, green: 0.62, blue: 0.62),
                accent: Color(red: 0.96, green: 0.32, blue: 0.28),
                warning: Color(red: 1.0, green: 0.70, blue: 0.20),
                danger: Color(red: 0.92, green: 0.20, blue: 0.20),
                border: Color.white.opacity(0.12)
            )
        case .cleanFrost:
            return ThemePalette(
                background: Color(red: 0.94, green: 0.96, blue: 0.98),
                cardBackground: Color.white,
                primaryText: Color(red: 0.11, green: 0.13, blue: 0.16),
                secondaryText: Color(red: 0.42, green: 0.46, blue: 0.52),
                accent: Color(red: 0.12, green: 0.52, blue: 0.90),
                warning: Color(red: 0.90, green: 0.58, blue: 0.10),
                danger: Color(red: 0.88, green: 0.22, blue: 0.22),
                border: Color.black.opacity(0.08)
            )
        }
    }
}
