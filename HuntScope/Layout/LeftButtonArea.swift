//
//  LeftButtonArea.swift
//  HuntScope
//
//  Created by Jacek Schikora on 09.09.25.
//
import SwiftUI


// Linke Button-Area: kann von Dialogen mitbenutzt werden
struct LeftButtonArea<DialogButtons: View>: View {
    let dialogButtons: DialogButtons
    let showDialogButtons: Bool

    init(showDialogButtons: Bool, @ViewBuilder dialogButtons: () -> DialogButtons) {
        self.showDialogButtons = showDialogButtons
        self.dialogButtons = dialogButtons()
    }

    var body: some View {
        VStack(spacing: 16) {
            // Platzhalter fuer linke Standard-Buttons (wenn kein Dialog)
            if !showDialogButtons {
                Button(action: {}) {
                    Image(systemName: "bolt.horizontal")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)

                Spacer()
            } else {
                // Wenn Dialog aktiv ist, zeigt die linke Spalte die Dialog-Buttons
                dialogButtons
                Spacer()
            }
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}
