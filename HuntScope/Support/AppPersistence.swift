//
//  AppPersistence.swift
//  HuntScope
//
//  Utilities to wipe all persistent data for debug/testing.
//

import Foundation

enum AppPersistence {
    @MainActor
    static func resetAll(trial: TrialStore, entitlements: EntitlementStore) {
        // 1) Remove Keychain trial items
        KeychainHelper.deleteAllTrialItems()

        // 2) Clear premium entitlement cache in UserDefaults
        let ud = UserDefaults.standard
        ud.removeObject(forKey: "premium.active")
        ud.removeObject(forKey: "premium.exp")

        // 3) Reset app settings to defaults and remove persisted file
        ConfigManager.shared.resetToDefaults(deleteFile: true)

        // 4) Reset stream presets to bundle seed (remove Application Support file)
        StreamPresetManager.shared.resetToSeed()

        // 5) Refresh in-memory stores (trial + entitlements)
        //trial.initialize() // will set a fresh installDate and activate trial
        entitlements.loadCached()
        NotificationCenter.default.post(name: .premiumStatusChanged, object: nil, userInfo: ["active": false])
    }
}
