//
//  ConfigDialogView.swift
//  HuntScope
//
//  Extracted configuration dialog content for maintainability.
//

import SwiftUI

struct ConfigDialogView: View {
    @EnvironmentObject private var config: ConfigStore
    @EnvironmentObject private var ui: UIStateModel

    var onOpenCamera: () -> Void
    var onOpenSubscription: () -> Void

    init(onOpenCamera: @escaping () -> Void = {debugLog("Open camera configuration", "Settings")},
         onOpenSubscription: @escaping () -> Void = { debugLog("Open subscription configuration", "Settings") }) {
        self.onOpenCamera = onOpenCamera
        self.onOpenSubscription = onOpenSubscription
    }

    private var primary: Color { (config.theme == .red) ? .red : .white }

    var body: some View {
        DialogContainer(title: "Konfiguration", backgroundOpacity: 0.2, onClose: {
            ui.isDialogActive = false
            ui.activeDialog = nil
        }) {
            // Liste mit Optionen (zentrierte Spalte, linksbündige Items)
            VStack(alignment: .leading, spacing: 16) {
                // Kamerakonfiguration
                Button(action: { ui.activeDialog = .rtspConfig }) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle().stroke(primary, lineWidth: 2)
                            Image(systemName: "camera")
                                .font(.system(size: 35))
                                .foregroundStyle(primary)
                        }
                        .frame(width: 66, height: 66)
                        Text("Kamerakonfiguration")
                            .font(.title2)
                            .foregroundStyle(primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Abo-Konfiguration -> öffnet TestConfig-Dialog
                Button(action: { ui.activeDialog = .testConfig }) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle().stroke(primary, lineWidth: 2)
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 35))
                                .foregroundStyle(primary)
                        }
                        .frame(width: 66, height: 66)
                        Text("HuntScope Premium freischalten")
                            .font(.title2)
                            .foregroundStyle(primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
