import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import VoltGuardDomain

@MainActor
public final class LocalBatteryMonitor: ObservableObject {
    @Published public private(set) var level: Int = 100
    @Published public private(set) var isPluggedIn: Bool = false
    @Published public private(set) var isCharging: Bool = false
    @Published public private(set) var isLowPowerMode: Bool = false

    public init() {
        #if canImport(UIKit)
        UIDevice.current.isBatteryMonitoringEnabled = true
        refresh()
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        #else
        self.level = 88
        self.isPluggedIn = true
        self.isCharging = true
        #endif
    }

    public func refresh() {
        #if canImport(UIKit)
        let rawLevel = UIDevice.current.batteryLevel
        self.level = rawLevel >= 0 ? Int(rawLevel * 100.0) : 100
        let state = UIDevice.current.batteryState
        self.isPluggedIn = (state == .charging || state == .full)
        self.isCharging = (state == .charging)
        self.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        #else
        self.level = 88
        #endif
    }
}
