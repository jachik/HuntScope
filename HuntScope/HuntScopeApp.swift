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
    @State private var showSplash: Bool = true
    @Environment(\.scenePhase) private var scenePhase
    @State private var adScheduler: InterstitialAdScheduler? = nil
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {

        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(configStore)
                    .environmentObject(uiState)
                    .environmentObject(player)
                    .preferredColorScheme(.dark)
                    .background(Color.black)
                    .statusBarHidden(true)

                if showSplash {
                    SplashView {


                        withAnimation(.easeOut(duration: 2)) {
                            showSplash = false
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
            }
            // Lifecycle: Splash bei Reaktivierung nach >= 30 min
            .onChange(of: scenePhase) { phase in
                switch phase {
                case .background:
                    let now = Date()
                    configStore.lastBackgroundAt = now
                    ConfigManager.shared.lastBackgroundAt = now
                    adScheduler?.handleScenePhase(.background)
                case .active:
                    if let last = configStore.lastBackgroundAt {
                        let elapsed = Date().timeIntervalSince(last)
                        if elapsed >= 30 * 60 {
                            showSplash = true
                        }
                    }
                    adScheduler?.handleScenePhase(.active)
                default:
                    break
                }
            }
        }
    }
}
