import Foundation
import VoltGuardDomain

public enum L10nKey: String, CaseIterable, Sendable {
    case appTitle
    case tabOverview
    case tabAlerts
    case tabSchedule
    case tabAppearance
    case tabSystem
    case statusCharging
    case statusLimitReached
    case statusTopUp
    case statusOnBattery
    case statusThermalWarning
    case chargeTargetTitle
    case targetLimitLabel
    case topUp100
    case topUpDesc
    case thermalAlert
    case thermalAlertDesc
    case lowBatteryAlert
    case lowBatteryAlertDesc
    case sailingReminder
    case sailingReminderDesc
    case thermalStateLabel
    case thermalNominal
    case thermalFair
    case thermalSerious
    case thermalCritical
    case batteryStateLabel
    case statePluggedCharging
    case statePluggedFull
    case stateOnBattery
    case lowPowerModeLabel
    case lowPowerOn
    case lowPowerOff
    case recommendedProfilesTitle
    case profileBalancedTitle
    case profileBalancedDesc
    case profileMobilityTitle
    case profileMobilityDesc
    case profileLongevityTitle
    case profileLongevityDesc
    case applyProfile
    case appliedProfile
    case nativeLimitGuideTitle
    case nativeLimitGuideBody15Plus
    case nativeLimitGuideBodyOlder
    case openSettingsButton
    case testAlertButton
    case smartAlertsTitle
    case smartAlertsToggle
    case smartAlertsDesc
    case scheduleTitle
    case scheduleNamePlaceholder
    case addScheduleButton
    case noSchedulesHint
    case scheduleSetLimit80
    case scheduleTopUp100
    case activityLogTitle
    case activityLogEmpty
    case activityLimitAlertSent
    case activityThermalAlertSent
    case activityLowBatteryAlertSent
    case activityProfileApplied
    case themePresetTitle
    case presetObsidianSlate
    case presetPaperLight
    case presetNordicMist
    case presetMidnightAmber
    case customAccentTitle
    case batteryColorStyleTitle
    case batteryColorSpectrum
    case batteryColorThermal
    case batteryColorAccent
    case cornerRadiusLabel
    case surfaceOpacityLabel
    case wallpaperTitle
    case wallpaperSolid
    case wallpaperPhoto
    case wallpaperChoosePhoto
    case wallpaperRemovePhoto
    case wallpaperScrimLabel
    case wallpaperBlurLabel
    case compatCardTitle
    case compatCachedBadge
    case compatRecheckButton
    case compatModelLabel
    case compatOSLabel
    case compatFeatureTelemetry
    case compatFeatureAlerts
    case compatFeatureThermal
    case compatFeatureNative80
    case compatFeatureSMC
    case compatStatusSupported
    case compatReasonNotifDenied
    case compatReasonOlderIPhone
    case compatReasonSandboxSMC
    case settingsBackupTitle
    case exportSettings
    case importSettings
    case resetSettings
    case settingsCopied
    case settingsResetDone
    case settingsImportInvalid
    case architectureNoteTitle
    case architectureNoteBody
    case alertTargetTitle
    case alertTargetBody
    case alertThermalTitle
    case alertThermalBody
    case alertLowBatteryTitle
    case alertLowBatteryBody
    case alertTestTitle
    case alertTestBody
    case etaHoldingAt
    case etaToTarget
    case etaToEmpty
    case thermalTapHint
    case thermalSafeAdvice
    case thermalWarnAdvice
    case thermalCoolAdvice
    case tabUpdates
    case appUpdatesTitle
    case checkUpdatesButton
    case checkingUpdates
    case updateAvailableBanner
    case upToDateBanner
    case updatesWhatsNewSection
    case updatesFixesSection
    case updatesCleanHint
    case openDownloadPage
}

public struct L10n {
    public static func text(_ key: L10nKey, locale: AppLocale) -> String {
        switch locale {
        case .en: return en[key] ?? key.rawValue
        case .id: return id[key] ?? key.rawValue
        }
    }

    public static let en: [L10nKey: String] = [
        .appTitle: "VoltGuard",
        .tabOverview: "Overview",
        .tabAlerts: "Alerts & Limits",
        .tabSchedule: "Schedule",
        .tabAppearance: "Appearance",
        .tabSystem: "System",
        .statusCharging: "Charging",
        .statusLimitReached: "Target Limit Reached",
        .statusTopUp: "Top Up 100% Active",
        .statusOnBattery: "On Battery",
        .statusThermalWarning: "High Thermal State",
        .chargeTargetTitle: "Charge Alert Limit",
        .targetLimitLabel: "Target Limit",
        .topUp100: "Top Up 100%",
        .topUpDesc: "Temporarily raise charge alert target to 100% before travel, then auto-restore.",
        .thermalAlert: "Thermal Guard Alert",
        .thermalAlertDesc: "Warn with notification when iPhone thermal state hits Serious or Critical.",
        .lowBatteryAlert: "Low Battery 20% Alert",
        .lowBatteryAlertDesc: "Alert when battery drops to 20% or below while unplugged.",
        .sailingReminder: "Sailing Re-plug Band",
        .sailingReminderDesc: "Give a cooldown buffer below limit before reminding again.",
        .thermalStateLabel: "Thermal State",
        .thermalNominal: "Nominal",
        .thermalFair: "Warm (Fair)",
        .thermalSerious: "Serious",
        .thermalCritical: "Critical",
        .batteryStateLabel: "Power State",
        .statePluggedCharging: "Charging",
        .statePluggedFull: "Full / Plugged",
        .stateOnBattery: "Battery",
        .lowPowerModeLabel: "Low Power",
        .lowPowerOn: "Enabled",
        .lowPowerOff: "Off",
        .recommendedProfilesTitle: "Recommended Profiles",
        .profileBalancedTitle: "Balanced",
        .profileBalancedDesc: "80% daily reminder target with thermal alerts active.",
        .profileMobilityTitle: "Travel / Mobility",
        .profileMobilityDesc: "100% full target before trips or heavy outdoor navigation.",
        .profileLongevityTitle: "Max Lifespan",
        .profileLongevityDesc: "60%-75% conservative target to minimize cell wear.",
        .applyProfile: "Apply",
        .appliedProfile: "Active",
        .nativeLimitGuideTitle: "Apple Hardware Charge Limit",
        .nativeLimitGuideBody15Plus: "iPhone 15 and newer support hardware 80% Charge Limit directly in iOS Settings -> Battery -> Charging. Use VoltGuard alerts for custom 60%/90% targets and thermal warnings.",
        .nativeLimitGuideBodyOlder: "Older iPhones support Optimized Battery Charging in iOS Settings. iOS apps cannot cut charging power directly at the kernel level, so VoltGuard provides real-time alarms at your target.",
        .openSettingsButton: "Open iOS Settings",
        .testAlertButton: "Send Test Alert",
        .smartAlertsTitle: "Charge & Thermal Alerts",
        .smartAlertsToggle: "Smart Notifications",
        .smartAlertsDesc: "Allow VoltGuard to notify you when charge target, 20% low level, or high heat occurs.",
        .scheduleTitle: "Daily Alert Schedules",
        .scheduleNamePlaceholder: "Rule name",
        .addScheduleButton: "Add Rule",
        .noSchedulesHint: "No schedule rules yet. Add rules to automate 80% vs 100% travel targets.",
        .scheduleSetLimit80: "Set 80% Target",
        .scheduleTopUp100: "Top Up 100%",
        .activityLogTitle: "Activity Log",
        .activityLogEmpty: "No battery events recorded yet in this session.",
        .activityLimitAlertSent: "Charge target alert triggered",
        .activityThermalAlertSent: "Thermal state warning triggered",
        .activityLowBatteryAlertSent: "Low battery 20% alert triggered",
        .activityProfileApplied: "Battery profile updated",
        .themePresetTitle: "Theme Preset",
        .presetObsidianSlate: "Obsidian",
        .presetPaperLight: "Paper Light",
        .presetNordicMist: "Nordic Mist",
        .presetMidnightAmber: "Midnight",
        .customAccentTitle: "Accent Color",
        .batteryColorStyleTitle: "Battery Cell Color Style",
        .batteryColorSpectrum: "Adaptive Spectrum",
        .batteryColorThermal: "Thermal Reactive",
        .batteryColorAccent: "Theme Accent",
        .cornerRadiusLabel: "Card Corner Radius",
        .surfaceOpacityLabel: "Card Surface Opacity",
        .wallpaperTitle: "Custom Background",
        .wallpaperSolid: "Solid Theme",
        .wallpaperPhoto: "Custom Photo",
        .wallpaperChoosePhoto: "Choose Photo",
        .wallpaperRemovePhoto: "Remove Photo",
        .wallpaperScrimLabel: "Dark Scrim Opacity",
        .wallpaperBlurLabel: "Background Blur",
        .compatCardTitle: "iPhone Compatibility Profile",
        .compatCachedBadge: "Cached (Checked 1x)",
        .compatRecheckButton: "Re-check",
        .compatModelLabel: "Device Model",
        .compatOSLabel: "iOS Version",
        .compatFeatureTelemetry: "UIDevice Live Telemetry",
        .compatFeatureAlerts: "Smart Charge Alerts",
        .compatFeatureThermal: "Thermal State Monitor",
        .compatFeatureNative80: "Apple Native 80% Limit",
        .compatFeatureSMC: "Kernel SMC / Force Discharge",
        .compatStatusSupported: "Supported",
        .compatReasonNotifDenied: "Enable notifications in iOS Settings",
        .compatReasonOlderIPhone: "Requires iPhone 15 or newer",
        .compatReasonSandboxSMC: "Not possible on iOS (Mac-only SMC)",
        .settingsBackupTitle: "Settings Backup & Reset",
        .exportSettings: "Copy JSON",
        .importSettings: "Paste JSON",
        .resetSettings: "Reset Defaults",
        .settingsCopied: "Settings JSON copied to clipboard.",
        .settingsResetDone: "Settings restored to defaults.",
        .settingsImportInvalid: "Clipboard does not contain valid VoltGuard JSON.",
        .architectureNoteTitle: "iPhone vs Mac Architecture",
        .architectureNoteBody: "VoltGuard iOS keeps identical themes, animated cell graphics, thermal tracking, schedules, and smart notifications while omitting Mac-only SMC kernel write, force discharge, Clamshell, and MagSafe LED controls restricted by iOS.",
        .alertTargetTitle: "Charge Target Reached",
        .alertTargetBody: "iPhone reached your %d%% target limit. Unplug charger to preserve battery health.",
        .alertThermalTitle: "iPhone Running Warm",
        .alertThermalBody: "System thermal state reached Serious/Critical. Pause charging or heavy tasks to cool down.",
        .alertLowBatteryTitle: "Low Battery Warning",
        .alertLowBatteryBody: "Battery dropped to %d%%. Connect a charger soon.",
        .alertTestTitle: "VoltGuard Test Alert",
        .alertTestBody: "Smart charge and thermal notifications are working on your iPhone.",
        .etaHoldingAt: "Target %d%% reached",
        .etaToTarget: "to %d%% target",
        .etaToEmpty: "until empty",
        .thermalTapHint: "Tap for cooling guidance & Thermal Alert control",
        .thermalSafeAdvice: "Battery thermal envelope is healthy. Optimal efficiency during charge and everyday tasks.",
        .thermalWarnAdvice: "Device is warming up. Remove thick cases or pause fast charging briefly to protect cell longevity.",
        .thermalCoolAdvice: "High heat detected! Unplug charger or move away from direct sunlight so iOS stops throttling.",
        .tabUpdates: "Updates",
        .appUpdatesTitle: "Software Update",
        .checkUpdatesButton: "Check for Updates",
        .checkingUpdates: "Checking for updates...",
        .updateAvailableBanner: "Update Ready: v%@",
        .upToDateBanner: "VoltGuard is up to date (v%@)",
        .updatesWhatsNewSection: "Changes in v%@",
        .updatesFixesSection: "Fixes in v%@",
        .updatesCleanHint: "Shows only changes and bug fixes for the latest release.",
        .openDownloadPage: "Open Download Page"
    ]

    public static let id: [L10nKey: String] = [
        .appTitle: "VoltGuard",
        .tabOverview: "Ringkasan",
        .tabAlerts: "Batas & Alert",
        .tabSchedule: "Jadwal",
        .tabAppearance: "Tampilan",
        .tabSystem: "Sistem",
        .statusCharging: "Mengisi Daya",
        .statusLimitReached: "Batas Target Tercapai",
        .statusTopUp: "Top Up 100% Aktif",
        .statusOnBattery: "Pakai Baterai",
        .statusThermalWarning: "Suhu Tinggi",
        .chargeTargetTitle: "Batas Pengingat Pengisian",
        .targetLimitLabel: "Target Batas",
        .topUp100: "Top Up 100%",
        .topUpDesc: "Naikkan target pengingat ke 100% sementara sebelum bepergian, lalu pulih otomatis.",
        .thermalAlert: "Alert Pelindung Panas",
        .thermalAlertDesc: "Kirim notifikasi saat status thermal iPhone mencapai Serious atau Critical.",
        .lowBatteryAlert: "Alert Baterai Lemah 20%",
        .lowBatteryAlertDesc: "Ingatkan saat baterai turun ke 20% atau lebih rendah.",
        .sailingReminder: "Buffer Pengingat Ulang",
        .sailingReminderDesc: "Berikan jeda persen di bawah target agar tidak mengingatkan berulang kali.",
        .thermalStateLabel: "Status Suhu",
        .thermalNominal: "Normal",
        .thermalFair: "Hangat (Fair)",
        .thermalSerious: "Tinggi (Serious)",
        .thermalCritical: "Kritis (Critical)",
        .batteryStateLabel: "Status Daya",
        .statePluggedCharging: "Mengisi",
        .statePluggedFull: "Penuh / Tercolok",
        .stateOnBattery: "Baterai",
        .lowPowerModeLabel: "Hemat Daya",
        .lowPowerOn: "Aktif",
        .lowPowerOff: "Mati",
        .recommendedProfilesTitle: "Profil Rekomendasi",
        .profileBalancedTitle: "Seimbang",
        .profileBalancedDesc: "Target pengingat 80% harian dengan alert suhu aktif.",
        .profileMobilityTitle: "Mobilitas / Travel",
        .profileMobilityDesc: "Target penuh 100% sebelum bepergian jauh.",
        .profileLongevityTitle: "Awet Maksimal",
        .profileLongevityDesc: "Target konservatif 60%-75% untuk memperlambat aus baterai.",
        .applyProfile: "Terapkan",
        .appliedProfile: "Aktif",
        .nativeLimitGuideTitle: "Batas Hardware Bawaan iPhone",
        .nativeLimitGuideBody15Plus: "iPhone 15 dan yang lebih baru mendukung batas pengisian hardware 80% langsung di Settings -> Battery -> Charging. Gunakan VoltGuard untuk target fleksibel 60%/90% & alert panas.",
        .nativeLimitGuideBodyOlder: "iPhone generasi sebelum 15 memakai Optimized Battery Charging di Settings. Aplikasi iOS tidak bisa memotong arus charger secara langsung di kernel, sehingga VoltGuard mengirim alarm real-time di target.",
        .openSettingsButton: "Buka Pengaturan iOS",
        .testAlertButton: "Uji Notifikasi",
        .smartAlertsTitle: "Notifikasi Pintar & Panas",
        .smartAlertsToggle: "Aktifkan Notifikasi Pintar",
        .smartAlertsDesc: "Izinkan VoltGuard mengirim alarm lokal saat target pengisian, baterai 20%, atau panas tinggi tercapai.",
        .scheduleTitle: "Jadwal Pengingat Harian",
        .scheduleNamePlaceholder: "Nama jadwal",
        .addScheduleButton: "Tambah Jadwal",
        .noSchedulesHint: "Belum ada jadwal. Tambahkan aturan otomatis untuk target 80% atau Top Up 100%.",
        .scheduleSetLimit80: "Atur Target 80%",
        .scheduleTopUp100: "Top Up 100%",
        .activityLogTitle: "Log Aktivitas",
        .activityLogEmpty: "Belum ada peristiwa baterai tercatat di sesi ini.",
        .activityLimitAlertSent: "Notifikasi batas pengisian terkirim",
        .activityThermalAlertSent: "Peringatan suhu tinggi terkirim",
        .activityLowBatteryAlertSent: "Peringatan baterai lemah 20% terkirim",
        .activityProfileApplied: "Profil baterai diperbarui",
        .themePresetTitle: "Preset Tema",
        .presetObsidianSlate: "Obsidian",
        .presetPaperLight: "Terang",
        .presetNordicMist: "Nordic Mist",
        .presetMidnightAmber: "Midnight",
        .customAccentTitle: "Warna Aksen",
        .batteryColorStyleTitle: "Gaya Warna Sel Baterai",
        .batteryColorSpectrum: "Spektrum Adaptif",
        .batteryColorThermal: "Reaktif Suhu",
        .batteryColorAccent: "Aksen Tema",
        .cornerRadiusLabel: "Kelengkungan Sudut Kartu",
        .surfaceOpacityLabel: "Opasitas Kartu",
        .wallpaperTitle: "Latar Belakang Kustom",
        .wallpaperSolid: "Tema Solid",
        .wallpaperPhoto: "Foto Kustom",
        .wallpaperChoosePhoto: "Pilih Foto Galeri",
        .wallpaperRemovePhoto: "Hapus Foto",
        .wallpaperScrimLabel: "Opasitas Gelap Latar",
        .wallpaperBlurLabel: "Blur Latar",
        .compatCardTitle: "Profil Kompatibilitas iPhone Ini",
        .compatCachedBadge: "Tersimpan (Cek 1x)",
        .compatRecheckButton: "Cek Ulang",
        .compatModelLabel: "Model Perangkat",
        .compatOSLabel: "Versi iOS",
        .compatFeatureTelemetry: "Telemetri Langsung UIDevice",
        .compatFeatureAlerts: "Notifikasi Batas Pengisian",
        .compatFeatureThermal: "Monitor Status Thermal",
        .compatFeatureNative80: "Batas Hardware 80% Apple",
        .compatFeatureSMC: "Kontrol SMC / Force Discharge",
        .compatStatusSupported: "Didukung",
        .compatReasonNotifDenied: "Aktifkan izin notifikasi di Settings",
        .compatReasonOlderIPhone: "Butuh iPhone 15 atau lebih baru",
        .compatReasonSandboxSMC: "Tidak didukung arsitektur iOS (khusus Mac)",
        .settingsBackupTitle: "Cadangan & Reset Pengaturan",
        .exportSettings: "Salin JSON",
        .importSettings: "Tempel JSON",
        .resetSettings: "Reset Default",
        .settingsCopied: "JSON pengaturan disalin ke clipboard.",
        .settingsResetDone: "Pengaturan dikembalikan ke bawaan.",
        .settingsImportInvalid: "Clipboard tidak berisi JSON VoltGuard iOS yang valid.",
        .architectureNoteTitle: "Perbedaan Arsitektur iPhone vs Mac",
        .architectureNoteBody: "VoltGuard iOS menyamakan tema, sel baterai animasi, monitor thermal, jadwal, dan alert pintar dengan versi Mac, tanpa kontrol SMC kernel, discharge paksa, Clamshell, atau LED MagSafe yang hanya ada di Mac.",
        .alertTargetTitle: "Batas Pengisian Tercapai",
        .alertTargetBody: "Baterai iPhone mencapai target %d%%. Cabut charger untuk menjaga kesehatan sel baterai.",
        .alertThermalTitle: "Suhu iPhone Meningkat",
        .alertThermalBody: "Status suhu sistem mencapai Serious/Critical. Jeda pengisian atau beban berat sejenak.",
        .alertLowBatteryTitle: "Baterai Lemah",
        .alertLowBatteryBody: "Baterai turun ke %d%%. Segera hubungkan pengisi daya.",
        .alertTestTitle: "Uji Notifikasi VoltGuard",
        .alertTestBody: "Notifikasi batas pengisian dan suhu siap bekerja di iPhone Anda.",
        .etaHoldingAt: "Target %d%% tercapai",
        .etaToTarget: "menuju target %d%%",
        .etaToEmpty: "sampai habis",
        .thermalTapHint: "Ketuk untuk panduan pendinginan & Alert Panas",
        .thermalSafeAdvice: "Suhu baterai sehat dan sejuk. Efisiensi optimal untuk mengisi daya maupun aktivitas harian.",
        .thermalWarnAdvice: "Perangkat mulai hangat. Lepas casing tebal atau jeda sebentar pengisian cepat agar sel baterai awet.",
        .thermalCoolAdvice: "Suhu tinggi terdeteksi! Cabut charger atau hindari panas langsung agar iOS berhenti throttle.",
        .tabUpdates: "Pembaruan",
        .appUpdatesTitle: "Pembaruan Aplikasi",
        .checkUpdatesButton: "Cek Pembaruan",
        .checkingUpdates: "Memeriksa pembaruan...",
        .updateAvailableBanner: "Pembaruan Tersedia: v%@",
        .upToDateBanner: "VoltGuard versi terbaru (v%@)",
        .updatesWhatsNewSection: "Perubahan di v%@",
        .updatesFixesSection: "Perbaikan di v%@",
        .updatesCleanHint: "Hanya menampilkan perubahan dan perbaikan versi terbaru.",
        .openDownloadPage: "Buka Halaman Unduh"
    ]
}

public enum BatteryETAFormatter {
    public static func text(for eta: BatteryETA?, locale: AppLocale) -> String {
        guard let eta else { return "--" }
        switch eta.kind {
        case .steady:
            return String(format: L10n.text(.etaHoldingAt, locale: locale), eta.targetPercent)
        case .toTargetLimit:
            let suffix = String(format: L10n.text(.etaToTarget, locale: locale), eta.targetPercent)
            return "\(formatDuration(minutes: eta.minutes ?? 1, locale: locale)) \(suffix)"
        case .toEmpty:
            return "\(formatDuration(minutes: eta.minutes ?? 1, locale: locale)) \(L10n.text(.etaToEmpty, locale: locale))"
        }
    }

    private static func formatDuration(minutes: Int, locale: AppLocale) -> String {
        let h = minutes / 60
        let m = minutes % 60
        let hourUnit = locale == .id ? "j" : "h"
        if h > 0 && m > 0 { return "\(h)\(hourUnit) \(m)m" }
        if h > 0 { return "\(h)\(hourUnit)" }
        return "\(m)m"
    }
}
