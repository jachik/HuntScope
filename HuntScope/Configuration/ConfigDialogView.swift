//
//  ConfigDialogView.swift
//  HuntScope
//
//  Extracted configuration dialog content for maintainability.
//

import SwiftUI

struct ConfigDialogView: View {
    @EnvironmentObject private var config: ConfigStore

    var onOpenCamera: () -> Void
    var onOpenSubscription: () -> Void

    init(onOpenCamera: @escaping () -> Void = {debugLog("Open camera configuration", "Settings")},
         onOpenSubscription: @escaping () -> Void = { debugLog("Open subscription configuration", "Settings") }) {
        self.onOpenCamera = onOpenCamera
        self.onOpenSubscription = onOpenSubscription
    }

    private var primary: Color { (config.theme == .red) ? .red : .white }

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            // Header
            Text("Konfiguration")
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(primary)

            // Liste mit Optionen (zentrierte Spalte, linksbündige Items)
            VStack(alignment: .leading, spacing: 16) {
                // Kamerakonfiguration
                Button(action: onOpenCamera) {
                    HStack(spacing: 16) {
                        Image(systemName: "camera")
                            .font(.system(size: 50))
                            .foregroundStyle(primary)
                        Text("Kamerakonfiguration")
                            .font(.title2)
                            .foregroundStyle(primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Abo-Konfiguration
                Button(action: onOpenSubscription) {
                    HStack(spacing: 16) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(primary)
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

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .foregroundColor(primary)
    }
}
