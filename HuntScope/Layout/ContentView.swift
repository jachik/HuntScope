//
//  ContentView.swift
//  HuntScope
//
//  Created by Jacek Schikora on 08.09.25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var ui: UIStateModel
    @EnvironmentObject var config: ConfigStore
    @EnvironmentObject var player: PlayerController
    var body: some View {
        MainLayout(
            // Linke Dialog-Buttons (derzeit ungenutzt)
            dialogButtons: {
                EmptyView()
            },
            // Dialog-Inhalt (zentral ueber Stream)
            dialogContent: {
                switch ui.activeDialog {
                case .firstLaunch:
                    FirstLaunchPromptView()
                case .rtspConfig:
                    RTSPConfigurationDialog()
                case .testConfig:
                    HuntScopePremiumPayWall()
                default:
                    MainConfigurationDialog()
                }
            }
        )
        .background(Color.black)
        .ignoresSafeArea()
        .onAppear {
            // Auto-Start beim Start der UI
            if !ui.isDialogActive, !config.streamURL.isEmpty {
                player.play(urlString: config.streamURL)
            }
        }
        .onChange(of: ui.isDialogActive) { _ in
            // Dialoge beeinflussen den Stream nicht mehr: Wiedergabe läuft weiter.
        }
        // Reagiere auf geänderte Stream-URL: sofort neu verbinden
        .onChange(of: config.streamURL) { newURL in
            let url = newURL.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !url.isEmpty else { return }
            player.play(urlString: url)
        }
    }

}

#Preview {
    ContentView()
        .background(Color.black)

        
}
