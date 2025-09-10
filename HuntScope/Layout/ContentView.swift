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
                case .rtspConfig:
                    RTSPConfigurationDialog()
                case .testConfig:
                    TestConfigView()
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
        .onChange(of: ui.isDialogActive) { active in
            // Stoppen beim Öffnen der Konfiguration, Starten nach Schließen
            if active {
                player.stop()
            } else if !config.streamURL.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    player.play(urlString: config.streamURL)
                }
            }
        }
    }

}

#Preview {
    ContentView()
        .background(Color.black)

        
}
