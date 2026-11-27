import Foundation
import VoltGuardDomain

public protocol MacCompanionSyncService: Sendable {
    func connect(host: String, port: Int) async throws
    func disconnect() async
    func fetchTelemetry() async throws -> BatteryTelemetry
    func updatePolicy(limitPercent: Int, manualDischarge: Bool) async throws
}

public actor SimulatedMacCompanionService: MacCompanionSyncService {
    private var connected = false
    private var currentLimit = 80
    private var isDischarging = false

    public init() {}

    public func connect(host: String, port: Int) async throws {
        try? await Task.sleep(nanoseconds: 120_000_000)
        connected = true
    }

    public func disconnect() async {
        connected = false
    }

    public func fetchTelemetry() async throws -> BatteryTelemetry {
        return BatteryTelemetry(
            percentage: isDischarging ? 76 : 80,
            isCharging: !isDischarging,
            isPluggedIn: true,
            temperatureCelsius: 31.4,
            voltageVolts: 12.3,
            amperageAmps: isDischarging ? -1.2 : 0.8,
            adapterWatts: 70,
            cycleCount: 42,
            currentCapacityMah: 4420,
            maxCapacityMah: 5400,
            designCapacityMah: 5500
        )
    }

    public func updatePolicy(limitPercent: Int, manualDischarge: Bool) async throws {
        self.currentLimit = limitPercent
        self.isDischarging = manualDischarge
    }
}
