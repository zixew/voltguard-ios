import XCTest
@testable import VoltGuardDomain
@testable import VoltGuardNetwork

final class VoltGuardiOSTests: XCTestCase {
    func testBatteryTelemetryCalculations() {
        let telemetry = BatteryTelemetry(
            percentage: 82,
            isCharging: true,
            isPluggedIn: true,
            temperatureCelsius: 32.5,
            voltageVolts: 12.0,
            amperageAmps: 1.5,
            adapterWatts: 70,
            cycleCount: 15,
            currentCapacityMah: 4100,
            maxCapacityMah: 4900,
            designCapacityMah: 5000
        )
        XCTAssertEqual(telemetry.percentage, 82)
        XCTAssertEqual(telemetry.healthPercent, 98)
        XCTAssertEqual(telemetry.powerWatts, 18.0)
    }

    func testBatteryETACalculatorToLimit() {
        var calc = BatteryETACalculator()
        let charging = BatteryTelemetry(
            percentage: 60,
            isCharging: true,
            isPluggedIn: true,
            temperatureCelsius: 30.0,
            voltageVolts: 12.0,
            amperageAmps: 1.0,
            adapterWatts: 60,
            cycleCount: 10,
            currentCapacityMah: 3000,
            maxCapacityMah: 5000,
            designCapacityMah: 5000
        )
        let eta = calc.update(telemetry: charging, targetLimit: 80)
        XCTAssertEqual(eta.kind, .toLimit)
        XCTAssertEqual(eta.targetPercent, 80)
        XCTAssertGreaterThan(eta.minutes, 0)
    }

    func testCompanionSyncSimulation() async throws {
        let service = SimulatedMacCompanionService()
        try await service.connect(host: "127.0.0.1", port: 8998)
        let telemetry = try await service.fetchTelemetry()
        XCTAssertEqual(telemetry.percentage, 80)

        try await service.updatePolicy(limitPercent: 90, manualDischarge: true)
        let updated = try await service.fetchTelemetry()
        XCTAssertEqual(updated.percentage, 76)
        XCTAssertFalse(updated.isCharging)
    }
}
