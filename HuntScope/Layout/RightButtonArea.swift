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
            .accessibilityLabel(Text("_a11y_layout_btn_theme_label"))
            .accessibilityHint(Text("_a11y_layout_btn_theme_hint"))

            SidebarButton(systemName: "camera") {
                player.takePhoto()
            }
            .disabled(!player.hasStreamSignal || ui.isDialogActive)
            .accessibilityLabel(Text("_a11y_layout_btn_camera_label"))
            .accessibilityHint(Text("_a11y_layout_btn_camera_hint"))

            SidebarButton(systemName: (player.isRecording ? (recordFlashOn ? "record.circle.fill" : "record.circle") : "record.circle"),
                          pulsing: player.isRecording) {
                if player.isRecording {
                    player.stopRecording()
                } else {
                    player.startRecording()
                }
            }
            .disabled(!player.hasStreamSignal || ui.isDialogActive)
            .accessibilityLabel(Text(player.isRecording ? "_a11y_layout_btn_record_label_stop" : "_a11y_layout_btn_record_label_start"))
            .accessibilityValue(Text(player.isRecording ? "_a11y_layout_btn_record_value_on" : "_a11y_layout_btn_record_value_off"))
            .accessibilityHint(Text(player.isRecording ? "_a11y_layout_btn_record_hint_stop" : "_a11y_layout_btn_record_hint_start"))
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
            .accessibilityLabel(Text("_a11y_layout_btn_settings_label"))
            .accessibilityHint(Text("_a11y_layout_btn_settings_hint"))

            // Unten: Beenden (an Position der bisherigen Batterie)
            SidebarButton(systemName: "power") {
                debugLog("Beenden gedrückt", "UI")
                UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
            }
            .disabled(ui.isDialogActive)
            .accessibilityLabel(Text("_a11y_layout_btn_quit_label"))
            .accessibilityHint(Text("_a11y_layout_btn_quit_hint"))
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}
