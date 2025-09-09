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
        let primary = (config.theme == .red) ? Color.red : Color.white
        return MainLayout(
            // Linke Dialog-Buttons (nur sichtbar, wenn Dialog aktiv)
            dialogButtons: {
                HStack(spacing: 12) {/*
                    Button("Abbrechen") { ui.isDialogActive = false }
                        .buttonStyle(.bordered)
                        .tint(primary)

                    Button("Speichern") { ui.isDialogActive = false }
                        .buttonStyle(.borderedProminent)
                        .tint(primary)*/
                }
                .padding(.top, 20)
                .padding(.leading, 8)
            },
            // Dialog-Inhalt (zentral ueber Stream)
            dialogContent: {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Konfiguration")
                        .font(.headline)
                        .foregroundStyle(primary)

                    // Weiß->Rot Mapping im Red-Theme
                    let themedWhite = (config.theme == .red) ? Color.red : Color.white
                    Text("Hier kommt spaeter der eigentliche Dialoginhalt hin.")
                        .foregroundStyle(themedWhite.opacity(0.9))

                    Button {
                        ui.isDialogActive = false
                    } label: {
                        Text("Schliessen").bold()
                    }
                    .buttonStyle(.bordered)
                    .tint(primary)
                    .padding(.top, 8)
                }
                // Weiß->Rot Mapping im Red-Theme
                .foregroundColor(primary)
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
