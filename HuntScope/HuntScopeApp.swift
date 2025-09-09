//
//  HuntScopeApp.swift
//  HuntScope
//
//  Created by Jacek Schikora on 08.09.25.
//

import SwiftUI
import UIKit

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
    @State private var showSplash: Bool = true
    @Environment(\.scenePhase) private var scenePhase
    
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
            // Lifecycle: Splash bei Reaktivierung nach >= 30 min
            .onChange(of: scenePhase) { phase in
                switch phase {
                case .background:
                    let now = Date()
                    configStore.lastBackgroundAt = now
                    ConfigManager.shared.lastBackgroundAt = now
                case .active:
                    if let last = configStore.lastBackgroundAt {
                        let elapsed = Date().timeIntervalSince(last)
                        if elapsed >= 30 * 60 {
                            showSplash = true
                        }
                    }
                default:
                    break
                }
            }
        }
    }
}
