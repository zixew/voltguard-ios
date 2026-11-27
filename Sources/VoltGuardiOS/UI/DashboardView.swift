import SwiftUI
import VoltGuardDomain
import VoltGuardNetwork

public struct DashboardView: View {
    @StateObject private var localBattery = LocalBatteryMonitor()
    @State private var theme: AppThemeID = .obsidianSlate
    @State private var selectedTab: Int = 0

    // Remote Mac State
    @State private var macTelemetry: BatteryTelemetry?
    @State private var macTargetLimit: Int = 80
    @State private var macManualDischarge: Bool = false
    @State private var isConnectingMac: Bool = false
    @State private var macConnected: Bool = true
    private let companionService = SimulatedMacCompanionService()

    public init() {}

    public var body: some View {
        let palette = ThemePalette.resolve(theme)

        NavigationStack {
            ZStack {
                palette.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        Picker("Device View", selection: $selectedTab) {
                            Text("Mac Companion").tag(0)
                            Text("iPhone Local").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        if selectedTab == 0 {
                            macCompanionView(palette: palette)
                        } else {
                            iphoneLocalView(palette: palette)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("VoltGuard")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        ForEach(AppThemeID.allCases, id: \.self) { t in
                            Button(t.rawValue.capitalized) {
                                withAnimation { theme = t }
                            }
                        }
                    } label: {
                        Image(systemName: "paintpalette.fill")
                            .foregroundStyle(palette.accent)
                    }
                }
            }
            .task {
                await refreshMacData()
            }
        }
    }

    @ViewBuilder
    private func macCompanionView(palette: ThemePalette) -> some View {
        VStack(spacing: 16) {
            // Hero Battery Card
            VStack(spacing: 12) {
                HStack {
                    Label("MacBook Pro (Living Room)", systemImage: "laptopcomputer")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(palette.primaryText)
                    Spacer()
                    Circle()
                        .fill(macConnected ? palette.accent : palette.danger)
                        .frame(width: 8, height: 8)
                    Text(macConnected ? "Synced" : "Offline")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(macConnected ? palette.accent : palette.secondaryText)
                }

                FluidBatteryWaveView(
                    percentage: macTelemetry?.percentage ?? 80,
                    isCharging: macTelemetry?.isCharging ?? true,
                    accentColor: palette.accent
                )
                .padding(.vertical, 6)

                if let t = macTelemetry {
                    HStack(spacing: 16) {
                        statPill(label: "Temp", value: String(format: "%.1f°C", t.temperatureCelsius), palette: palette)
                        statPill(label: "Power", value: String(format: "%.1fW", t.powerWatts), palette: palette)
                        statPill(label: "Health", value: "\(t.healthPercent)%", palette: palette)
                    }
                }
            }
            .padding()
            .background(palette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(palette.border, lineWidth: 1))
            .padding(.horizontal)

            // Mac Charge Limit Control
            VStack(alignment: .leading, spacing: 12) {
                Text("Mac Charging Limit")
                    .font(.headline)
                    .foregroundStyle(palette.primaryText)

                HStack(spacing: 10) {
                    ForEach([60, 80, 90, 100], id: \.self) { limit in
                        Button {
                            macTargetLimit = limit
                            applyMacPolicy()
                        } label: {
                            Text("\(limit)%")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(macTargetLimit == limit ? palette.accent : palette.background)
                                .foregroundStyle(macTargetLimit == limit ? .white : palette.primaryText)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }

                Toggle(isOn: $macManualDischarge) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Force Battery Discharge")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(palette.primaryText)
                        Text("Discharge Mac on AC power for calibration")
                            .font(.caption)
                            .foregroundStyle(palette.secondaryText)
                    }
                }
                .onChange(of: macManualDischarge) { _, _ in
                    applyMacPolicy()
                }
                .tint(palette.accent)
                .padding(.top, 4)
            }
            .padding()
            .background(palette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(palette.border, lineWidth: 1))
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func iphoneLocalView(palette: ThemePalette) -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                HStack {
                    Label("iPhone Battery Insights", systemImage: "iphone")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(palette.primaryText)
                    Spacer()
                    Text("UIDevice Active")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(palette.accent)
                }

                FluidBatteryWaveView(
                    percentage: localBattery.level,
                    isCharging: localBattery.isCharging,
                    accentColor: localBattery.level <= 20 ? palette.danger : palette.accent
                )
                .padding(.vertical, 6)

                HStack(spacing: 16) {
                    statPill(label: "State", value: localBattery.isPluggedIn ? (localBattery.isCharging ? "Charging" : "Full") : "Unplugged", palette: palette)
                    statPill(label: "Low Power", value: localBattery.isLowPowerMode ? "On" : "Off", palette: palette)
                }
            }
            .padding()
            .background(palette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(palette.border, lineWidth: 1))
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 10) {
                Text("Smart 80% Reminder")
                    .font(.headline)
                    .foregroundStyle(palette.primaryText)
                Text("Receive a chime notification when iPhone reaches 80% charge level to protect battery longevity.")
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryText)
            }
            .padding()
            .background(palette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(palette.border, lineWidth: 1))
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func statPill(label: String, value: String, palette: ThemePalette) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(palette.secondaryText)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(palette.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(palette.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func refreshMacData() async {
        isConnectingMac = true
        do {
            try await companionService.connect(host: "192.168.1.100", port: 8998)
            let t = try await companionService.fetchTelemetry()
            self.macTelemetry = t
            self.macConnected = true
        } catch {
            self.macConnected = false
        }
        isConnectingMac = false
    }

    private func applyMacPolicy() {
        Task {
            try? await companionService.updatePolicy(
                limitPercent: macTargetLimit,
                manualDischarge: macManualDischarge
            )
            await refreshMacData()
        }
    }
}
