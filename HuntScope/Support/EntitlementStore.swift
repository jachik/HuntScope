//
//  EntitlementStore.swift
//  HuntScope
//
//  Tracks Premium subscription state using StoreKit 2.
//

import Foundation
import StoreKit

@MainActor
final class EntitlementStore: ObservableObject {
    @Published private(set) var isPremiumActive: Bool = false
    @Published private(set) var expirationDate: Date? = nil

    private let productIDs: [String]
    private var updatesTask: Task<Void, Never>? = nil

    init(productIDs: [String]) {
        self.productIDs = productIDs
    }

    func loadCached() {
        isPremiumActive = UserDefaults.standard.bool(forKey: "premium.active")
        if let ts = UserDefaults.standard.object(forKey: "premium.exp") as? Double, ts > 0 {
            expirationDate = Date(timeIntervalSince1970: ts)
        } else {
            expirationDate = nil
        }
    }

    func start() {
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            guard let self else { return }
            for await vr in Transaction.updates {
                await self.handleUpdate(vr)
            }
        }
    }

    func stop() {
        updatesTask?.cancel()
        updatesTask = nil
    }

    func refreshOnce() async {
        var active = false
        var latestExp: Date? = nil

        for id in productIDs {
            if let vr = await Transaction.latest(for: id) {
                if case .verified(let t) = vr {
                    let notRevoked = (t.revocationDate == nil)
                    let exp = t.expirationDate ?? .distantFuture
                    let valid = exp > Date() && !t.isUpgraded
                    if notRevoked && valid {
                        active = true
                        if let e = t.expirationDate {
                            if latestExp == nil || e > latestExp! { latestExp = e }
                        }
                    }
                }
            }
        }
        apply(active: active, expiration: latestExp)
    }

    private func handleUpdate(_ vr: VerificationResult<Transaction>) async {
        // Recompute state on any transaction change
        await refreshOnce()
    }

    private func apply(active: Bool, expiration: Date?) {
        let changed = (active != isPremiumActive) || (expiration?.timeIntervalSince1970 != expirationDate?.timeIntervalSince1970)
        isPremiumActive = active
        expirationDate = expiration
        if changed {
            UserDefaults.standard.set(active, forKey: "premium.active")
            if let expiration { UserDefaults.standard.set(expiration.timeIntervalSince1970, forKey: "premium.exp") }
            else { UserDefaults.standard.removeObject(forKey: "premium.exp") }
            NotificationCenter.default.post(name: .premiumStatusChanged,
                                            object: nil,
                                            userInfo: ["active": active, "expiration": expiration as Any])
        }
    }
}

extension Notification.Name {
    static let premiumStatusChanged = Notification.Name("PremiumStatusChanged")
}

