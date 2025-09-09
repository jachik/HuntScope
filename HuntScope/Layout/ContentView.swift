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
                HStack(spacing: 12) {
                    Button("Abbrechen") { ui.isDialogActive = false }
                        .buttonStyle(.bordered)
                        .tint(primary)

                    Button("Speichern") { ui.isDialogActive = false }
                        .buttonStyle(.borderedProminent)
                        .tint(primary)
                }
                .padding(.top, 20)
                .padding(.leading, 8)
            },
            // Dialog-Inhalt (zentral ueber Stream)
            dialogContent: {
                VStack(alignment: .center, spacing: 20) {
                    // Header
                    Text("Konfiguration")
                        .font(.title.weight(.bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(primary)

                    // Liste mit Optionen (Liste zentriert, Inhalte linksbündig)
                    VStack(alignment: .leading, spacing: 16) {
                        // Kamerakonfiguration
                        Button {
                            debugLog("Open camera configuration", "Settings")
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "camera")
                                    .font(.system(size: 50))
                                    .foregroundStyle(primary)
                                Text("Kamerakonfiguration")
                                    .font(.title2)
                                    .foregroundStyle(primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        // Abo-Konfiguration
                        Button {
                            debugLog("Open subscription configuration", "Settings")
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "lock.open.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(primary)
                                Text("HuntScope Premium freischalten")
                                    .font(.title2)
                                    .foregroundStyle(primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    // Liste als schmale Spalte in der Mitte ausrichten
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity, alignment: .center)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .center)
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
