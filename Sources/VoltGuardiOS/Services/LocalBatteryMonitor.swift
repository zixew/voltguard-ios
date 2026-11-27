import Foundation
import SwiftUI
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif
import VoltGuardDomain

@MainActor
public final class VoltGuardiOSStore: ObservableObject {
    @Published public private(set) var telemetry: iOSBatteryTelemetry
    @Published public private(set) var batteryETA: BatteryETA
    @Published public var settings: iOSSettings
    @Published public private(set) var activityLog: [ActivityLogEntry] = []
    @Published public private(set) var notificationsAuthorized: Bool = true
    @Published public var feedbackMessage: String?
    @Published public private(set) var updateResult: iOSUpdateCheckResult?
    @Published public private(set) var isCheckingUpdates: Bool = false

    private var etaCalculator = BatteryETACalculator()
    private var lastAlertDates: [String: Date] = [:]
    private var hasNotifiedLimitThisCycle: Bool = false
    private let settingsURL: URL

    public init(settingsURL: URL? = nil) {
        let resolvedURL: URL
        if let settingsURL {
            resolvedURL = settingsURL
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            resolvedURL = base.appendingPathComponent("VoltGuard", isDirectory: true).appendingPathComponent("ios_settings.json")
        }
        self.settingsURL = resolvedURL

        let loadedSettings = Self.loadSettings(from: resolvedURL)
        self.settings = loadedSettings

        let initialTelemetry = Self.readCurrentTelemetry()
        self.telemetry = initialTelemetry
        self.batteryETA = etaCalculator.update(telemetry: initialTelemetry, targetLimit: loadedSettings.policy.effectiveTargetPercent)

        setupObservers()
        refreshCompatibilityOnce(force: false)
        Task {
            await refreshNotificationAuthorization()
        }
    }

    public var palette: ThemePalette {
        ThemePalette.resolve(settings.theme)
    }

    public var effectiveCompatibility: iOSDeviceCompatibilityReport {
        if let cached = settings.cachedCompatibility {
            return cached
        }
        return iOSDeviceCompatibilityReport.evaluateOnce(notificationsAuthorized: notificationsAuthorized)
    }

    public func refreshTelemetry() {
        let current = Self.readCurrentTelemetry()
        self.telemetry = current

        if settings.policy.topUpActive && current.percentage >= 100 {
            settings.policy.topUpActive = false
            saveSettings()
        }

        self.batteryETA = etaCalculator.update(
            telemetry: current,
            targetLimit: settings.policy.effectiveTargetPercent
        )
        evaluateAlertsIfNeeded(telemetry: current)
    }

    public func refreshCompatibilityOnce(force: Bool) {
        let profile = iOSHardwareProfile.detectCurrent()
        let fp = iOSDeviceCompatibilityReport.makeFingerprint(
            profile: profile,
            notificationsAuthorized: notificationsAuthorized
        )
        if !force, let existing = settings.cachedCompatibility, existing.fingerprint == fp {
            return
        }
        settings.cachedCompatibility = iOSDeviceCompatibilityReport.evaluateOnce(
            profile: profile,
            notificationsAuthorized: notificationsAuthorized
        )
        saveSettings()
    }

    public func applyProfile(_ tier: ProfileTier) {
        switch tier {
        case .balanced:
            settings.policy.limitPercent = 80
            settings.policy.topUpActive = false
            settings.policy.thermalAlertEnabled = true
        case .mobility:
            settings.policy.limitPercent = 100
            settings.policy.topUpActive = false
            settings.policy.thermalAlertEnabled = true
        case .longevity:
            settings.policy.limitPercent = 70
            settings.policy.topUpActive = false
            settings.policy.thermalAlertEnabled = true
        }
        hasNotifiedLimitThisCycle = false
        recordActivity("activityProfileApplied")
        saveAndRefresh()
    }

    public func setTargetLimit(_ newLimit: Int) {
        let clamped = min(max(newLimit, VoltGuardiOSLimits.minLimitPercent), VoltGuardiOSLimits.maxLimitPercent)
        settings.policy.limitPercent = clamped
        settings.policy.topUpActive = false
        hasNotifiedLimitThisCycle = false
        saveAndRefresh()
    }

    public func toggleTopUp() {
        settings.policy.topUpActive.toggle()
        hasNotifiedLimitThisCycle = false
        saveAndRefresh()
    }

    public func toggleThermalAlert() {
        settings.policy.thermalAlertEnabled.toggle()
        saveSettings()
    }

    public func toggleLowBatteryAlert() {
        settings.policy.lowBatteryAlertEnabled.toggle()
        saveSettings()
    }

    public func toggleSailingReminder() {
        settings.policy.sailingReminderEnabled.toggle()
        saveSettings()
    }

    public func toggleSmartNotifications() {
        settings.alertsEnabled.toggle()
        saveSettings()
        if settings.alertsEnabled {
            requestNotificationPermission()
        }
    }

    public func setLocale(_ locale: AppLocale) {
        settings.locale = locale
        saveSettings()
    }

    public func updateTheme(_ theme: ThemeConfig) {
        settings.theme = theme
        saveSettings()
    }

    public func addSchedule(title: String, hour: Int, minute: Int, action: ScheduleAction) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let rule = ScheduleRule(
            title: trimmed.isEmpty ? L10n.text(action == .topUp100 ? .scheduleTopUp100 : .scheduleSetLimit80, locale: settings.locale) : trimmed,
            hour: hour,
            minute: minute,
            action: action
        )
        settings.schedules.append(rule)
        saveSettings()
        syncScheduledNotifications()
    }

    public func toggleSchedule(id: UUID) {
        guard let idx = settings.schedules.firstIndex(where: { $0.id == id }) else { return }
        settings.schedules[idx].isEnabled.toggle()
        saveSettings()
        syncScheduledNotifications()
    }

    public func removeSchedule(id: UUID) {
        settings.schedules.removeAll { $0.id == id }
        saveSettings()
        syncScheduledNotifications()
    }

    public func syncScheduledNotifications() {
        #if os(iOS)
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { [settings] requests in
            let oldIDs = requests.map(\.identifier).filter { $0.hasPrefix("voltguard.schedule.") }
            center.removePendingNotificationRequests(withIdentifiers: oldIDs)
            guard settings.alertsEnabled else { return }
            let locale = settings.locale
            for rule in settings.schedules where rule.isEnabled {
                for day in rule.weekdays {
                    var dc = DateComponents()
                    dc.weekday = day
                    dc.hour = rule.hour
                    dc.minute = rule.minute
                    let content = UNMutableNotificationContent()
                    content.title = rule.title
                    content.body = L10n.text(rule.action == .topUp100 ? .scheduleTopUp100 : .scheduleSetLimit80, locale: locale)
                    content.sound = .default
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                    let req = UNNotificationRequest(identifier: "voltguard.schedule.\(rule.id.uuidString).\(day)", content: content, trigger: trigger)
                    center.add(req)
                }
            }
        }
        #endif
    }

    public func exportSettingsJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(settings),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    public func importSettingsJSON(_ json: String) -> Bool {
        guard let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(iOSSettings.self, from: data) else {
            return false
        }
        settings = decoded
        saveAndRefresh()
        return true
    }

    public func resetSettings() {
        let currentLocale = settings.locale
        var fresh = iOSSettings()
        fresh.locale = currentLocale
        settings = fresh
        refreshCompatibilityOnce(force: true)
        saveAndRefresh()
    }

    public func saveWallpaperImageData(_ data: Data) {
        let dir = settingsURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let pathURL = dir.appendingPathComponent("custom_wallpaper.jpg")
        if (try? data.write(to: pathURL)) != nil {
            settings.theme.useCustomBackground = true
            settings.theme.customBackgroundPath = pathURL.path
            saveSettings()
        }
    }

    public func clearWallpaperImage() {
        settings.theme.useCustomBackground = false
        settings.theme.customBackgroundPath = nil
        saveSettings()
    }

    public func requestNotificationPermission() {
        #if os(iOS)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            Task { @MainActor [weak self] in
                self?.notificationsAuthorized = granted
                self?.refreshCompatibilityOnce(force: true)
            }
        }
        #endif
    }

    public func sendTestNotification() {
        let locale = settings.locale
        dispatchLocalNotification(
            id: "voltguard.test",
            title: L10n.text(.alertTestTitle, locale: locale),
            body: L10n.text(.alertTestBody, locale: locale),
            bypassCooldown: true
        )
    }

    private func refreshNotificationAuthorization() async {
        #if os(iOS)
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let granted = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional || settings.authorizationStatus == .notDetermined
        self.notificationsAuthorized = granted
        refreshCompatibilityOnce(force: false)
        #endif
    }

    private func evaluateAlertsIfNeeded(telemetry: iOSBatteryTelemetry) {
        guard settings.alertsEnabled else { return }
        let locale = settings.locale
        let target = settings.policy.effectiveTargetPercent
        let resetFloor = settings.policy.sailingReminderEnabled
            ? max(target - settings.policy.sailingDeltaPercent, 10)
            : max(target - 2, 10)

        if telemetry.percentage <= resetFloor || !telemetry.isPluggedIn {
            hasNotifiedLimitThisCycle = false
        }

        if telemetry.isPluggedIn && telemetry.percentage >= target && !hasNotifiedLimitThisCycle {
            hasNotifiedLimitThisCycle = true
            recordActivity("activityLimitAlertSent")
            dispatchLocalNotification(
                id: "voltguard.limit",
                title: L10n.text(.alertTargetTitle, locale: locale),
                body: String(format: L10n.text(.alertTargetBody, locale: locale), target),
                bypassCooldown: false
            )
        }

        if settings.policy.thermalAlertEnabled && (telemetry.thermalLevel == .serious || telemetry.thermalLevel == .critical) {
            recordActivity("activityThermalAlertSent")
            dispatchLocalNotification(
                id: "voltguard.thermal",
                title: L10n.text(.alertThermalTitle, locale: locale),
                body: L10n.text(.alertThermalBody, locale: locale),
                bypassCooldown: false
            )
        }

        if settings.policy.lowBatteryAlertEnabled && !telemetry.isPluggedIn && telemetry.percentage <= VoltGuardiOSLimits.lowBatteryAlertThresholdPercent {
            recordActivity("activityLowBatteryAlertSent")
            dispatchLocalNotification(
                id: "voltguard.low",
                title: L10n.text(.alertLowBatteryTitle, locale: locale),
                body: String(format: L10n.text(.alertLowBatteryBody, locale: locale), telemetry.percentage),
                bypassCooldown: false
            )
        }
    }

    private func dispatchLocalNotification(id: String, title: String, body: String, bypassCooldown: Bool) {
        let now = Date()
        if !bypassCooldown, let last = lastAlertDates[id], now.timeIntervalSince(last) < VoltGuardiOSLimits.alertCooldownSeconds {
            return
        }
        lastAlertDates[id] = now

        #if os(iOS)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
        #endif
    }

    private func recordActivity(_ key: String) {
        activityLog.insert(ActivityLogEntry(messageKey: key), at: 0)
        if activityLog.count > 40 {
            activityLog.removeLast(activityLog.count - 40)
        }
    }

    private func saveAndRefresh() {
        saveSettings()
        refreshTelemetry()
    }

    private func saveSettings() {
        let dir = settingsURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(settings) {
            try? data.write(to: settingsURL, options: .atomic)
        }
    }

    private static func loadSettings(from url: URL) -> iOSSettings {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(iOSSettings.self, from: data) else {
            return iOSSettings()
        }
        return decoded
    }

    private func setupObservers() {
        #if canImport(UIKit)
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(forName: UIDevice.batteryLevelDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshTelemetry() }
        }
        NotificationCenter.default.addObserver(forName: UIDevice.batteryStateDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshTelemetry() }
        }
        #endif
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSProcessInfoPowerStateDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshTelemetry() }
        }
        NotificationCenter.default.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshTelemetry() }
        }
    }

    private static func readCurrentTelemetry() -> iOSBatteryTelemetry {
        let thermal = mapThermalState(ProcessInfo.processInfo.thermalState)
        let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        #if canImport(UIKit)
        let rawLevel = UIDevice.current.batteryLevel
        let state = UIDevice.current.batteryState
        let sensorLive = (rawLevel >= 0 && state != .unknown)
        let pct = rawLevel >= 0 ? Int((rawLevel * 100.0).rounded()) : 82
        let plugged = sensorLive ? (state == .charging || state == .full) : false
        let charging = sensorLive ? (state == .charging) : false
        return iOSBatteryTelemetry(
            percentage: pct,
            isPluggedIn: plugged,
            isCharging: charging,
            isLowPowerModeEnabled: lowPower,
            thermalLevel: thermal,
            isBatterySensorLive: sensorLive
        )
        #else
        return iOSBatteryTelemetry(
            percentage: 82,
            isPluggedIn: true,
            isCharging: false,
            isLowPowerModeEnabled: lowPower,
            thermalLevel: thermal,
            isBatterySensorLive: false
        )
        #endif
    }

    private static func mapThermalState(_ state: ProcessInfo.ThermalState) -> iOSThermalLevel {
        switch state {
        case .nominal: return .nominal
        case .fair: return .fair
        case .serious: return .serious
        case .critical: return .critical
        @unknown default: return .nominal
        }
    }

    public func checkForUpdates() {
        guard !isCheckingUpdates else { return }
        isCheckingUpdates = true
        feedbackMessage = nil

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.isCheckingUpdates = false }
            let fetched = await Self.fetchLatestGitHubRelease()
            self.updateResult = fetched
        }
    }

    private nonisolated static func fetchLatestGitHubRelease() async -> iOSUpdateCheckResult {
        guard let url = URL(string: iOSReleaseInfo.latestReleaseAPI) else {
            return iOSUpdateCheckResult(
                currentVersion: iOSReleaseInfo.currentVersion,
                latestVersion: iOSReleaseInfo.currentVersion,
                isUpdateAvailable: false,
                releaseURL: iOSReleaseInfo.releasesWebURL,
                releaseNotes: ""
            )
        }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("VoltGuard-iOS/\(iOSReleaseInfo.currentVersion)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String else {
                return iOSUpdateCheckResult(
                    currentVersion: iOSReleaseInfo.currentVersion,
                    latestVersion: iOSReleaseInfo.currentVersion,
                    isUpdateAvailable: false,
                    releaseURL: iOSReleaseInfo.releasesWebURL,
                    releaseNotes: ""
                )
            }
            let latest = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            let htmlURL = (json["html_url"] as? String) ?? iOSReleaseInfo.releasesWebURL
            let body = (json["body"] as? String) ?? ""
            return iOSUpdateCheckResult(
                currentVersion: iOSReleaseInfo.currentVersion,
                latestVersion: latest,
                isUpdateAvailable: iOSReleaseInfo.isNewerVersion(latest, than: iOSReleaseInfo.currentVersion),
                releaseURL: htmlURL,
                releaseNotes: body
            )
        } catch {
            return iOSUpdateCheckResult(
                currentVersion: iOSReleaseInfo.currentVersion,
                latestVersion: iOSReleaseInfo.currentVersion,
                isUpdateAvailable: false,
                releaseURL: iOSReleaseInfo.releasesWebURL,
                releaseNotes: ""
            )
        }
    }
}
