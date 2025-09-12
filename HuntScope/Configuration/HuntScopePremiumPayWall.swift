//
//  HuntScopePremiumPayWall.swift
//  HuntScope
//
//  Beispiel-Dialog, der den neuen DialogContainer nutzt.
//

import SwiftUI
import StoreKit
import UIKit

struct HuntScopePremiumPayWall: View {
    @EnvironmentObject private var ui: UIStateModel
    @EnvironmentObject private var config: ConfigStore
    @EnvironmentObject private var subscription: SubscriptionManager
    @EnvironmentObject private var entitlements: EntitlementStore

    private var primary: Color { (config.theme == .red) ? .red : .white }
    private let accent = Color.red
    @State private var selectedProductID: String? = nil
    @Environment(\.openURL) private var openURL

    var body: some View {
        DialogContainer(title: "_subscription_title", onClose: {
            ui.isDialogActive = false
            ui.activeDialog = nil
        }) {
            VStack(spacing: 18) {
                HStack { Spacer() }
                if entitlements.isPremiumActive {
                    // Premium aktiv -> Info + Abo verwalten
                    let exp = entitlements.expirationDate
                    Text(exp != nil ? String(format: String(localized: "_subscription_active_until"), DateFormatter.localizedString(from: exp!, dateStyle: .medium, timeStyle: .none)) : String(localized: "_subscription_active"))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(primary)
                        .padding(.top, 2)
                    HStack {
                        Spacer()
                        Button {
                            hapticTap()
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                openURL(url)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "gearshape")
                                    .font(.title2)
                                    .foregroundStyle(primary)
                                Text("_subscription_manage_button").bold()
                            }
                            .font(.title.weight(.semibold))
                            .foregroundStyle(primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.black)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(primary, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                } else {
                    // Kein Premium -> Vorteile-Box sofort anzeigen
                    HStack {
                        Spacer(minLength: 0)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("_subscription_benefits_title")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(primary)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(accent)
                                    Text("_subscription_benefit_adfree")
                                        .foregroundStyle(primary.opacity(0.9))
                                        .font(.subheadline)
                                }
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(accent)
                                    Text("_subscription_benefit_support")
                                        .foregroundStyle(primary.opacity(0.9))
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(15)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.black.opacity(0.6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(primary.opacity(0.6), lineWidth: 1)
                        )
                        //.frame(maxWidth: 520, alignment: .leading)
                        .frame(maxWidth: 520, alignment: .center)
                        Spacer(minLength: 0)
                    }
                    .padding(.bottom, 7)

                    // Plan-Auswahl (lädt ggf. später)
                    if subscription.products.isEmpty {
                        Text("_subscription_prices_loading")
                            .font(.body)
                            .foregroundStyle(primary.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 6)
                    } else {
                        // Abo-Optionen im passenden Rotton
                        VStack(alignment: .center, spacing: 10) {
                            Text("_subscription_select_plan")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(primary)
                            HStack(spacing: 10) {
                                ForEach(subscription.products, id: \.id) { p in
                                    let isSelected = (selectedProductID ?? subscription.products.first?.id) == p.id
                                    Button(action: {
                                        hapticSelection()
                                        selectedProductID = p.id
                                    }) {
                                        Text(planLabel(p))
                                            .font(.subheadline.weight(.semibold))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .frame(minWidth: 120)
                                            .background(isSelected ? accent : Color.clear)
                                            .foregroundStyle(isSelected ? Color.white : accent)
                                            .overlay(
                                                Capsule().stroke(accent, lineWidth: 1.5)
                                            )
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    // Premium freischalten + Käufe wiederherstellen adaptiv (nebeneinander oder zweizeilig)
                    //LazyVGrid(columns: actionGridColumns, alignment: .center, spacing: 12) {
                    HStack(alignment: .center) {
                        purchaseButton
                        restoreButton
                    }
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity)

                    if let msg = subscription.lastMessage {
                        Text(msg)
                            .font(.footnote)
                            .foregroundStyle(primary.opacity(0.85))
                            .padding(.top, 6)
                    }
                }

                Spacer(minLength: 4)
            }
            .task {
                await subscription.refreshProducts()
                // Bevorzugt Monats-Abo vorselektieren, falls vorhanden
                if let monthly = subscription.products.first(where: { $0.subscription?.subscriptionPeriod.unit == .month }) {
                    selectedProductID = monthly.id
                } else {
                    selectedProductID = subscription.products.first?.id
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

private extension HuntScopePremiumPayWall {
    var actionGridColumns: [GridItem] { [GridItem(.adaptive(minimum: 160), spacing: 12)] }
    var purchaseButton: some View {
        Button {
            hapticTap()
            Task {
                if let id = selectedProductID ?? subscription.products.first?.id {
                    await subscription.purchase(productID: id)
                } else {
                    await subscription.purchasePremium()
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundStyle(primary)
                Text("_subscription_purchase_button").bold()
            }
            .font(.title3.weight(.semibold))
            .foregroundStyle(primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(primary, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(subscription.isBusy)
    }

    var restoreButton: some View {
        Button {
            hapticTap()
            Task { await subscription.restorePurchases() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                    .foregroundStyle(primary)
                Text("_subscription_restore_button").bold()
            }
            .font(.title3.weight(.semibold))
            .foregroundStyle(primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(primary, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(subscription.isBusy)
    }
    func hapticTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    func hapticSelection() {
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.prepare()
        g.impactOccurred()
    }
    func planLabel(_ product: Product) -> String {
        let price = product.displayPrice
        if let unit = product.subscription?.subscriptionPeriod.unit {
            switch unit {
            case .month:
                return "\(price) \(String(localized: "_subscription_per_month"))"
            case .year:
                return "\(price) \(String(localized: "_subscription_per_year"))"
            case .day:
                return "\(price)/d"
            case .week:
                return "\(price)/w"
            @unknown default:
                return price
            }
        }
        return price
    }
}
