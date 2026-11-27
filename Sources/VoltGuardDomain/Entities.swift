import Foundation

public enum VoltGuardiOSLimits {
    public static let minLimitPercent = 50
    public static let maxLimitPercent = 100
    public static let defaultLimitPercent = 80
    public static let quickPresets = [60, 80, 90, 100]

    public static let minSailingDeltaPercent = 2
    public static let maxSailingDeltaPercent = 20
    public static let defaultSailingDeltaPercent = 5

    public static let lowBatteryAlertThresholdPercent = 20
    public static let alertCooldownSeconds: TimeInterval = 120
    public static let minCornerRadius = 8.0
    public static let maxCornerRadius = 22.0
    public static let defaultCornerRadius = 14.0
    public static let minSurfaceOpacity = 0.72
    public static let maxSurfaceOpacity = 1.0
    public static let defaultSurfaceOpacity = 0.94
}

public enum AppLocale: String, Codable, CaseIterable, Sendable {
    case en
    case id
}

public enum ThemePreset: String, Codable, CaseIterable, Sendable {
    case obsidianSlate
    case paperLight
    case nordicMist
    case midnightAmber
}

public enum BatteryColorStyle: String, Codable, CaseIterable, Sendable {
    case adaptiveSpectrum
    case thermalReactive
    case themeAccent
}

public struct ThemeConfig: Codable, Equatable, Sendable {
    public var preset: ThemePreset
    public var customAccentHex: String?
    public var cornerRadius: Double
    public var surfaceOpacity: Double
    public var useCustomBackground: Bool
    public var customBackgroundPath: String?
    public var backgroundScrimOpacity: Double
    public var backgroundBlurRadius: Double
    public var batteryColorStyle: BatteryColorStyle

    public init(
        preset: ThemePreset = .obsidianSlate,
        customAccentHex: String? = nil,
        cornerRadius: Double = VoltGuardiOSLimits.defaultCornerRadius,
        surfaceOpacity: Double = VoltGuardiOSLimits.defaultSurfaceOpacity,
        useCustomBackground: Bool = false,
        customBackgroundPath: String? = nil,
        backgroundScrimOpacity: Double = 0.68,
        backgroundBlurRadius: Double = 0.0,
        batteryColorStyle: BatteryColorStyle = .adaptiveSpectrum
    ) {
        self.preset = preset
        self.customAccentHex = customAccentHex
        self.cornerRadius = min(max(cornerRadius, VoltGuardiOSLimits.minCornerRadius), VoltGuardiOSLimits.maxCornerRadius)
        self.surfaceOpacity = min(max(surfaceOpacity, VoltGuardiOSLimits.minSurfaceOpacity), VoltGuardiOSLimits.maxSurfaceOpacity)
        self.useCustomBackground = useCustomBackground
        self.customBackgroundPath = customBackgroundPath
        self.backgroundScrimOpacity = min(max(backgroundScrimOpacity, 0.0), 0.92)
        self.backgroundBlurRadius = min(max(backgroundBlurRadius, 0.0), 24.0)
        self.batteryColorStyle = batteryColorStyle
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.preset = try c.decodeIfPresent(ThemePreset.self, forKey: .preset) ?? .obsidianSlate
        self.customAccentHex = try c.decodeIfPresent(String.self, forKey: .customAccentHex)
        self.cornerRadius = try c.decodeIfPresent(Double.self, forKey: .cornerRadius) ?? VoltGuardiOSLimits.defaultCornerRadius
        self.surfaceOpacity = try c.decodeIfPresent(Double.self, forKey: .surfaceOpacity) ?? VoltGuardiOSLimits.defaultSurfaceOpacity
        self.useCustomBackground = try c.decodeIfPresent(Bool.self, forKey: .useCustomBackground) ?? false
        self.customBackgroundPath = try c.decodeIfPresent(String.self, forKey: .customBackgroundPath)
        self.backgroundScrimOpacity = try c.decodeIfPresent(Double.self, forKey: .backgroundScrimOpacity) ?? 0.68
        self.backgroundBlurRadius = try c.decodeIfPresent(Double.self, forKey: .backgroundBlurRadius) ?? 0.0
        self.batteryColorStyle = try c.decodeIfPresent(BatteryColorStyle.self, forKey: .batteryColorStyle) ?? .adaptiveSpectrum
    }
}

public enum iOSThermalLevel: String, Codable, Equatable, Sendable {
    case nominal
    case fair
    case serious
    case critical

    public var approximateCelsiusBadge: Double {
        switch self {
        case .nominal: return 28.0
        case .fair: return 34.0
        case .serious: return 39.0
        case .critical: return 44.0
        }
    }
}

public struct iOSBatteryTelemetry: Codable, Equatable, Sendable {
    public let percentage: Int
    public let isPluggedIn: Bool
    public let isCharging: Bool
    public let isLowPowerModeEnabled: Bool
    public let thermalLevel: iOSThermalLevel
    public let isBatterySensorLive: Bool
    public let timestamp: Date

    public init(
        percentage: Int,
        isPluggedIn: Bool,
        isCharging: Bool,
        isLowPowerModeEnabled: Bool,
        thermalLevel: iOSThermalLevel = .nominal,
        isBatterySensorLive: Bool = true,
        timestamp: Date = Date()
    ) {
        self.percentage = min(max(percentage, 0), 100)
        self.isPluggedIn = isPluggedIn
        self.isCharging = isCharging
        self.isLowPowerModeEnabled = isLowPowerModeEnabled
        self.thermalLevel = thermalLevel
        self.isBatterySensorLive = isBatterySensorLive
        self.timestamp = timestamp
    }
}

public enum ProfileTier: String, Codable, CaseIterable, Sendable {
    case balanced
    case mobility
    case longevity
}

public struct ChargeAlertPolicy: Codable, Equatable, Sendable {
    public var limitPercent: Int
    public var topUpActive: Bool
    public var thermalAlertEnabled: Bool
    public var lowBatteryAlertEnabled: Bool
    public var sailingReminderEnabled: Bool
    public var sailingDeltaPercent: Int

    public init(
        limitPercent: Int = VoltGuardiOSLimits.defaultLimitPercent,
        topUpActive: Bool = false,
        thermalAlertEnabled: Bool = true,
        lowBatteryAlertEnabled: Bool = true,
        sailingReminderEnabled: Bool = true,
        sailingDeltaPercent: Int = VoltGuardiOSLimits.defaultSailingDeltaPercent
    ) {
        self.limitPercent = min(max(limitPercent, VoltGuardiOSLimits.minLimitPercent), VoltGuardiOSLimits.maxLimitPercent)
        self.topUpActive = topUpActive
        self.thermalAlertEnabled = thermalAlertEnabled
        self.lowBatteryAlertEnabled = lowBatteryAlertEnabled
        self.sailingReminderEnabled = sailingReminderEnabled
        self.sailingDeltaPercent = min(max(sailingDeltaPercent, VoltGuardiOSLimits.minSailingDeltaPercent), VoltGuardiOSLimits.maxSailingDeltaPercent)
    }

    public var effectiveTargetPercent: Int {
        topUpActive ? VoltGuardiOSLimits.maxLimitPercent : limitPercent
    }
}

public enum ScheduleAction: String, Codable, CaseIterable, Sendable {
    case setLimit80
    case topUp100
}

public struct ScheduleRule: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var hour: Int
    public var minute: Int
    public var weekdays: Set<Int>
    public var action: ScheduleAction
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        hour: Int,
        minute: Int,
        weekdays: Set<Int> = [2, 3, 4, 5, 6],
        action: ScheduleAction = .setLimit80,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.title = title
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
        self.weekdays = weekdays
        self.action = action
        self.isEnabled = isEnabled
    }
}

public struct ActivityLogEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let messageKey: String

    public init(id: UUID = UUID(), timestamp: Date = Date(), messageKey: String) {
        self.id = id
        self.timestamp = timestamp
        self.messageKey = messageKey
    }
}

public struct FeatureCapabilityStatus: Codable, Equatable, Sendable {
    public let supported: Bool
    public let reasonCode: String

    public init(supported: Bool, reasonCode: String = "ok") {
        self.supported = supported
        self.reasonCode = reasonCode
    }
}

public struct iOSHardwareProfile: Codable, Equatable, Sendable {
    public let modelIdentifier: String
    public let iOSVersionString: String
    public let iOSMajorVersion: Int
    public let iOSMinorVersion: Int
    public let isSimulator: Bool
    public let supportsNative80LimitSetting: Bool

    public init(
        modelIdentifier: String,
        iOSVersionString: String,
        iOSMajorVersion: Int,
        iOSMinorVersion: Int = 0,
        isSimulator: Bool = false,
        supportsNative80LimitSetting: Bool
    ) {
        self.modelIdentifier = modelIdentifier
        self.iOSVersionString = iOSVersionString
        self.iOSMajorVersion = iOSMajorVersion
        self.iOSMinorVersion = iOSMinorVersion
        self.isSimulator = isSimulator
        self.supportsNative80LimitSetting = supportsNative80LimitSetting
    }

    public static func detectCurrent() -> iOSHardwareProfile {
        let simModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]
        let rawModel = simModel ?? readSysctlString("hw.machine") ?? "iPhone"
        let ver = ProcessInfo.processInfo.operatingSystemVersion
        let verStr = "\(ver.majorVersion).\(ver.minorVersion).\(ver.patchVersion)"
        return iOSHardwareProfile(
            modelIdentifier: rawModel,
            iOSVersionString: verStr,
            iOSMajorVersion: ver.majorVersion,
            iOSMinorVersion: ver.minorVersion,
            isSimulator: simModel != nil,
            supportsNative80LimitSetting: supportsNativeChargeLimit(
                modelIdentifier: rawModel,
                iOSMajor: ver.majorVersion,
                iOSMinor: ver.minorVersion
            )
        )
    }

    public static func supportsNativeChargeLimit(modelIdentifier: String, iOSMajor: Int, iOSMinor: Int = 5) -> Bool {
        let lower = modelIdentifier.lowercased()
        if lower.hasPrefix("iphone") {
            guard iOSMajor >= 17 else { return false }
            let parts = lower.replacingOccurrences(of: "iphone", with: "").split(separator: ",")
            guard let major = parts.first.flatMap({ Int($0) }),
                  let minor = parts.dropFirst().first.flatMap({ Int($0) }) else {
                return false
            }
            return major >= 16 || (major == 15 && minor >= 4)
        }
        if lower.hasPrefix("ipad") {
            guard iOSMajor > 17 || (iOSMajor == 17 && iOSMinor >= 5) else { return false }
            let parts = lower.replacingOccurrences(of: "ipad", with: "").split(separator: ",")
            guard let major = parts.first.flatMap({ Int($0) }),
                  let minor = parts.dropFirst().first.flatMap({ Int($0) }) else {
                return false
            }
            return major >= 15 || (major == 14 && minor >= 8)
        }
        if lower.contains("x86_64") || lower.contains("arm64") {
            return iOSMajor >= 17
        }
        return false
    }

    private static func readSysctlString(_ name: String) -> String? {
        var size: Int = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buf = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buf, &size, nil, 0) == 0 else { return nil }
        return String(cString: buf)
    }
}

public struct iOSDeviceCompatibilityReport: Codable, Equatable, Sendable {
    public let fingerprint: String
    public let hardwareProfile: iOSHardwareProfile
    public let liveTelemetry: FeatureCapabilityStatus
    public let smartChargeAlerts: FeatureCapabilityStatus
    public let thermalMonitor: FeatureCapabilityStatus
    public let native80HardwareLimit: FeatureCapabilityStatus
    public let kernelSMCAndDischarge: FeatureCapabilityStatus
    public let checkedAt: Date

    public init(
        fingerprint: String,
        hardwareProfile: iOSHardwareProfile,
        liveTelemetry: FeatureCapabilityStatus,
        smartChargeAlerts: FeatureCapabilityStatus,
        thermalMonitor: FeatureCapabilityStatus,
        native80HardwareLimit: FeatureCapabilityStatus,
        kernelSMCAndDischarge: FeatureCapabilityStatus,
        checkedAt: Date = Date()
    ) {
        self.fingerprint = fingerprint
        self.hardwareProfile = hardwareProfile
        self.liveTelemetry = liveTelemetry
        self.smartChargeAlerts = smartChargeAlerts
        self.thermalMonitor = thermalMonitor
        self.native80HardwareLimit = native80HardwareLimit
        self.kernelSMCAndDischarge = kernelSMCAndDischarge
        self.checkedAt = checkedAt
    }

    public static func makeFingerprint(profile: iOSHardwareProfile, notificationsAuthorized: Bool) -> String {
        "\(profile.modelIdentifier)|\(profile.iOSVersionString)|\(profile.supportsNative80LimitSetting)|notif=\(notificationsAuthorized)"
    }

    public static func evaluateOnce(
        profile: iOSHardwareProfile = .detectCurrent(),
        notificationsAuthorized: Bool,
        now: Date = Date()
    ) -> iOSDeviceCompatibilityReport {
        let fp = makeFingerprint(profile: profile, notificationsAuthorized: notificationsAuthorized)
        let alertStatus = notificationsAuthorized
            ? FeatureCapabilityStatus(supported: true)
            : FeatureCapabilityStatus(supported: false, reasonCode: "notifications_denied")
        let native80Status = profile.supportsNative80LimitSetting
            ? FeatureCapabilityStatus(supported: true)
            : FeatureCapabilityStatus(supported: false, reasonCode: "requires_iphone15_plus")
        let smcDenied = FeatureCapabilityStatus(supported: false, reasonCode: "ios_sandbox_restricted")

        return iOSDeviceCompatibilityReport(
            fingerprint: fp,
            hardwareProfile: profile,
            liveTelemetry: FeatureCapabilityStatus(supported: true),
            smartChargeAlerts: alertStatus,
            thermalMonitor: FeatureCapabilityStatus(supported: true),
            native80HardwareLimit: native80Status,
            kernelSMCAndDischarge: smcDenied,
            checkedAt: now
        )
    }
}

public struct iOSSettings: Codable, Equatable, Sendable {
    public var policy: ChargeAlertPolicy
    public var schedules: [ScheduleRule]
    public var theme: ThemeConfig
    public var locale: AppLocale
    public var alertsEnabled: Bool
    public var cachedCompatibility: iOSDeviceCompatibilityReport?

    public init(
        policy: ChargeAlertPolicy = ChargeAlertPolicy(),
        schedules: [ScheduleRule] = [],
        theme: ThemeConfig = ThemeConfig(),
        locale: AppLocale = .en,
        alertsEnabled: Bool = true,
        cachedCompatibility: iOSDeviceCompatibilityReport? = nil
    ) {
        self.policy = policy
        self.schedules = schedules
        self.theme = theme
        self.locale = locale
        self.alertsEnabled = alertsEnabled
        self.cachedCompatibility = cachedCompatibility
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.policy = try c.decodeIfPresent(ChargeAlertPolicy.self, forKey: .policy) ?? ChargeAlertPolicy()
        self.schedules = try c.decodeIfPresent([ScheduleRule].self, forKey: .schedules) ?? []
        self.theme = try c.decodeIfPresent(ThemeConfig.self, forKey: .theme) ?? ThemeConfig()
        self.locale = try c.decodeIfPresent(AppLocale.self, forKey: .locale) ?? .en
        self.alertsEnabled = try c.decodeIfPresent(Bool.self, forKey: .alertsEnabled) ?? true
        self.cachedCompatibility = try c.decodeIfPresent(iOSDeviceCompatibilityReport.self, forKey: .cachedCompatibility)
    }
}

public struct iOSReleaseChangelogEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let version: String
    public let date: String
    public let titleEN: String
    public let titleID: String
    public let highlightsEN: [String]
    public let highlightsID: [String]

    public init(
        version: String,
        date: String,
        titleEN: String,
        titleID: String,
        highlightsEN: [String],
        highlightsID: [String]
    ) {
        self.id = version
        self.version = version
        self.date = date
        self.titleEN = titleEN
        self.titleID = titleID
        self.highlightsEN = highlightsEN
        self.highlightsID = highlightsID
    }
}

public struct iOSUpdateCheckResult: Equatable, Sendable {
    public let currentVersion: String
    public let latestVersion: String
    public let latestBuild: String
    public let publishedAt: String
    public let isUpdateAvailable: Bool
    public let updatePageURL: String
    public let latestChangesEN: [String]
    public let latestFixesEN: [String]
    public let latestChangesID: [String]
    public let latestFixesID: [String]
    public let checkedAt: Date

    public init(
        currentVersion: String,
        latestVersion: String,
        latestBuild: String = iOSReleaseInfo.buildNumber,
        publishedAt: String = iOSReleaseInfo.latestPublishedDate,
        isUpdateAvailable: Bool,
        updatePageURL: String = iOSReleaseInfo.websiteURL,
        latestChangesEN: [String] = iOSReleaseInfo.latestChangesEN,
        latestFixesEN: [String] = iOSReleaseInfo.latestFixesEN,
        latestChangesID: [String] = iOSReleaseInfo.latestChangesID,
        latestFixesID: [String] = iOSReleaseInfo.latestFixesID,
        checkedAt: Date = Date()
    ) {
        self.currentVersion = currentVersion
        self.latestVersion = latestVersion
        self.latestBuild = latestBuild
        self.publishedAt = publishedAt
        self.isUpdateAvailable = isUpdateAvailable
        self.updatePageURL = updatePageURL
        self.latestChangesEN = latestChangesEN
        self.latestFixesEN = latestFixesEN
        self.latestChangesID = latestChangesID
        self.latestFixesID = latestFixesID
        self.checkedAt = checkedAt
    }
}

public enum iOSReleaseInfo {
    public static let currentVersion = "1.2.0"
    public static let buildNumber = "3"
    public static let latestPublishedDate = "2026-11-27"
    public static let websiteURL = "https://voltguard-mocha.vercel.app"
    public static let feedURL = "https://voltguard-mocha.vercel.app/appcast.json"

    public static let latestChangesEN: [String] = [
        "Interactive animated Thermal Zone card with inline Thermal Alert switch and cooling guidance",
        "Dedicated Software Updates tab displaying latest version changes and fixes"
    ]

    public static let latestFixesEN: [String] = [
        "Replaced deprecated SwiftUI onChange and Text.foregroundColor modifiers for iOS 17 - 26",
        "Improved feature parity alignment with VoltGuard Desktop v1.2.0"
    ]

    public static let latestChangesID: [String] = [
        "Kartu Thermal Zone interaktif beranimasi dengan toggle Thermal Alert langsung & panduan pendinginan",
        "Tab Pembaruan Aplikasi tersendiri berisi daftar perubahan & perbaikan versi terbaru"
    ]

    public static let latestFixesID: [String] = [
        "Upgrade modifier deprecated SwiftUI onChange dan Text.foregroundColor untuk iOS 17 - 26",
        "Penyelarasan fitur penuh dengan VoltGuard Desktop v1.2.0"
    ]

    public static let changelog: [iOSReleaseChangelogEntry] = [
        iOSReleaseChangelogEntry(
            version: "1.2.0",
            date: "2026-11-27",
            titleEN: "What's New & Fixes in v1.2.0",
            titleID: "Perubahan & Perbaikan Versi 1.2.0",
            highlightsEN: latestChangesEN + latestFixesEN,
            highlightsID: latestChangesID + latestFixesID
        )
    ]

    public static func isNewerVersion(_ candidate: String, than current: String) -> Bool {
        let parse: (String) -> [Int] = { raw in
            raw.trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
                .split(separator: ".")
                .compactMap { Int($0.filter(\.isNumber)) }
        }
        let a = parse(candidate)
        let b = parse(current)
        let count = max(a.count, b.count)
        for idx in 0..<count {
            let av = idx < a.count ? a[idx] : 0
            let bv = idx < b.count ? b[idx] : 0
            if av != bv { return av > bv }
        }
        return false
    }
}
