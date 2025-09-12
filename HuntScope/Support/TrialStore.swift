//
//  TrialStore.swift
//  HuntScope
//
//  Tracks a local 30-day ad-free trial using Keychain.
//

import Foundation

@MainActor
final class TrialStore: ObservableObject {
    struct Keys {
        static let installDate = "installDate"
        static let trialEnded  = "trialEnded"
    }

    @Published private(set) var isActive: Bool = false
    @Published private(set) var daysLeft: Int = 0
    @Published private(set) var didSetInstallDateThisLaunch: Bool = false

    private let trialLength: TimeInterval = 30 * 24 * 60 * 60

    func initialize() {
        // Reset transient flag for this launch
        didSetInstallDateThisLaunch = false
        // Ensure install date exists; if not, set now and mark to show intro
        if KeychainHelper.getDouble(account: Keys.installDate) == nil {
            KeychainHelper.setDouble(Date().timeIntervalSince1970, account: Keys.installDate)
            didSetInstallDateThisLaunch = true
        }
        refreshStatus()
    }

    func refreshStatus(now: Date = Date()) {
        guard let ts = KeychainHelper.getDouble(account: Keys.installDate) else {
            // If for some reason missing, mark inactive and reset onboarding on next initialize
            isActive = false
            daysLeft = 0
            NotificationCenter.default.post(name: .trialStatusChanged, object: nil)
            return
        }
        let install = Date(timeIntervalSince1970: ts)
        let ended = KeychainHelper.getBool(account: Keys.trialEnded) ?? false
        if ended {
            isActive = false
            daysLeft = 0
        } else {
            let elapsed = now.timeIntervalSince(install)
            let remaining = max(0, trialLength - elapsed)
            isActive = remaining > 0
            daysLeft = Int(ceil(remaining / (24 * 60 * 60)))
            if !isActive {
                // Mark ended permanently
                KeychainHelper.setBool(true, account: Keys.trialEnded)
            }
        }
        NotificationCenter.default.post(name: .trialStatusChanged, object: nil)
    }
}

extension Notification.Name {
    static let trialStatusChanged = Notification.Name("TrialStatusChanged")
}
