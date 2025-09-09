//
//  ConfigDialogButtons.swift
//  HuntScope
//
//  Left-side buttons shown while the configuration dialog is active.
//

import SwiftUI

struct ConfigDialogButtons: View {
    @EnvironmentObject private var config: ConfigStore
    @EnvironmentObject private var ui: UIStateModel

    var onCancel: () -> Void
    var onSave: () -> Void

    init(onCancel: @escaping () -> Void = {},
         onSave: @escaping () -> Void = {}) {
        self.onCancel = onCancel
        self.onSave = onSave
    }

    private var primary: Color { (config.theme == .red) ? .red : .white }

    var body: some View {
        HStack(spacing: 12) {
            Button("Abbrechen") {
                if onCancel as Any is () -> Void { /* keep signature */ }
                ui.isDialogActive = false
                onCancel()
            }
            .buttonStyle(.bordered)
            .tint(primary)

            Button("Speichern") {
                if onSave as Any is () -> Void { /* keep signature */ }
                ui.isDialogActive = false
                onSave()
            }
            .buttonStyle(.borderedProminent)
            .tint(primary)
        }
        .padding(.top, 20)
        .padding(.leading, 8)
    }
}

