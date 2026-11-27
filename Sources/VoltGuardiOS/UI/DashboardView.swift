import SwiftUI
#if os(iOS)
import PhotosUI
import UIKit
#endif
import VoltGuardDomain

public struct DashboardView: View {
    @StateObject private var store: VoltGuardiOSStore
    @State private var selectedTab: Int = 0
    @State private var newScheduleTitle: String = ""
    @State private var newScheduleTime: Date = Date()
    @State private var newScheduleAction: ScheduleAction = .setLimit80
    @State private var customHexInput: String = ""
    #if os(iOS)
    @State private var selectedPhotoItem: PhotosPickerItem?
    #endif

    @MainActor
    public init(store: VoltGuardiOSStore? = nil) {
        _store = StateObject(wrappedValue: store ?? VoltGuardiOSStore())
    }

    public var body: some View {
        let palette = store.palette
        let locale = store.settings.locale

        NavigationStack {
            ZStack {
                backgroundLayer(palette: palette)

                TabView(selection: $selectedTab) {
                    overviewTab(palette: palette, locale: locale)
                        .tabItem { Label(L10n.text(.tabOverview, locale: locale), systemImage: "battery.100percent") }
                        .tag(0)

                    alertsAndLimitsTab(palette: palette, locale: locale)
                        .tabItem { Label(L10n.text(.tabAlerts, locale: locale), systemImage: "bell.badge.fill") }
                        .tag(1)

                    scheduleAndLogTab(palette: palette, locale: locale)
                        .tabItem { Label(L10n.text(.tabSchedule, locale: locale), systemImage: "calendar.badge.clock") }
                        .tag(2)

                    appearanceTab(palette: palette, locale: locale)
                        .tabItem { Label(L10n.text(.tabAppearance, locale: locale), systemImage: "paintpalette.fill") }
                        .tag(3)

                    systemTab(palette: palette, locale: locale)
                        .tabItem { Label(L10n.text(.tabSystem, locale: locale), systemImage: "gearshape.2.fill") }
                        .tag(4)

                    updatesTab(palette: palette, locale: locale)
                        .tabItem { Label(L10n.text(.tabUpdates, locale: locale), systemImage: "arrow.down.circle.fill") }
                        .tag(5)
                }
                .tint(palette.accent)
            }
            .preferredColorScheme(palette.isDark ? .dark : .light)
            .toolbar {
                ToolbarItem(placement: .topBarLeadingOrAutomatic) {
                    HStack(spacing: 8) {
                        BrandLogoView(size: 26, accentColor: palette.accent)
                        Text(L10n.text(.appTitle, locale: locale))
                            .font(.headline.bold())
                            .foregroundStyle(palette.primaryText)
                    }
                }
                ToolbarItem(placement: .topBarTrailingOrAutomatic) {
                    Button {
                        store.setLocale(locale == .en ? .id : .en)
                    } label: {
                        Text(locale == .en ? "EN" : "ID")
                            .font(.caption.bold())
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(palette.surface)
                            .foregroundStyle(palette.accent)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(palette.border, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .compatOnChange(of: selectedPhotoItem) { newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        store.saveWallpaperImageData(data)
                    }
                }
            }
            #endif
            .onAppear {
                customHexInput = store.settings.theme.customAccentHex ?? palette.accentHex
                store.refreshTelemetry()
            }
        }
    }

    @ViewBuilder
    private func backgroundLayer(palette: ThemePalette) -> some View {
        ZStack {
            palette.background.ignoresSafeArea()
            #if os(iOS)
            if store.settings.theme.useCustomBackground,
               let path = store.settings.theme.customBackgroundPath,
               let img = UIImage(contentsOfFile: path) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .blur(radius: store.settings.theme.backgroundBlurRadius)
                Color.black
                    .opacity(store.settings.theme.backgroundScrimOpacity)
                    .ignoresSafeArea()
            }
            #endif
        }
    }

    // MARK: - 1. Overview Tab
    @ViewBuilder
    private func overviewTab(palette: ThemePalette, locale: AppLocale) -> some View {
        let t = store.telemetry
        let policy = store.settings.policy
        let target = policy.effectiveTargetPercent
        let visualMode: BatteryVisualMode = {
            if t.thermalLevel == .serious || t.thermalLevel == .critical { return .thermalWarning }
            if t.isPluggedIn && t.percentage >= target { return .limitReached }
            if t.isCharging { return .charging }
            return .onBattery
        }()

        ScrollView {
            VStack(spacing: 16) {
                cardContainer(palette: palette) {
                    HStack(spacing: 16) {
                        LiquidBatteryCellView(
                            percentage: t.percentage,
                            limitPercent: target,
                            sailingDeltaPercent: policy.sailingReminderEnabled ? policy.sailingDeltaPercent : nil,
                            thermalLevel: t.thermalLevel,
                            colorStyle: store.settings.theme.batteryColorStyle,
                            mode: visualMode,
                            palette: palette
                        ) { newLimit in
                            store.setTargetLimit(newLimit)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(statusTitle(t: t, target: target, locale: locale))
                                .font(.headline)
                                .foregroundStyle(palette.primaryText)

                            Text(BatteryETAFormatter.text(for: store.batteryETA, locale: locale))
                                .font(.subheadline.monospacedDigit().weight(.semibold))
                                .foregroundStyle(palette.accent)
                                .compatNumericTransition()

                            Text("\(L10n.text(.targetLimitLabel, locale: locale)): \(target)%")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(palette.secondaryText)

                            Slider(
                                value: Binding(
                                    get: { Double(policy.limitPercent) },
                                    set: { store.setTargetLimit(Int($0.rounded())) }
                                ),
                                in: Double(VoltGuardiOSLimits.minLimitPercent)...Double(VoltGuardiOSLimits.maxLimitPercent)
                            )
                            .tint(palette.accent)
                        }
                    }

                    HStack(spacing: 8) {
                        ForEach(VoltGuardiOSLimits.quickPresets, id: \.self) { preset in
                            let isSelected = policy.limitPercent == preset && !policy.topUpActive
                            Button {
                                store.setTargetLimit(preset)
                            } label: {
                                Text("\(preset)%")
                                    .font(.caption.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? palette.accent : palette.background.opacity(0.65))
                                    .foregroundStyle(isSelected ? (palette.isDark ? Color.black : Color.white) : palette.primaryText)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.clear : palette.border, lineWidth: 1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }

                HStack(spacing: 12) {
                    statCard(
                        title: L10n.text(.batteryStateLabel, locale: locale),
                        value: t.isPluggedIn ? L10n.text(t.isCharging ? .statePluggedCharging : .statePluggedFull, locale: locale) : L10n.text(.stateOnBattery, locale: locale),
                        tint: t.isPluggedIn ? palette.accent : palette.warning,
                        palette: palette
                    )
                    statCard(
                        title: L10n.text(.lowPowerModeLabel, locale: locale),
                        value: L10n.text(t.isLowPowerModeEnabled ? .lowPowerOn : .lowPowerOff, locale: locale),
                        tint: t.isLowPowerModeEnabled ? palette.warning : palette.secondaryText,
                        palette: palette
                    )
                }

                InteractiveiOSThermalCard(
                    telemetry: t,
                    thermalAlertEnabled: policy.thermalAlertEnabled,
                    locale: locale,
                    palette: palette,
                    onToggleThermalAlert: { store.toggleThermalAlert() }
                )

                cardContainer(palette: palette) {
                    Text(L10n.text(.recommendedProfilesTitle, locale: locale))
                        .font(.headline)
                        .foregroundStyle(palette.primaryText)

                    profileRow(
                        tier: .balanced,
                        title: L10n.text(.profileBalancedTitle, locale: locale),
                        desc: L10n.text(.profileBalancedDesc, locale: locale),
                        isActive: policy.limitPercent == 80 && !policy.topUpActive,
                        palette: palette,
                        locale: locale
                    )
                    profileRow(
                        tier: .mobility,
                        title: L10n.text(.profileMobilityTitle, locale: locale),
                        desc: L10n.text(.profileMobilityDesc, locale: locale),
                        isActive: policy.limitPercent == 100 && !policy.topUpActive,
                        palette: palette,
                        locale: locale
                    )
                    profileRow(
                        tier: .longevity,
                        title: L10n.text(.profileLongevityTitle, locale: locale),
                        desc: L10n.text(.profileLongevityDesc, locale: locale),
                        isActive: policy.limitPercent <= 75 && !policy.topUpActive,
                        palette: palette,
                        locale: locale
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - 2. Alerts & Limits Tab
    @ViewBuilder
    private func alertsAndLimitsTab(palette: ThemePalette, locale: AppLocale) -> some View {
        let compat = store.effectiveCompatibility
        let policy = store.settings.policy

        ScrollView {
            VStack(spacing: 16) {
                cardContainer(palette: palette) {
                    Label(L10n.text(.nativeLimitGuideTitle, locale: locale), systemImage: "bolt.shield.fill")
                        .font(.headline)
                        .foregroundStyle(palette.accent)
                    Text(L10n.text(compat.hardwareProfile.supportsNative80LimitSetting ? .nativeLimitGuideBody15Plus : .nativeLimitGuideBodyOlder, locale: locale))
                        .font(.caption)
                        .foregroundStyle(palette.secondaryText)

                    HStack(spacing: 10) {
                        Button(L10n.text(.openSettingsButton, locale: locale)) {
                            #if os(iOS)
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                            #endif
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(palette.accent)

                        Button(L10n.text(.testAlertButton, locale: locale)) {
                            store.sendTestNotification()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!compat.smartChargeAlerts.supported)
                    }
                }

                cardContainer(palette: palette) {
                    Text(L10n.text(.smartAlertsTitle, locale: locale))
                        .font(.headline)
                        .foregroundStyle(palette.primaryText)

                    toggleRow(
                        icon: "bell.badge.fill",
                        title: L10n.text(.smartAlertsToggle, locale: locale),
                        subtitle: compat.smartChargeAlerts.supported ? L10n.text(.smartAlertsDesc, locale: locale) : L10n.text(.compatReasonNotifDenied, locale: locale),
                        isOn: store.settings.alertsEnabled,
                        disabled: !compat.smartChargeAlerts.supported,
                        palette: palette
                    ) { store.toggleSmartNotifications() }

                    toggleRow(
                        icon: "bolt.fill",
                        title: L10n.text(.topUp100, locale: locale),
                        subtitle: L10n.text(.topUpDesc, locale: locale),
                        isOn: policy.topUpActive,
                        disabled: false,
                        palette: palette
                    ) { store.toggleTopUp() }

                    toggleRow(
                        icon: "thermometer.sun.fill",
                        title: L10n.text(.thermalAlert, locale: locale),
                        subtitle: L10n.text(.thermalAlertDesc, locale: locale),
                        isOn: policy.thermalAlertEnabled,
                        disabled: !store.settings.alertsEnabled,
                        palette: palette
                    ) { store.toggleThermalAlert() }

                    toggleRow(
                        icon: "battery.25",
                        title: L10n.text(.lowBatteryAlert, locale: locale),
                        subtitle: L10n.text(.lowBatteryAlertDesc, locale: locale),
                        isOn: policy.lowBatteryAlertEnabled,
                        disabled: !store.settings.alertsEnabled,
                        palette: palette
                    ) { store.toggleLowBatteryAlert() }

                    toggleRow(
                        icon: "wind",
                        title: L10n.text(.sailingReminder, locale: locale),
                        subtitle: L10n.text(.sailingReminderDesc, locale: locale),
                        isOn: policy.sailingReminderEnabled,
                        disabled: !store.settings.alertsEnabled,
                        palette: palette
                    ) { store.toggleSailingReminder() }
                }
            }
            .padding()
        }
    }

    // MARK: - 3. Schedule & Activity Tab
    @ViewBuilder
    private func scheduleAndLogTab(palette: ThemePalette, locale: AppLocale) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                cardContainer(palette: palette) {
                    Text(L10n.text(.scheduleTitle, locale: locale))
                        .font(.headline)
                        .foregroundStyle(palette.primaryText)

                    TextField(L10n.text(.scheduleNamePlaceholder, locale: locale), text: $newScheduleTitle)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        DatePicker("", selection: $newScheduleTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                        Picker("", selection: $newScheduleAction) {
                            Text(L10n.text(.scheduleSetLimit80, locale: locale)).tag(ScheduleAction.setLimit80)
                            Text(L10n.text(.scheduleTopUp100, locale: locale)).tag(ScheduleAction.topUp100)
                        }
                        Spacer()
                        Button(L10n.text(.addScheduleButton, locale: locale)) {
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: newScheduleTime)
                            store.addSchedule(
                                title: newScheduleTitle,
                                hour: comps.hour ?? 8,
                                minute: comps.minute ?? 0,
                                action: newScheduleAction
                            )
                            newScheduleTitle = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(palette.accent)
                    }

                    if store.settings.schedules.isEmpty {
                        Text(L10n.text(.noSchedulesHint, locale: locale))
                            .font(.caption)
                            .foregroundStyle(palette.secondaryText)
                    } else {
                        ForEach(store.settings.schedules) { rule in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rule.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(palette.primaryText)
                                    Text(String(format: "%02d:%02d · %@", rule.hour, rule.minute, L10n.text(rule.action == .topUp100 ? .scheduleTopUp100 : .scheduleSetLimit80, locale: locale)))
                                        .font(.caption.monospaced())
                                        .foregroundStyle(palette.secondaryText)
                                }
                                Spacer()
                                Toggle("", isOn: Binding(get: { rule.isEnabled }, set: { _ in store.toggleSchedule(id: rule.id) }))
                                    .labelsHidden()
                                    .tint(palette.accent)
                                Button(role: .destructive) {
                                    store.removeSchedule(id: rule.id)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(palette.danger)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                cardContainer(palette: palette) {
                    Text(L10n.text(.activityLogTitle, locale: locale))
                        .font(.headline)
                        .foregroundStyle(palette.primaryText)

                    if store.activityLog.isEmpty {
                        Text(L10n.text(.activityLogEmpty, locale: locale))
                            .font(.caption)
                            .foregroundStyle(palette.secondaryText)
                    } else {
                        ForEach(store.activityLog.prefix(10)) { entry in
                            HStack {
                                Text(L10n.text(L10nKey(rawValue: entry.messageKey) ?? .activityProfileApplied, locale: locale))
                                    .font(.caption)
                                    .foregroundStyle(palette.primaryText)
                                Spacer()
                                Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(palette.secondaryText)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - 4. Appearance Tab (Identical Desktop Theme Studio)
    @ViewBuilder
    private func appearanceTab(palette: ThemePalette, locale: AppLocale) -> some View {
        let theme = store.settings.theme

        ScrollView {
            VStack(spacing: 16) {
                cardContainer(palette: palette) {
                    Text(L10n.text(.themePresetTitle, locale: locale))
                        .font(.headline)
                        .foregroundStyle(palette.primaryText)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(ThemePreset.allCases, id: \.self) { preset in
                            let isSelected = theme.preset == preset
                            let specPalette = ThemePalette.resolve(ThemeConfig(preset: preset))
                            Button {
                                var next = theme
                                next.preset = preset
                                next.customAccentHex = nil
                                store.updateTheme(next)
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(specPalette.accent)
                                        .frame(width: 12, height: 12)
                                    Text(presetTitle(preset, locale: locale))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(palette.primaryText)
                                    Spacer()
                                }
                                .padding(10)
                                .background(isSelected ? palette.accent.opacity(0.18) : palette.background.opacity(0.6))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? palette.accent : palette.border, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }

                    Divider()

                    Text(L10n.text(.customAccentTitle, locale: locale))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.secondaryText)

                    HStack(spacing: 10) {
                        ForEach(ThemeHexConstants.accentSwatches, id: \.self) { hex in
                            let selected = palette.accentHex.caseInsensitiveCompare(hex) == .orderedSame
                            Button {
                                var next = theme
                                next.customAccentHex = hex
                                customHexInput = hex
                                store.updateTheme(next)
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 26, height: 26)
                                    .overlay(Circle().stroke(selected ? palette.primaryText : Color.clear, lineWidth: 2))
                            }
                        }
                        TextField("#10B981", text: $customHexInput)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                var next = theme
                                next.customAccentHex = customHexInput
                                store.updateTheme(next)
                            }
                    }

                    Text(L10n.text(.batteryColorStyleTitle, locale: locale))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.secondaryText)

                    HStack(spacing: 8) {
                        ForEach(BatteryColorStyle.allCases, id: \.self) { style in
                            let selected = theme.batteryColorStyle == style
                            Button {
                                var next = theme
                                next.batteryColorStyle = style
                                store.updateTheme(next)
                            } label: {
                                Text(colorStyleTitle(style, locale: locale))
                                    .font(.caption.weight(selected ? .semibold : .medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(selected ? palette.accent.opacity(0.18) : palette.background.opacity(0.55))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(selected ? palette.accent : palette.border, lineWidth: 1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(L10n.text(.cornerRadiusLabel, locale: locale)): \(Int(theme.cornerRadius))px")
                            .font(.caption)
                            .foregroundStyle(palette.secondaryText)
                        Slider(
                            value: Binding(
                                get: { theme.cornerRadius },
                                set: {
                                    var next = theme
                                    next.cornerRadius = $0.rounded()
                                    store.updateTheme(next)
                                }
                            ),
                            in: VoltGuardiOSLimits.minCornerRadius...VoltGuardiOSLimits.maxCornerRadius
                        )
                        .tint(palette.accent)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(L10n.text(.surfaceOpacityLabel, locale: locale)): \(Int(theme.surfaceOpacity * 100))%")
                            .font(.caption)
                            .foregroundStyle(palette.secondaryText)
                        Slider(
                            value: Binding(
                                get: { theme.surfaceOpacity },
                                set: {
                                    var next = theme
                                    next.surfaceOpacity = $0
                                    store.updateTheme(next)
                                }
                            ),
                            in: VoltGuardiOSLimits.minSurfaceOpacity...VoltGuardiOSLimits.maxSurfaceOpacity
                        )
                        .tint(palette.accent)
                    }
                }

                #if os(iOS)
                cardContainer(palette: palette) {
                    Text(L10n.text(.wallpaperTitle, locale: locale))
                        .font(.headline)
                        .foregroundStyle(palette.primaryText)

                    HStack(spacing: 10) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label(L10n.text(.wallpaperChoosePhoto, locale: locale), systemImage: "photo.on.rectangle")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(palette.accent.opacity(0.18))
                                .foregroundStyle(palette.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        if theme.useCustomBackground {
                            Button(L10n.text(.wallpaperRemovePhoto, locale: locale)) {
                                store.clearWallpaperImage()
                            }
                            .buttonStyle(.bordered)
                            .tint(palette.danger)
                        }
                    }

                    if theme.useCustomBackground {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(L10n.text(.wallpaperScrimLabel, locale: locale)): \(Int(theme.backgroundScrimOpacity * 100))%")
                                .font(.caption)
                                .foregroundStyle(palette.secondaryText)
                            Slider(
                                value: Binding(
                                    get: { theme.backgroundScrimOpacity },
                                    set: {
                                        var next = theme
                                        next.backgroundScrimOpacity = $0
                                        store.updateTheme(next)
                                    }
                                ),
                                in: 0.0...0.9
                            )
                            .tint(palette.accent)

                            Text("\(L10n.text(.wallpaperBlurLabel, locale: locale)): \(Int(theme.backgroundBlurRadius))px")
                                .font(.caption)
                                .foregroundStyle(palette.secondaryText)
                            Slider(
                                value: Binding(
                                    get: { theme.backgroundBlurRadius },
                                    set: {
                                        var next = theme
                                        next.backgroundBlurRadius = $0
                                        store.updateTheme(next)
                                    }
                                ),
                                in: 0.0...24.0
                            )
                            .tint(palette.accent)
                        }
                    }
                }
                #endif
            }
            .padding()
        }
    }

    // MARK: - 5. System & Guide Tab
    @ViewBuilder
    private func systemTab(palette: ThemePalette, locale: AppLocale) -> some View {
        let compat = store.effectiveCompatibility

        ScrollView {
            VStack(spacing: 16) {
                cardContainer(palette: palette) {
                    Text(L10n.text(.compatCardTitle, locale: locale))
                        .font(.headline)
                        .foregroundStyle(palette.primaryText)

                    HStack {
                        Text(L10n.text(.compatCachedBadge, locale: locale))
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(palette.accent.opacity(0.18))
                            .foregroundStyle(palette.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text(compat.checkedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2.monospaced())
                            .foregroundStyle(palette.secondaryText)
                        Spacer()
                        Button(L10n.text(.compatRecheckButton, locale: locale)) {
                            store.refreshCompatibilityOnce(force: true)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    HStack(spacing: 10) {
                        statCard(title: L10n.text(.compatModelLabel, locale: locale), value: compat.hardwareProfile.modelIdentifier, tint: palette.primaryText, palette: palette)
                        statCard(title: L10n.text(.compatOSLabel, locale: locale), value: "iOS \(compat.hardwareProfile.iOSVersionString)", tint: palette.accent, palette: palette)
                    }

                    compatRow(title: L10n.text(.compatFeatureTelemetry, locale: locale), status: compat.liveTelemetry, locale: locale, palette: palette)
                    compatRow(title: L10n.text(.compatFeatureAlerts, locale: locale), status: compat.smartChargeAlerts, locale: locale, palette: palette)
                    compatRow(title: L10n.text(.compatFeatureThermal, locale: locale), status: compat.thermalMonitor, locale: locale, palette: palette)
                    compatRow(title: L10n.text(.compatFeatureNative80, locale: locale), status: compat.native80HardwareLimit, locale: locale, palette: palette)
                    compatRow(title: L10n.text(.compatFeatureSMC, locale: locale), status: compat.kernelSMCAndDischarge, locale: locale, palette: palette)
                }

                cardContainer(palette: palette) {
                    Text(L10n.text(.architectureNoteTitle, locale: locale))
                        .font(.headline)
                        .foregroundStyle(palette.primaryText)
                    Text(L10n.text(.architectureNoteBody, locale: locale))
                        .font(.caption)
                        .foregroundStyle(palette.secondaryText)
                }

                cardContainer(palette: palette) {
                    Text(L10n.text(.settingsBackupTitle, locale: locale))
                        .font(.headline)
                        .foregroundStyle(palette.primaryText)

                    HStack(spacing: 10) {
                        Button(L10n.text(.exportSettings, locale: locale)) {
                            let json = store.exportSettingsJSON()
                            #if os(iOS)
                            UIPasteboard.general.string = json
                            #endif
                            store.feedbackMessage = L10n.text(.settingsCopied, locale: locale)
                        }
                        .buttonStyle(.bordered)

                        Button(L10n.text(.importSettings, locale: locale)) {
                            #if os(iOS)
                            let text = UIPasteboard.general.string ?? ""
                            store.feedbackMessage = store.importSettingsJSON(text) ? nil : L10n.text(.settingsImportInvalid, locale: locale)
                            #endif
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button(L10n.text(.resetSettings, locale: locale)) {
                            store.resetSettings()
                            store.feedbackMessage = L10n.text(.settingsResetDone, locale: locale)
                        }
                        .buttonStyle(.bordered)
                        .tint(palette.danger)
                    }

                    if let msg = store.feedbackMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(palette.accent)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - 6. Dedicated Updates Tab
    @ViewBuilder
    private func updatesTab(palette: ThemePalette, locale: AppLocale) -> some View {
        let latest = store.updateResult
        let activeVersion = latest?.latestVersion ?? iOSReleaseInfo.currentVersion
        let activeDate = latest?.publishedAt ?? iOSReleaseInfo.latestPublishedDate
        let changes = locale == .id
            ? (latest?.latestChangesID ?? iOSReleaseInfo.latestChangesID)
            : (latest?.latestChangesEN ?? iOSReleaseInfo.latestChangesEN)
        let fixes = locale == .id
            ? (latest?.latestFixesID ?? iOSReleaseInfo.latestFixesID)
            : (latest?.latestFixesEN ?? iOSReleaseInfo.latestFixesEN)

        ScrollView {
            VStack(spacing: 16) {
                cardContainer(palette: palette) {
                    HStack(spacing: 12) {
                        BrandLogoView(size: 38, accentColor: palette.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.text(.appUpdatesTitle, locale: locale))
                                .font(.headline)
                                .foregroundStyle(palette.primaryText)
                            Text("VoltGuard iOS v\(iOSReleaseInfo.currentVersion) (Build \(iOSReleaseInfo.buildNumber))")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(palette.secondaryText)
                        }
                        Spacer()
                        Button {
                            store.checkForUpdates()
                        } label: {
                            if store.isCheckingUpdates {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text(L10n.text(.checkUpdatesButton, locale: locale))
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(palette.accent)
                        .disabled(store.isCheckingUpdates)
                    }

                    if let update = latest {
                        HStack(spacing: 8) {
                            Image(systemName: update.isUpdateAvailable ? "arrow.down.circle.fill" : "checkmark.circle.fill")
                                .foregroundStyle(update.isUpdateAvailable ? palette.warning : palette.accent)
                            Text(
                                String(
                                    format: L10n.text(update.isUpdateAvailable ? .updateAvailableBanner : .upToDateBanner, locale: locale),
                                    update.latestVersion
                                )
                            )
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.primaryText)
                            Spacer()
                            if update.isUpdateAvailable, let url = URL(string: update.updatePageURL) {
                                Link(L10n.text(.openDownloadPage, locale: locale), destination: url)
                                    .font(.caption.weight(.semibold))
                            }
                        }
                        .padding(10)
                        .background((update.isUpdateAvailable ? palette.warning : palette.accent).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Text(L10n.text(.updatesCleanHint, locale: locale))
                        .font(.caption)
                        .foregroundStyle(palette.secondaryText)
                }

                cardContainer(palette: palette) {
                    HStack {
                        Text(String(format: L10n.text(.updatesWhatsNewSection, locale: locale), activeVersion))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.primaryText)
                        Spacer()
                        Text(activeDate)
                            .font(.caption2.monospaced())
                            .foregroundStyle(palette.secondaryText)
                    }

                    ForEach(Array(changes.enumerated()), id: \.offset) { _, line in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.caption)
                                .foregroundStyle(palette.accent)
                                .padding(.top, 2)
                            Text(line)
                                .font(.caption)
                                .foregroundStyle(palette.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if !fixes.isEmpty {
                        Divider()
                        Text(String(format: L10n.text(.updatesFixesSection, locale: locale), activeVersion))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.primaryText)

                        ForEach(Array(fixes.enumerated()), id: \.offset) { _, line in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "wrench.and.screwdriver.fill")
                                    .font(.caption)
                                    .foregroundStyle(palette.warning)
                                    .padding(.top, 2)
                                Text(line)
                                    .font(.caption)
                                    .foregroundStyle(palette.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            if store.updateResult == nil && !store.isCheckingUpdates {
                store.checkForUpdates()
            }
        }
    }

    // MARK: - Helpers
    @ViewBuilder
    private func cardContainer<Content: View>(palette: ThemePalette, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface)
        .overlay(RoundedRectangle(cornerRadius: palette.cornerRadius, style: .continuous).strokeBorder(palette.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: palette.cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private func statCard(title: String, value: String, tint: Color, palette: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(palette.secondaryText)
                .lineLimit(1)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(palette.surface)
        .overlay(RoundedRectangle(cornerRadius: palette.cornerRadius, style: .continuous).strokeBorder(palette.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: palette.cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private func profileRow(tier: ProfileTier, title: String, desc: String, isActive: Bool, palette: ThemePalette, locale: AppLocale) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.primaryText)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
            }
            Spacer()
            Button(L10n.text(isActive ? .appliedProfile : .applyProfile, locale: locale)) {
                store.applyProfile(tier)
            }
            .buttonStyle(.borderedProminent)
            .tint(isActive ? palette.accent : palette.border)
            .controlSize(.small)
        }
        .padding(10)
        .background(palette.background.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func toggleRow(icon: String, title: String, subtitle: String, isOn: Bool, disabled: Bool, palette: ThemePalette, action: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(isOn && !disabled ? palette.accent : palette.secondaryText)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.primaryText)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(disabled ? palette.warning : palette.secondaryText)
            }
            Spacer()
            Toggle("", isOn: Binding(get: { isOn && !disabled }, set: { _ in if !disabled { action() } }))
                .labelsHidden()
                .tint(palette.accent)
                .disabled(disabled)
        }
        .padding(10)
        .background(palette.background.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(disabled ? 0.52 : 1.0)
    }

    @ViewBuilder
    private func compatRow(title: String, status: FeatureCapabilityStatus, locale: AppLocale, palette: ThemePalette) -> some View {
        HStack {
            Image(systemName: status.supported ? "checkmark.circle.fill" : "minus.circle.fill")
                .foregroundStyle(status.supported ? palette.accent : palette.warning)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.primaryText)
            Spacer()
            Text(compatReason(status, locale: locale))
                .font(.caption2)
                .foregroundStyle(status.supported ? palette.accent : palette.warning)
        }
        .padding(.vertical, 3)
    }

    private func compatReason(_ status: FeatureCapabilityStatus, locale: AppLocale) -> String {
        if status.supported { return L10n.text(.compatStatusSupported, locale: locale) }
        switch status.reasonCode {
        case "notifications_denied": return L10n.text(.compatReasonNotifDenied, locale: locale)
        case "requires_iphone15_plus": return L10n.text(.compatReasonOlderIPhone, locale: locale)
        case "ios_sandbox_restricted": return L10n.text(.compatReasonSandboxSMC, locale: locale)
        default: return status.reasonCode
        }
    }

    private func statusTitle(t: iOSBatteryTelemetry, target: Int, locale: AppLocale) -> String {
        if t.thermalLevel == .serious || t.thermalLevel == .critical {
            return L10n.text(.statusThermalWarning, locale: locale)
        }
        if t.isPluggedIn && t.percentage >= target {
            return L10n.text(.statusLimitReached, locale: locale)
        }
        if store.settings.policy.topUpActive && t.isCharging {
            return L10n.text(.statusTopUp, locale: locale)
        }
        return L10n.text(t.isCharging ? .statusCharging : .statusOnBattery, locale: locale)
    }

    private func thermalText(_ level: iOSThermalLevel, locale: AppLocale) -> String {
        switch level {
        case .nominal: return L10n.text(.thermalNominal, locale: locale)
        case .fair: return L10n.text(.thermalFair, locale: locale)
        case .serious: return L10n.text(.thermalSerious, locale: locale)
        case .critical: return L10n.text(.thermalCritical, locale: locale)
        }
    }

    private func thermalColor(_ level: iOSThermalLevel, palette: ThemePalette) -> Color {
        switch level {
        case .nominal: return palette.accent
        case .fair: return palette.warning
        case .serious, .critical: return palette.danger
        }
    }

    private func presetTitle(_ preset: ThemePreset, locale: AppLocale) -> String {
        switch preset {
        case .obsidianSlate: return L10n.text(.presetObsidianSlate, locale: locale)
        case .paperLight: return L10n.text(.presetPaperLight, locale: locale)
        case .nordicMist: return L10n.text(.presetNordicMist, locale: locale)
        case .midnightAmber: return L10n.text(.presetMidnightAmber, locale: locale)
        }
    }

    private func colorStyleTitle(_ style: BatteryColorStyle, locale: AppLocale) -> String {
        switch style {
        case .adaptiveSpectrum: return L10n.text(.batteryColorSpectrum, locale: locale)
        case .thermalReactive: return L10n.text(.batteryColorThermal, locale: locale)
        case .themeAccent: return L10n.text(.batteryColorAccent, locale: locale)
        }
    }
}

private extension ToolbarItemPlacement {
    static var topBarLeadingOrAutomatic: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarLeading
        #else
        return .automatic
        #endif
    }

    static var topBarTrailingOrAutomatic: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarTrailing
        #else
        return .automatic
        #endif
    }
}

private struct InteractiveiOSThermalCard: View {
    let telemetry: iOSBatteryTelemetry
    let thermalAlertEnabled: Bool
    let locale: AppLocale
    let palette: ThemePalette
    let onToggleThermalAlert: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded: Bool = false

    private var levelColor: Color {
        switch telemetry.thermalLevel {
        case .nominal: return palette.accent
        case .fair: return palette.warning
        case .serious, .critical: return palette.danger
        }
    }

    private var normalizedHeat: Double {
        switch telemetry.thermalLevel {
        case .nominal: return 0.28
        case .fair: return 0.56
        case .serious: return 0.80
        case .critical: return 0.96
        }
    }

    private var statusTitle: String {
        switch telemetry.thermalLevel {
        case .nominal: return L10n.text(.thermalNominal, locale: locale)
        case .fair: return L10n.text(.thermalFair, locale: locale)
        case .serious: return L10n.text(.thermalSerious, locale: locale)
        case .critical: return L10n.text(.thermalCritical, locale: locale)
        }
    }

    private var adviceText: String {
        switch telemetry.thermalLevel {
        case .nominal: return L10n.text(.thermalSafeAdvice, locale: locale)
        case .fair: return L10n.text(.thermalWarnAdvice, locale: locale)
        case .serious, .critical: return L10n.text(.thermalCoolAdvice, locale: locale)
        }
    }

    var body: some View {
        let animate = !reduceMotion
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.85)) {
                    isExpanded.toggle()
                }
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(levelColor)
                            .frame(width: 8, height: 8)
                            .shadow(color: levelColor.opacity(0.6), radius: animate ? 4 : 0)
                        Text(L10n.text(.thermalStateLabel, locale: locale))
                            .font(.caption)
                            .foregroundStyle(palette.secondaryText)
                        Spacer()
                        Text(String(format: "~%.0f C", telemetry.thermalLevel.approximateCelsiusBadge))
                            .font(.caption.bold().monospacedDigit())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(levelColor.opacity(0.16))
                            .foregroundStyle(levelColor)
                            .clipShape(Capsule())
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(palette.secondaryText)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }

                    HStack {
                        Text(statusTitle)
                            .font(.subheadline.bold())
                            .foregroundStyle(levelColor)
                        Spacer()
                        Text(L10n.text(.thermalTapHint, locale: locale))
                            .font(.caption2)
                            .foregroundStyle(palette.secondaryText)
                    }

                    TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: !animate)) { timeline in
                        let phase = animate
                            ? (timeline.date.timeIntervalSinceReferenceDate * (telemetry.thermalLevel == .nominal ? 0.6 : 1.3)).truncatingRemainder(dividingBy: 1.0)
                            : 0.5
                        GeometryReader { geo in
                            let fillWidth = max(geo.size.width * CGFloat(normalizedHeat), 10)
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(palette.background)
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [palette.accent, palette.warning, palette.danger],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: fillWidth)
                                    .overlay(
                                        Group {
                                            if animate {
                                                Capsule()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [.clear, Color.white.opacity(0.35), .clear],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                                    .frame(width: max(fillWidth * 0.32, 18))
                                                    .offset(x: CGFloat(phase) * max(fillWidth - 18, 1) - (fillWidth * 0.16))
                                            }
                                        }
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                        .frame(height: 8)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                Text(adviceText)
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Text(L10n.text(.thermalAlert, locale: locale))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.primaryText)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { thermalAlertEnabled },
                        set: { _ in onToggleThermalAlert() }
                    ))
                    .labelsHidden()
                    .tint(palette.accent)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: palette.cornerRadius, style: .continuous)
                .strokeBorder(isExpanded ? levelColor.opacity(0.6) : palette.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: palette.cornerRadius, style: .continuous))
    }
}
