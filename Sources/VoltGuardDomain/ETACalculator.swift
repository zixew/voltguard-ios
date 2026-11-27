import Foundation

public enum ETAKind: String, Codable, Equatable, Sendable {
    case toTargetLimit
    case toEmpty
    case steady
}

public struct BatteryETA: Codable, Equatable, Sendable {
    public let kind: ETAKind
    public let minutes: Int?
    public let targetPercent: Int

    public init(kind: ETAKind, minutes: Int?, targetPercent: Int) {
        self.kind = kind
        self.minutes = minutes
        self.targetPercent = targetPercent
    }
}

public struct BatteryETACalculator: Sendable {
    private var lastSampleLevel: Int?
    private var lastSampleDate: Date?
    private var measuredMinutesPerPercent: Double?

    public init() {}

    public mutating func update(telemetry: iOSBatteryTelemetry, targetLimit: Int) -> BatteryETA {
        let now = telemetry.timestamp

        if let prevLevel = lastSampleLevel, let prevDate = lastSampleDate {
            let deltaPct = abs(telemetry.percentage - prevLevel)
            let dtMinutes = now.timeIntervalSince(prevDate) / 60.0
            if deltaPct >= 1 && dtMinutes >= 0.25 && dtMinutes <= 60.0 {
                let sampleRate = dtMinutes / Double(deltaPct)
                if let prevRate = measuredMinutesPerPercent {
                    measuredMinutesPerPercent = (prevRate * 0.65) + (sampleRate * 0.35)
                } else {
                    measuredMinutesPerPercent = sampleRate
                }
                lastSampleLevel = telemetry.percentage
                lastSampleDate = now
            }
        } else {
            lastSampleLevel = telemetry.percentage
            lastSampleDate = now
        }

        if telemetry.isPluggedIn {
            if telemetry.percentage >= targetLimit && targetLimit < 100 {
                return BatteryETA(kind: .steady, minutes: nil, targetPercent: targetLimit)
            }
            if !telemetry.isCharging && telemetry.percentage >= targetLimit {
                return BatteryETA(kind: .steady, minutes: nil, targetPercent: targetLimit)
            }
            let remainingPct = max(targetLimit - telemetry.percentage, 0)
            guard remainingPct > 0 else {
                return BatteryETA(kind: .steady, minutes: nil, targetPercent: targetLimit)
            }
            let minPerPct = measuredMinutesPerPercent ?? (telemetry.percentage >= 80 ? 2.2 : 1.1)
            let totalMinutes = max(Int((Double(remainingPct) * minPerPct).rounded()), 1)
            return BatteryETA(kind: .toTargetLimit, minutes: totalMinutes, targetPercent: targetLimit)
        } else {
            let rate = measuredMinutesPerPercent ?? (telemetry.isLowPowerModeEnabled ? 6.5 : 4.5)
            let totalMinutes = max(Int((Double(max(telemetry.percentage, 1)) * rate).rounded()), 1)
            return BatteryETA(kind: .toEmpty, minutes: totalMinutes, targetPercent: 0)
        }
    }
}
