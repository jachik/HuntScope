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
    }
    @StateObject private var configStore = ConfigStore()
    @StateObject private var uiState = UIStateModel()
    @StateObject private var player      = PlayerController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(configStore)
                .environmentObject(uiState)
                .environmentObject(player)
                .preferredColorScheme(.dark)
                .background(Color.black)
                .statusBarHidden(true)
        }
    }
}
