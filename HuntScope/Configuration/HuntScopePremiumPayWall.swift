//
//  HuntScopePremiumPayWall.swift
//  HuntScope
//
//  Beispiel-Dialog, der den neuen DialogContainer nutzt.
//

import SwiftUI
import StoreKit

struct HuntScopePremiumPayWall: View {
    @EnvironmentObject private var ui: UIStateModel
    @EnvironmentObject private var config: ConfigStore
    @EnvironmentObject private var subscription: SubscriptionManager
    @EnvironmentObject private var entitlements: EntitlementStore

    private var primary: Color { (config.theme == .red) ? .red : .white }
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
                    // Kein Premium -> Plan-Auswahl, Kauf, Restore
                    if subscription.products.isEmpty {
                        Text("_subscription_prices_loading")
                            .font(.body)
                            .foregroundStyle(primary.opacity(0.8))
                    } else {
                        VStack(alignment: .center, spacing: 10) {
                            Text("_subscription_select_plan")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(primary)
                            Picker("", selection: Binding(get: {
                                selectedProductID ?? subscription.products.first?.id
                            }, set: { newID in
                                selectedProductID = newID
                            })) {
                                ForEach(subscription.products, id: \.id) { p in
                                    Text(planLabel(p)).tag(Optional(p.id))
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    // Premium freischalten
                    HStack {
                        Spacer()
                        Button {
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
                        .disabled(subscription.isBusy)
                        Spacer()
                    }

                    // Käufe wiederherstellen
                    HStack {
                        Spacer()
                        Button {
                            Task { await subscription.restorePurchases() }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title2)
                                    .foregroundStyle(primary)
                                Text("_subscription_restore_button").bold()
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
                        .disabled(subscription.isBusy)
                        Spacer()
                    }

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
