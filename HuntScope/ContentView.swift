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
                HStack(spacing: 12) {
                    Button("Abbrechen") { ui.isDialogActive = false }
                        .buttonStyle(.bordered)
                        .tint(.red)

                    Button("Speichern") { ui.isDialogActive = false }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                }
                .padding(.top, 20)
                .padding(.leading, 8)
            },
            // Dialog-Inhalt (zentral ueber Stream)
            dialogContent: {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Konfiguration")
                        .font(.headline)
                        .foregroundStyle(.red)

                    Text("Hier kommt spaeter der eigentliche Dialoginhalt hin.")
                        .foregroundStyle(.white.opacity(0.9))

                    Button {
                        ui.isDialogActive = false
                    } label: {
                        Text("Schliessen").bold()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .padding(.top, 8)
                }
                .foregroundColor(.white)
            }
        )
        .background(Color.black)
        .ignoresSafeArea()
        // Zum Testen: Dialog toggeln per Tap mit zwei Fingern
        .simultaneousGesture(
            TapGesture(count: 2).onEnded { _ in ui.isDialogActive.toggle() }
        )
    }
    /*
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                //.foregroundStyle(.fill)
            Text("Hello, world!")
        }
        .padding()
        .ignoresSafeArea()

        
    }*/
}

#Preview {
    ContentView()
        .background(Color.black)

        
}
