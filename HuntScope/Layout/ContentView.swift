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
    var body: some View {
        MainLayout(
            // Linke Dialog-Buttons (nur sichtbar, wenn Dialog aktiv)
            dialogButtons: {
                ConfigDialogButtons()
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
    }

}

#Preview {
    ContentView()
        .background(Color.black)

        
}
