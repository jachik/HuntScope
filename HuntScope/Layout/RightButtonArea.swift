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

            // Oben in der Bottom-Sektion: Konfiguration
            SidebarButton(systemName: "gearshape") {
                ui.isDialogActive.toggle()
            }

            // Unten: Beenden (an Position der bisherigen Batterie)
            SidebarButton(systemName: "power") {
                debugLog("Beenden gedrückt", "UI")
                UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
            }
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}
