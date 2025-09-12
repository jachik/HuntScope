//
//  LeftButtonArea.swift
//  HuntScope
//
//  Created by Jacek Schikora on 09.09.25.
//
import SwiftUI
import UIKit


// Linke Button-Area: zeigt nur Status-Symbole (keine Interaktion)
struct LeftButtonArea<DialogButtons: View>: View {
    @EnvironmentObject private var config: ConfigStore
    @EnvironmentObject private var ui: UIStateModel
    @EnvironmentObject private var entitlements: EntitlementStore
    @EnvironmentObject private var trial: TrialStore
    @StateObject private var battery = BatteryMonitor()
    let dialogButtons: DialogButtons // ignoriert (keine Dialog-Buttons mehr links)
    let showDialogButtons: Bool      // ignoriert

    init(showDialogButtons: Bool, @ViewBuilder dialogButtons: () -> DialogButtons) {
        self.showDialogButtons = showDialogButtons
        self.dialogButtons = dialogButtons()
    }

    var body: some View {
        return VStack(spacing: 16) {
            // Batterie-Status (optisch wie SidebarButton, aber nicht klickbar)
            SidebarButton(pulsing: false, action: {}) {
                ZStack {
                    Image(systemName: battery.symbolName)
                    if battery.isPluggedIn {
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                            .offset(x: 12, y: -12)
                    }
                }
            }
            // Dimm-Verhalten wie rechts: nur bei aktivem Dialog deaktiviert
            .disabled(ui.isDialogActive)
            // Keine Interaktion zulassen
            .allowsHitTesting(false)

            Spacer()

            // Temporärer Test-Button (nur Debug): zeigt internen AdDialog
            #if DEBUG
            SidebarButton(systemName: "megaphone.fill") {
                if let id = InternalAdProvider.chooseRandomAdID(range: 1...10) {
                    ui.internalAdID = id
                    ui.isAdDialogPresented = true
                } else {
                    // Fallback: dennoch Dialog mit ad01, falls vorhanden
                    ui.internalAdID = "ad01"
                    ui.isAdDialogPresented = true
                }
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 1.2)
                    .onEnded { _ in
                        Task { @MainActor in
                            AppPersistence.resetAll(trial: trial, entitlements: entitlements)
                            debugLog("All persistence wiped (Keychain, Settings, Presets).", "Debug")
                            // Nach dem Reset die App beenden/suspendieren
                            UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
                        }
                    }
            )
            .disabled(ui.isDialogActive || ui.isAdDialogPresented)
            #endif
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}
