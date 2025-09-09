//
//  BatteryMonitor.swift
//  HuntScope
//
//  Created by Codex on 09.09.25.
//

import SwiftUI
import UIKit

@MainActor
final class BatteryMonitor: ObservableObject {
    @Published private(set) var level: Float = UIDevice.current.batteryLevel
    @Published private(set) var state: UIDevice.BatteryState = UIDevice.current.batteryState

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        update()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateNotification(_:)),
                                               name: UIDevice.batteryLevelDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateNotification(_:)),
                                               name: UIDevice.batteryStateDidChangeNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func updateNotification(_ note: Notification) {
        update()
    }

    private func update() {
        level = UIDevice.current.batteryLevel // -1 if unknown
        state = UIDevice.current.batteryState
        // Debug output
        let pct: String = (level < 0) ? "unknown" : String(format: "%.0f%%", level * 100)
        let stateStr: String
        switch state {
        case .unknown:   stateStr = "unknown"
        case .unplugged: stateStr = "unplugged"
        case .charging:  stateStr = "charging"
        case .full:      stateStr = "full"
        @unknown default: stateStr = "unknown"
        }
        debugLog("level=\(pct) state=\(stateStr)", "Battery")

        objectWillChange.send()
    }

    // Maps battery level to 0/25/50/100 steps (4 Stufen)
    var symbolName: String {
        let l = max(0.0, min(1.0, Double(level)))
        let base: String
        switch l {
        case ..<0.125: base = "battery.0"
        case ..<0.5:   base = "battery.25"
        case ..<0.875: base = "battery.50"
        default:        base = "battery.100"
        }

        // Keep it simple: use plain level-based icons (no bolt overlay)
        return base
    }
}
