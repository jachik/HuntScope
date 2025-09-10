//
//  FirstLaunchPromptView.swift
//  HuntScope
//
//  Erststart-Hinweis mit Option zum automatischen Kamera-Scan.
//

import SwiftUI

struct FirstLaunchPromptView: View {
    @EnvironmentObject private var config: ConfigStore
    @EnvironmentObject private var ui: UIStateModel
    @EnvironmentObject private var wifi: WiFiInfoProvider

    @State private var showAutoConnect: Bool = false
    @State private var acState: AutoConnectState = .scanning
    @State private var cancelScan: Bool = false
    @State private var showWiFiAlert: Bool = false
    @State private var acTitleScanning: String? = nil
    @State private var acTitleSuccess: String? = nil
    @State private var acTitleNotFound: String? = nil

    private var message: String {
        "Du startest die App das erste Mal. Sollen wir deine Wärmebildkamera automatisch ermitteln? (Dafür musst du bereits mit dem WLAN der Kamera verbunden sein.)"
    }

    var body: some View {
        ZStack {
            DialogContainer(title: "Erststart", backgroundOpacity: 0.7, onClose: {
                // Nicht erneut anzeigen
                ConfigManager.shared.hasLaunchedBefore = true
                ui.activeDialog = nil
                ui.isDialogActive = false
            }) {
                VStack(spacing: 16) {
                    Text(message)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        Button {
                            // Nein => Dialog schließen und Flag setzen
                            ConfigManager.shared.hasLaunchedBefore = true
                            ui.activeDialog = nil
                            ui.isDialogActive = false
                        } label: {
                            Text("Nein, später")
                                .bold()
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.black)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke((config.theme == .red ? Color.red : Color.white), lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)

                        Button {
                            // Ja => Auto-Scan starten
                            if !wifi.snapshot.isWiFiConnected { showWiFiAlert = true; return }
                            startAutoConnect()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.badge.automatic")
                                Text("Ja, automatisch suchen")
                            }
                            //.font(system.weight.semibold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.black)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke((config.theme == .red ? Color.red : Color.white), lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Modal Overlay für Auto-Connect
            if showAutoConnect {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)

                AutoConnectDialog(state: acState,
                                  onCancel: {
                    cancelScan = true
                    showAutoConnect = false
                }, onClose: {
                    // Nach Ergebnis schließen und Flag setzen
                    showAutoConnect = false
                    ConfigManager.shared.hasLaunchedBefore = true
                    ui.activeDialog = nil
                    ui.isDialogActive = false
                },
                                  scanningTitle: acTitleScanning,
                                  successTitle: acTitleSuccess,
                                  notFoundTitle: acTitleNotFound)
                .environmentObject(config)
                .transition(.opacity)
            }

            // Modal Overlay für WLAN-Hinweis
            if showWiFiAlert {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)

                MessageDialog(title: "WLAN benötigt",
                               message: "Bitte WLAN aktivieren und mit Kamera verbinden.",
                               buttonTitle: "OK",
                               onClose: { showWiFiAlert = false })
                .environmentObject(config)
                .transition(.opacity)
            }
        }
    }
}

private extension FirstLaunchPromptView {
    func startAutoConnect() {
        acState = .scanning
        cancelScan = false
        showAutoConnect = true
        acTitleScanning = nil
        acTitleSuccess = nil
        acTitleNotFound = nil

        Task { @MainActor in
            let found = await RTSPScanner.scan(config: config, wifi: wifi, cancel: { self.cancelScan }, progress: nil)
            if let u = found {
                config.streamURL = u
                debugLog("Erreichbar: \(config.streamURL)", "RTSP")
                acState = .success
            } else {
                acState = .notFound
            }
        }
    }
}

