import Foundation

public struct BatteryETACalculator: Sendable {
    private var lastObservedMinutes: Int?
    private var lastComputedCadenceDate: Date?

    public init() {}

    public mutating func update(telemetry: BatteryTelemetry, targetLimit: Int = 80) -> BatteryETA {
        if telemetry.isCharging {
            if telemetry.percentage >= targetLimit {
                return BatteryETA(
                    minutes: 0,
                    kind: .full,
                    targetPercent: targetLimit,
                    formatted: "Limit Reached (\(targetLimit)%)"
                )
            }
            let deficitPct = max(0, targetLimit - telemetry.percentage)
            let rawMinutes = Int((Double(deficitPct) * 1.5).rounded())
            return BatteryETA(
                minutes: rawMinutes,
                kind: .toLimit,
                targetPercent: targetLimit,
                formatted: "\(rawMinutes)m until \(targetLimit)%"
            )
        } else {
            let pct = telemetry.percentage
            let rawMinutes = Int((Double(pct) * 3.0).rounded())
            return BatteryETA(
                minutes: rawMinutes,
                kind: .toEmpty,
                targetPercent: 0,
                formatted: "\(rawMinutes)m until empty"
            )
        }
    }
}
