import XCTest
@testable import VoltGuardDomain
@testable import VoltGuardiOSCore

final class VoltGuardiOSTests: XCTestCase {
    func testBatteryETACalculatorToLimitSteadyAndEmpty() {
        var calc = BatteryETACalculator()
        let charging = iOSBatteryTelemetry(
            percentage: 60,
            isPluggedIn: true,
            isCharging: true,
            isLowPowerModeEnabled: false,
            thermalLevel: .nominal
        )
        let eta = calc.update(telemetry: charging, targetLimit: 80)
        XCTAssertEqual(eta.kind, .toTargetLimit)
        XCTAssertEqual(eta.targetPercent, 80)
        XCTAssertGreaterThan(eta.minutes ?? 0, 0)

        let atLimit = iOSBatteryTelemetry(
            percentage: 80,
            isPluggedIn: true,
            isCharging: false,
            isLowPowerModeEnabled: false,
            thermalLevel: .nominal
        )
        let steady = calc.update(telemetry: atLimit, targetLimit: 80)
        XCTAssertEqual(steady.kind, .steady)
        XCTAssertNil(steady.minutes)

        let unpluggedNormal = iOSBatteryTelemetry(
            percentage: 50,
            isPluggedIn: false,
            isCharging: false,
            isLowPowerModeEnabled: false,
            thermalLevel: .nominal
        )
        let normalEmpty = calc.update(telemetry: unpluggedNormal, targetLimit: 80)
        XCTAssertEqual(normalEmpty.kind, .toEmpty)

        let unpluggedLowPower = iOSBatteryTelemetry(
            percentage: 50,
            isPluggedIn: false,
            isCharging: false,
            isLowPowerModeEnabled: true,
            thermalLevel: .nominal
        )
        let lpmEmpty = calc.update(telemetry: unpluggedLowPower, targetLimit: 80)
        XCTAssertEqual(lpmEmpty.kind, .toEmpty)
        XCTAssertGreaterThan(lpmEmpty.minutes ?? 0, normalEmpty.minutes ?? 0)
    }

    func testAlliPhoneAndiPadHardwareCompatibilityMatrix() {
        // Legacy iPhone X (iOS 16), iPhone 12 mini, iPhone 14 Pro Max -> false for Apple 80% Limit
        XCTAssertFalse(iOSHardwareProfile.supportsNativeChargeLimit(modelIdentifier: "iPhone10,6", iOSMajor: 16, iOSMinor: 7))
        XCTAssertFalse(iOSHardwareProfile.supportsNativeChargeLimit(modelIdentifier: "iPhone13,1", iOSMajor: 18, iOSMinor: 0))
        XCTAssertFalse(iOSHardwareProfile.supportsNativeChargeLimit(modelIdentifier: "iPhone15,3", iOSMajor: 26, iOSMinor: 3))

        // iPhone 15 (15,4), 15 Pro Max (16,2), 16 (17,3), 17 (18,1) on iOS 17+ -> true
        XCTAssertTrue(iOSHardwareProfile.supportsNativeChargeLimit(modelIdentifier: "iPhone15,4", iOSMajor: 17, iOSMinor: 0))
        XCTAssertTrue(iOSHardwareProfile.supportsNativeChargeLimit(modelIdentifier: "iPhone16,2", iOSMajor: 17, iOSMinor: 0))
        XCTAssertTrue(iOSHardwareProfile.supportsNativeChargeLimit(modelIdentifier: "iPhone17,3", iOSMajor: 18, iOSMinor: 0))
        XCTAssertTrue(iOSHardwareProfile.supportsNativeChargeLimit(modelIdentifier: "iPhone18,1", iOSMajor: 26, iOSMinor: 3))

        // iPad Air M2 (14,8) requires iPadOS 17.5+
        XCTAssertFalse(iOSHardwareProfile.supportsNativeChargeLimit(modelIdentifier: "iPad14,8", iOSMajor: 17, iOSMinor: 4))
        XCTAssertTrue(iOSHardwareProfile.supportsNativeChargeLimit(modelIdentifier: "iPad14,8", iOSMajor: 17, iOSMinor: 5))
        XCTAssertTrue(iOSHardwareProfile.supportsNativeChargeLimit(modelIdentifier: "iPad16,3", iOSMajor: 18, iOSMinor: 0))
        XCTAssertTrue(iOSHardwareProfile.supportsNativeChargeLimit(modelIdentifier: "iPad16,1", iOSMajor: 18, iOSMinor: 0))

        // Older iPads -> false
        XCTAssertFalse(iOSHardwareProfile.supportsNativeChargeLimit(modelIdentifier: "iPad13,1", iOSMajor: 18, iOSMinor: 0))

        let live = iOSHardwareProfile.detectCurrent()
        XCTAssertFalse(live.modelIdentifier.isEmpty)
        XCTAssertGreaterThan(live.iOSMajorVersion, 0)
    }

    func testCompatibilityAuditRunsOnceAndCachesByFingerprint() throws {
        let oldProfile = iOSHardwareProfile(
            modelIdentifier: "iPhone13,1",
            iOSVersionString: "26.3.0",
            iOSMajorVersion: 26,
            iOSMinorVersion: 3,
            isSimulator: true,
            supportsNative80LimitSetting: false
        )
        let report = iOSDeviceCompatibilityReport.evaluateOnce(profile: oldProfile, notificationsAuthorized: false)
        XCTAssertFalse(report.native80HardwareLimit.supported)
        XCTAssertEqual(report.native80HardwareLimit.reasonCode, "requires_iphone15_plus")
        XCTAssertFalse(report.smartChargeAlerts.supported)
        XCTAssertEqual(report.smartChargeAlerts.reasonCode, "notifications_denied")
        XCTAssertFalse(report.kernelSMCAndDischarge.supported)

        var settings = iOSSettings()
        settings.cachedCompatibility = report
        settings.theme.preset = .nordicMist
        settings.theme.batteryColorStyle = .thermalReactive

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(iOSSettings.self, from: data)
        XCTAssertEqual(decoded.cachedCompatibility?.fingerprint, report.fingerprint)
        XCTAssertEqual(decoded.theme.preset, .nordicMist)
        XCTAssertEqual(decoded.theme.batteryColorStyle, .thermalReactive)
    }

    func testDesktopThemePaletteParityAndClamping() {
        for preset in ThemePreset.allCases {
            let palette = ThemePalette.resolve(ThemeConfig(preset: preset))
            XCTAssertFalse(palette.backgroundHex.isEmpty)
            XCTAssertFalse(palette.accentHex.isEmpty)
        }
        let custom = ThemePalette.resolve(ThemeConfig(preset: .obsidianSlate, customAccentHex: "#0EA5E9", cornerRadius: 99, surfaceOpacity: 0.1))
        XCTAssertEqual(custom.accentHex, "#0EA5E9")
        XCTAssertEqual(custom.cornerRadius, VoltGuardiOSLimits.maxCornerRadius)
        XCTAssertEqual(custom.surfaceOpacity, VoltGuardiOSLimits.minSurfaceOpacity)

        let invalid = ThemePalette.resolve(ThemeConfig(preset: .paperLight, customAccentHex: "bad"))
        XCTAssertEqual(invalid.accentHex, ThemeHexConstants.paperLight.accent)
    }

    func testLocalizationCompletenessFormatterAndNoEmDash() {
        for key in L10nKey.allCases {
            let enText = L10n.en[key]
            let idText = L10n.id[key]
            XCTAssertNotNil(enText, "Missing EN localization for \(key.rawValue)")
            XCTAssertNotNil(idText, "Missing ID localization for \(key.rawValue)")
            XCTAssertFalse(enText?.contains("\u{2014}") ?? false, "Unexpected em dash in EN for \(key.rawValue)")
            XCTAssertFalse(idText?.contains("\u{2014}") ?? false, "Unexpected em dash in ID for \(key.rawValue)")
        }

        let steady = BatteryETA(kind: .steady, minutes: nil, targetPercent: 80)
        XCTAssertEqual(BatteryETAFormatter.text(for: steady, locale: .en), "Target 80% reached")
        XCTAssertEqual(BatteryETAFormatter.text(for: steady, locale: .id), "Target 80% tercapai")
    }

    @MainActor
    func testStoreSchedulesProfilesBackupAndCacheStability() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("voltguard-ios-test-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fileURL = dir.appendingPathComponent("ios_settings.json")

        let store = VoltGuardiOSStore(settingsURL: fileURL)
        let firstCheckDate = store.settings.cachedCompatibility?.checkedAt
        XCTAssertNotNil(firstCheckDate)

        // Calling refreshCompatibilityOnce(force: false) with same fingerprint preserves cached checkedAt
        store.refreshCompatibilityOnce(force: false)
        XCTAssertEqual(store.settings.cachedCompatibility?.checkedAt, firstCheckDate)

        // Bounds clamping & Top Up behavior
        store.setTargetLimit(10)
        XCTAssertEqual(store.settings.policy.limitPercent, VoltGuardiOSLimits.minLimitPercent)
        store.setTargetLimit(120)
        XCTAssertEqual(store.settings.policy.limitPercent, VoltGuardiOSLimits.maxLimitPercent)

        store.applyProfile(.longevity)
        XCTAssertEqual(store.settings.policy.limitPercent, 70)
        store.toggleTopUp()
        XCTAssertTrue(store.settings.policy.topUpActive)
        XCTAssertEqual(store.settings.policy.effectiveTargetPercent, 100)

        // Schedules CRUD
        store.addSchedule(title: "Morning", hour: 7, minute: 30, action: .topUp100)
        XCTAssertEqual(store.settings.schedules.count, 1)
        let ruleID = store.settings.schedules[0].id
        store.toggleSchedule(id: ruleID)
        XCTAssertFalse(store.settings.schedules[0].isEnabled)
        store.removeSchedule(id: ruleID)
        XCTAssertTrue(store.settings.schedules.isEmpty)

        // Backup JSON & Reset preserving locale
        store.setLocale(.id)
        let json = store.exportSettingsJSON()
        XCTAssertTrue(store.importSettingsJSON(json))
        XCTAssertFalse(store.importSettingsJSON("not json"))
        store.resetSettings()
        XCTAssertEqual(store.settings.locale, .id)
        XCTAssertEqual(store.settings.policy.limitPercent, VoltGuardiOSLimits.defaultLimitPercent)
    }

    func testVersionComparisonAndChangelogMetadata() {
        XCTAssertTrue(iOSReleaseInfo.isNewerVersion("1.3.0", than: "1.2.0"))
        XCTAssertTrue(iOSReleaseInfo.isNewerVersion("v1.2.1", than: "1.2.0"))
        XCTAssertFalse(iOSReleaseInfo.isNewerVersion("1.2.0", than: "1.2.0"))
        XCTAssertFalse(iOSReleaseInfo.isNewerVersion("1.1.0", than: "1.2.0"))
        XCTAssertEqual(iOSReleaseInfo.currentVersion, "1.2.0")
        XCTAssertFalse(iOSReleaseInfo.changelog.isEmpty)
        for entry in iOSReleaseInfo.changelog {
            XCTAssertFalse(entry.titleEN.contains("\u{2014}"))
            XCTAssertFalse(entry.titleID.contains("\u{2014}"))
        }
    }
}
