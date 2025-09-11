//
//  HuntScopeApp.swift
//  HuntScope
//
//  Created by Jacek Schikora on 08.09.25.
//

import SwiftUI
import UIKit
import GoogleMobileAds


@main
struct HuntScopeApp: App {
    init() {
        // sorgt dafür, dass auch UIKit-Backgrounds schwarz sind
        UIWindow.appearance().backgroundColor = .black
        // Batterie-Überwachung global aktivieren, damit Level/State verfügbar sind
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    @StateObject private var configStore = ConfigStore()
    @StateObject private var uiState = UIStateModel()
    @StateObject private var player      = PlayerController()
    @StateObject private var interstitialVM = InterstitialViewModel()
    @StateObject private var subscription = SubscriptionManager()
    @StateObject private var entitlements: EntitlementStore = {
        let ids = (Bundle.main.object(forInfoDictionaryKey: "IAPProductIDs") as? [String]) ?? [
            "jsedv.local.HuntScope",
            "jsedv.local.HuntScope1Y"
        ]
        return EntitlementStore(productIDs: ids)
    }()
    @StateObject private var wifi = WiFiInfoProvider()
    @State private var showSplash: Bool = true
    @Environment(\.scenePhase) private var scenePhase
    @State private var adScheduler: InterstitialAdScheduler? = nil
    @State private var wasBackgrounded: Bool = false
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {

        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(configStore)
                    .environmentObject(uiState)
                    .environmentObject(player)
                    .environmentObject(wifi)
                    .environmentObject(subscription)
                    .environmentObject(entitlements)
                    .preferredColorScheme(.dark)
                    .background(Color.black)
                    .statusBarHidden(true)

                if showSplash {
                    SplashView {
                        withAnimation(.easeOut(duration: 2)) {
                            showSplash = false
                        }
                        // Erststart-Dialog direkt nach Splash
                        if ConfigManager.shared.hasLaunchedBefore == false {
                            uiState.activeDialog = .firstLaunch
                            uiState.isDialogActive = true
                        }
                    }
                    .environmentObject(uiState)
                    .environmentObject(configStore)
                    .environmentObject(player)
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .onAppear {
                if adScheduler == nil {
                    let scheduler = InterstitialAdScheduler(interstitial: interstitialVM, ui: uiState, player: player)
                    scheduler.start()
                    adScheduler = scheduler
                    // Initial preload (safety)
                    Task { await interstitialVM.loadAd() }
                }
                // Start WiFi monitoring
                wifi.start()
                // Load cached entitlement and refresh from App Store
                entitlements.loadCached()
                Task { await entitlements.refreshOnce() }
                entitlements.start()
            }
            // Lifecycle: Splash bei Reaktivierung nach >= 30 min
            .onChange(of: scenePhase) { phase in
                switch phase {
                case .background:
                    let now = Date()
                    configStore.lastBackgroundAt = now
                    ConfigManager.shared.lastBackgroundAt = now
                    adScheduler?.handleScenePhase(.background)
                    wifi.stop()
                    wasBackgrounded = true
                case .active:
                    if wasBackgrounded {
                        if let last = configStore.lastBackgroundAt {
                            let elapsed = Date().timeIntervalSince(last)
                            if elapsed >= 30 * 60 {
                                showSplash = true
                            }
                        }
                        wasBackgrounded = false
                    }
                    adScheduler?.handleScenePhase(.active)
                    wifi.start()
                default:
                    break
                }
            }
        }
    }
}
