//
//  RightButtonArea.swift
//  HuntScope
//
//  Created by Jacek Schikora on 09.09.25.
//

// Datei: RightButtonArea.swift
import SwiftUI
import Combine

struct RightButtonArea: View {
    @EnvironmentObject private var ui: UIStateModel
    @EnvironmentObject private var player: PlayerController
    @EnvironmentObject private var config: ConfigStore   // nur für Farben/Theme im SidebarButton
    @StateObject private var battery = BatteryMonitor()

    private let spacing: CGFloat = 16
    @State private var recordFlashOn: Bool = false

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
            .disabled(!player.hasStreamSignal || ui.isDialogActive)

            SidebarButton(systemName: (player.isRecording ? (recordFlashOn ? "record.circle.fill" : "record.circle") : "record.circle"),
                          pulsing: player.isRecording) {
                if player.isRecording {
                    player.stopRecording()
                } else {
                    player.startRecording()
                }
            }
            .disabled(!player.hasStreamSignal || ui.isDialogActive)
            // Blink-Animation waehrend Aufnahme
            .onReceive(Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()) { _ in
                if player.isRecording {
                    withAnimation(.easeInOut(duration: 0.25)) { recordFlashOn.toggle() }
                } else if recordFlashOn {
                    recordFlashOn = false
                }
            }

            Spacer()

            // MARK: Bottom section (from bottom up)

            // Oben in der Bottom-Sektion: Konfiguration
            SidebarButton(systemName: "gearshape") {
                ui.activeDialog = .mainConfig
                ui.isDialogActive = true
            }
            .disabled(ui.isDialogActive)

            // Unten: Beenden (an Position der bisherigen Batterie)
            SidebarButton(systemName: "power") {
                debugLog("Beenden gedrückt", "UI")
                UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
            }
            .disabled(ui.isDialogActive)
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}
