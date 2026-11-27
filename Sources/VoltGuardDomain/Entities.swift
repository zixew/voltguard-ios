import Foundation

public struct BatteryTelemetry: Codable, Equatable, Sendable {
    public let percentage: Int
    public let isCharging: Bool
    public let isPluggedIn: Bool
    public let temperatureCelsius: Double
    public let voltageVolts: Double
    public let amperageAmps: Double
    public let adapterWatts: Int
    public let cycleCount: Int
    public let currentCapacityMah: Int
    public let maxCapacityMah: Int
    public let designCapacityMah: Int
    public let timestamp: Date

    public init(
        percentage: Int,
        isCharging: Bool,
        isPluggedIn: Bool,
        temperatureCelsius: Double,
        voltageVolts: Double,
        amperageAmps: Double,
        adapterWatts: Int,
        cycleCount: Int,
        currentCapacityMah: Int,
        maxCapacityMah: Int,
        designCapacityMah: Int,
        timestamp: Date = Date()
    ) {
        self.percentage = max(0, min(100, percentage))
        self.isCharging = isCharging
        self.isPluggedIn = isPluggedIn
        self.temperatureCelsius = temperatureCelsius
        self.voltageVolts = voltageVolts
        self.amperageAmps = amperageAmps
        self.adapterWatts = adapterWatts
        self.cycleCount = cycleCount
        self.currentCapacityMah = currentCapacityMah
        self.maxCapacityMah = maxCapacityMah
        self.designCapacityMah = designCapacityMah
        self.timestamp = timestamp
    }

    public var healthPercent: Int {
        guard designCapacityMah > 0 else { return 100 }
        let raw = Double(maxCapacityMah) / Double(designCapacityMah) * 100.0
        return max(0, min(100, Int(raw.rounded())))
    }

    public var powerWatts: Double {
        abs(voltageVolts * amperageAmps)
    }
}

public struct ChargePolicy: Codable, Equatable, Sendable {
    public var limitPercent: Int
    public var sailingLowerBound: Int
    public var manualDischarge: Bool
    public var topUpActive: Bool
    public var heatProtectionEnabled: Bool
    public var heatThresholdCelsius: Double
    public var sleepInhibitCharging: Bool
    public var lowPowerModeOnBattery: Bool

    public init(
        limitPercent: Int = 80,
        sailingLowerBound: Int = 76,
        manualDischarge: Bool = false,
        topUpActive: Bool = false,
        heatProtectionEnabled: Bool = true,
        heatThresholdCelsius: Double = 35.0,
        sleepInhibitCharging: Bool = false,
        lowPowerModeOnBattery: Bool = false
    ) {
        self.limitPercent = limitPercent
        self.sailingLowerBound = sailingLowerBound
        self.manualDischarge = manualDischarge
        self.topUpActive = topUpActive
        self.heatProtectionEnabled = heatProtectionEnabled
        self.heatThresholdCelsius = heatThresholdCelsius
        self.sleepInhibitCharging = sleepInhibitCharging
        self.lowPowerModeOnBattery = lowPowerModeOnBattery
    }
}

public enum BatteryETAEstimationKind: String, Codable, Equatable, Sendable {
    case toLimit
    case toEmpty
    case full
    case calculating
}

public struct BatteryETA: Codable, Equatable, Sendable {
    public let minutes: Int
    public let kind: BatteryETAEstimationKind
    public let targetPercent: Int
    public let formatted: String

    public init(minutes: Int, kind: BatteryETAEstimationKind, targetPercent: Int, formatted: String) {
        self.minutes = max(0, minutes)
        self.kind = kind
        self.targetPercent = targetPercent
        self.formatted = formatted
    }
}

public struct MacHostDevice: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let host: String
    public let port: Int
    public let isConnected: Bool
    public let lastSeen: Date

    public init(id: String = UUID().uuidString, name: String, host: String, port: Int = 8998, isConnected: Bool = false, lastSeen: Date = Date()) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.isConnected = isConnected
        self.lastSeen = lastSeen
    }
}

public enum AppThemeID: String, Codable, CaseIterable, Sendable {
    case obsidianSlate
    case cyberLime
    case hyperNeon
    case crimsonForge
    case cleanFrost
}

public struct ThemeConfig: Codable, Equatable, Sendable {
    public var activeTheme: AppThemeID

    public init(activeTheme: AppThemeID = .obsidianSlate) {
        self.activeTheme = activeTheme
    }
}
