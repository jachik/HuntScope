//
//  RightButtonArea.swift
//  HuntScope
//
//  Created by Jacek Schikora on 09.09.25.
//

// Datei: RightButtonArea.swift
import SwiftUI

struct RightButtonArea: View {
    @EnvironmentObject private var ui: UIStateModel
    @EnvironmentObject private var player: PlayerController
    @EnvironmentObject private var config: ConfigStore   // nur für Farben/Theme im SidebarButton

    private let spacing: CGFloat = 16

    var body: some View {
        VStack(spacing: spacing) {
            // Aufnahme an/aus (pulsiert, wenn Aufnahme läuft)
            SidebarButton(systemName: player.isRecording ? "stop.circle" : "record.circle",
                          pulsing: player.isRecording) {
                if player.isRecording {
                    player.stopRecording()
                } else {
                    player.startRecording()
                }
            }
            .disabled(!player.isConnected || ui.isDialogActive)
            

            // Snapshot
            SidebarButton(systemName: "camera") {
                player.takePhoto()
            }
            .disabled(!player.isConnected || ui.isDialogActive)
            

            // Play/Pause Stream
            SidebarButton(systemName: player.isPlaying ? "pause.circle" : "play.circle") {
                if player.isPlaying {
                    player.stop()
                } else {
                    player.play(urlString: config.streamURL) // nutzt deine gespeicherte URL
                }
            }
            .disabled(ui.isDialogActive)
            

            // Einstellungen (öffnet Konfigurationsdialog)
            SidebarButton(systemName: "gearshape") {
                ui.isDialogActive = true
            }
            // Einstellungen dürfen auch ohne Verbindung aufgehen
            .disabled(ui.isDialogActive) // verhindert mehrfach öffnen

            Spacer()
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}
