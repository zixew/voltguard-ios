import Foundation
import CoreGraphics

public enum MotionConstants {
    public static let flowCycleSeconds: Double = 1.6
    public static let flowFrameInterval: Double = 1.0 / 30.0
    public static let uiTransitionDuration: Double = 0.22
}

public enum LiquidBatteryConstants {
    public static let cellWidth: CGFloat = 86
    public static let cellHeight: CGFloat = 124
    public static let waveAmplitude: CGFloat = 3.6
    public static let calmWaveAmplitude: CGFloat = 1.6
    public static let waveCycles: Double = 1.6
    public static let waveCycleSeconds: Double = 2.2
    public static let calmWaveCycleSeconds: Double = 4.5
    public static let calmFlowFrameInterval: Double = 1.0 / 15.0
}

public enum ThemeHexConstants {
    public struct PaletteSpec {
        public let isDark: Bool
        public let background: String
        public let surface: String
        public let border: String
        public let primaryText: String
        public let secondaryText: String
        public let accent: String
        public let warning: String
        public let danger: String
    }

    public static let obsidianSlate = PaletteSpec(
        isDark: true,
        background: "#12151A",
        surface: "#1B2028",
        border: "#2D3542",
        primaryText: "#F2F4F8",
        secondaryText: "#A3ACB9",
        accent: "#10B981",
        warning: "#F59E0B",
        danger: "#EF4444"
    )

    public static let paperLight = PaletteSpec(
        isDark: false,
        background: "#F5F6F8",
        surface: "#FFFFFF",
        border: "#D1D5DB",
        primaryText: "#111827",
        secondaryText: "#4B5563",
        accent: "#047857",
        warning: "#B45309",
        danger: "#B91C1C"
    )

    public static let nordicMist = PaletteSpec(
        isDark: true,
        background: "#161B22",
        surface: "#212832",
        border: "#35404F",
        primaryText: "#EEF2F6",
        secondaryText: "#9AA7B8",
        accent: "#2DD4BF",
        warning: "#FBBF24",
        danger: "#F87171"
    )

    public static let midnightAmber = PaletteSpec(
        isDark: true,
        background: "#141210",
        surface: "#211D18",
        border: "#3A3229",
        primaryText: "#F7F3EE",
        secondaryText: "#B8ADA0",
        accent: "#F59E0B",
        warning: "#FB923C",
        danger: "#F87171"
    )

    public static let accentSwatches = ["#10B981", "#F59E0B", "#0EA5E9", "#EC4899"]
}
