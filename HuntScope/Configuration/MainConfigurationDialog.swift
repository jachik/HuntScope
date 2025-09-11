//
//  ConfigDialogView.swift
//  HuntScope
//
//  Extracted configuration dialog content for maintainability.
//

import SwiftUI

struct MainConfigurationDialog: View {
    @EnvironmentObject private var config: ConfigStore
    @EnvironmentObject private var ui: UIStateModel
    @EnvironmentObject private var entitlements: EntitlementStore

    var onOpenCamera: () -> Void
    var onOpenSubscription: () -> Void

    init(onOpenCamera: @escaping () -> Void = {debugLog("Open camera configuration", "Settings")},
         onOpenSubscription: @escaping () -> Void = { debugLog("Open subscription configuration", "Settings") }) {
        self.onOpenCamera = onOpenCamera
        self.onOpenSubscription = onOpenSubscription
    }

    private var primary: Color { (config.theme == .red) ? .red : .white }

    var body: some View {
        DialogContainer(title: "_configuration_title", backgroundOpacity: 0.2, onClose: {
            ui.isDialogActive = false
            ui.activeDialog = nil
        }) {
            // Liste mit Optionen (zentrierte Spalte, linksbündige Items)
            VStack(alignment: .leading, spacing: 26) {
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
                        Text("_camera_configuration")
                            .font(.title2)
                            .foregroundStyle(primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                //Spacer(minLength: 10)
                
                // Abo-Konfiguration / Paywall (immer anklickbar)
                Button(action: { ui.activeDialog = .testConfig }) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle().stroke(primary, lineWidth: 2)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 35))
                                .foregroundStyle(primary)
                        }
                        .frame(width: 66, height: 66)
                        Text("_huntscope_premium")
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
            
            // Impressum unterhalb der Liste
            VStack(spacing: 8) {
                Divider()
                    .overlay(primary.opacity(0.5))
                    .padding(.vertical, 8)
                Text("_imprint_title")
                    .font(.title.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(primary)
                Spacer(minLength: 5)
                
                let legal = String(localized: "_imprint_body")
                Text(legal)
                    .font(.body)
                    .foregroundStyle(primary.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity, alignment: .center)
            
            VStack(spacing: 8) {
                Divider()
                    .overlay(primary.opacity(0.5))
                    .padding(.vertical, 8)
                Text("_dsgvo_title")
                    .font(.title.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(primary)
                //Link("Zum Öffnen der Datenschutzerklärung im Browser bitte hier klicken",
                Link("_dsgvo_body",
                     destination: URL(string: "https://s5j.de/huntscope_datenschutz.html")!)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(primary.opacity(0.9))
            }
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
