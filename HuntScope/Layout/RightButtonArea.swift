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
    @StateObject private var battery = BatteryMonitor()

    private let spacing: CGFloat = 16

    var body: some View {
        VStack(spacing: spacing) {
            // MARK: Top section (from top down)

            SidebarButton(systemName: "paintbrush") {
                config.theme = (config.theme == .red) ? .white : .red
            }
            .disabled(ui.isDialogActive)

            SidebarButton(systemName: "camera") {
                player.takePhoto()
            }
            .disabled(!player.isConnected || ui.isDialogActive)

            SidebarButton(systemName: player.isRecording ? "stop.circle" : "record.circle",
                          pulsing: player.isRecording) {
                if player.isRecording {
                    player.stopRecording()
                } else {
                    player.startRecording()
                }
            }
            .disabled(!player.isConnected || ui.isDialogActive)

            Spacer()

            // MARK: Bottom section (from bottom up)

            SidebarButton(systemName: "gearshape") {
                ui.isDialogActive.toggle()
            }

            let primary = (config.theme == .red) ? Color.red : Color.white
            ZStack {
                Circle()
                    .stroke(primary, lineWidth: 2)
                Image(systemName: battery.symbolName)
                    .font(.title2)
                    .foregroundColor(primary)
                // Stromversorgung visuell kennzeichnen (egal ob laden oder voll)
                if battery.isPluggedIn {
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                        .foregroundColor(primary)
                        .offset(x: 12, y: -12)
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .allowsHitTesting(false)
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}
