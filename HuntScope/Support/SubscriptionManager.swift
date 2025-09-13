//
//  SubscriptionManager.swift
//  HuntScope
//
//  Lightweight StoreKit 2 wrapper for purchasing and restoring
//  a single Premium subscription. Product IDs are read from
//  Info.plist key "IAPProductIDs" (Array of String). Fallback
//  to a placeholder if none provided.
//

import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isBusy: Bool = false
    @Published var lastMessage: String? = nil

    // Reads product identifiers from Info.plist (Array<String> under key "IAPProductIDs").
    private var productIDs: [String] {
        if let ids = Bundle.main.object(forInfoDictionaryKey: "IAPProductIDs") as? [String], !ids.isEmpty {
            return ids
        }
        // Fallback placeholder; replace in Info.plist for production
        return ["com.example.huntscope.premium"]
    }

    func refreshProducts() async {
        do {
            let fetched = try await Product.products(for: productIDs)
            self.products = fetched.sorted(by: { $0.displayPrice < $1.displayPrice })
        } catch {
            self.lastMessage = String(localized: "_subscription_error_products_load")
        }
    }

    // Attempts to purchase the first available subscription product
    func purchasePremium() async {
        guard let product = products.first else {
            await refreshProducts()
            guard let p = products.first else {
                self.lastMessage = String(localized: "_subscription_error_no_products")
                return
            }
            await purchase(product: p)
            return
        }
        await purchase(product: product)
    }

    // Purchase specific product by identifier
    func purchase(productID: String) async {
        if let product = products.first(where: { $0.id == productID }) {
            await purchase(product: product)
        } else {
            await refreshProducts()
            if let product = products.first(where: { $0.id == productID }) {
                await purchase(product: product)
            } else {
                self.lastMessage = String(localized: "_subscription_error_product_not_found")
            }
        }
    }

    private func purchase(product: Product) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification { // VerificationResult<Transaction>
                case .verified(let transaction):
                    await transaction.finish()
                    self.lastMessage = String(localized: "_subscription_success_purchase")
                case .unverified:
                    self.lastMessage = String(localized: "_subscription_error_purchase_unverified")
                }
            case .userCancelled:
                self.lastMessage = String(localized: "_subscription_cancelled_purchase")
            case .pending:
                self.lastMessage = String(localized: "_subscription_pending_purchase")
            @unknown default:
                self.lastMessage = String(localized: "_subscription_unknown_purchase_result")
            }
        } catch {
            self.lastMessage = String(localized: "_subscription_error_purchase_failed")
        }
    }

    func restorePurchases() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            try await AppStore.sync()
            self.lastMessage = String(localized: "_subscription_success_restore")
        } catch {
            self.lastMessage = String(localized: "_subscription_error_restore_failed")
        }
    }
}
