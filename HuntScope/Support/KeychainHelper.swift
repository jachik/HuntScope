//
//  KeychainHelper.swift
//  HuntScope
//
//  Minimal helper for storing trial metadata securely on-device.
//

import Foundation
import Security

enum KeychainHelper {
    private static var service: String {
        let base = Bundle.main.bundleIdentifier ?? "HuntScope"
        return base + ".trial"
    }

    static func set(_ data: Data, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let attrs: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            _ = SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    static func get(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &out)
        guard status == errSecSuccess else { return nil }
        return out as? Data
    }

    static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func deleteAllTrialItems() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }
}

extension KeychainHelper {
    static func setDouble(_ value: Double, account: String) {
        var v = value
        let data = Data(bytes: &v, count: MemoryLayout<Double>.size)
        set(data, account: account)
    }

    static func getDouble(account: String) -> Double? {
        guard let data = get(account: account) else { return nil }
        guard data.count == MemoryLayout<Double>.size else { return nil }
        return data.withUnsafeBytes { $0.load(as: Double.self) }
    }

    static func setBool(_ value: Bool, account: String) {
        set(Data([value ? 1 : 0]), account: account)
    }

    static func getBool(account: String) -> Bool? {
        guard let data = get(account: account), let byte = data.first else { return nil }
        return byte != 0
    }
}
