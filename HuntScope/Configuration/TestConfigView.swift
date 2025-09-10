//
//  TestConfigView.swift
//  HuntScope
//
//  Beispiel-Dialog, der den neuen DialogContainer nutzt.
//

import SwiftUI

struct TestConfigView: View {
    @EnvironmentObject private var ui: UIStateModel

    var body: some View {
        DialogContainer(title: "Test-Konfiguration", onClose: {
            ui.isDialogActive = false
            ui.activeDialog = nil
        }) {
            VStack(spacing: 12) {
                Text("Dies ist ein Test-Dialog auf Basis des DialogContainer.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                Text("Hier könnten deine spezifischen Einstellungen stehen.")
                    .font(.footnote)
                    .opacity(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

