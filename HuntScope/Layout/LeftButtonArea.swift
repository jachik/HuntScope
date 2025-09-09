//
//  LeftButtonArea.swift
//  HuntScope
//
//  Created by Jacek Schikora on 09.09.25.
//
import SwiftUI
import UIKit


// Linke Button-Area: kann von Dialogen mitbenutzt werden
struct LeftButtonArea<DialogButtons: View>: View {
    @EnvironmentObject private var config: ConfigStore
    let dialogButtons: DialogButtons
    let showDialogButtons: Bool

    init(showDialogButtons: Bool, @ViewBuilder dialogButtons: () -> DialogButtons) {
        self.showDialogButtons = showDialogButtons
        self.dialogButtons = dialogButtons()
    }

    var body: some View {
        VStack(spacing: 16) {
            // Beenden-Button (immer sichtbar, immer aktiv)
            SidebarButton(systemName: "power") {
                debugLog("Beenden gedrückt", "UI")
                // Versetzt die App in den Hintergrund (Apple-konformer als exit(0))
                UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
            }

            // Dialog-Buttons (falls ein Dialog aktiv ist)
            if showDialogButtons {
                dialogButtons
            }

            Spacer()
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}
