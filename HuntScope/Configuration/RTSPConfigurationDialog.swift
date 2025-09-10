//
//  RTSPStreamConfigView.swift
//  HuntScope
//
//  Stream-spezifische Konfiguration im gleichen Stil wie ConfigDialogView.
//

import SwiftUI

struct RTSPConfigurationDialog: View {
    @EnvironmentObject private var config: ConfigStore
    @EnvironmentObject private var ui: UIStateModel
    @EnvironmentObject private var player: PlayerController
    @EnvironmentObject private var wifi: WiFiInfoProvider

    private var primary: Color { (config.theme == .red) ? .red : .white }

    @State private var testResult: String? = nil
    @State private var showManual: Bool = false
    @State private var showAutoConnect: Bool = false
    @State private var acState: AutoConnectState = .scanning
    @State private var showWiFiAlert: Bool = false
    @State private var candidates: [String] = []

    var body: some View {
        DialogContainer(title: "Stream-Konfiguration", backgroundOpacity: 0.7, onClose: {
            ui.isDialogActive = false
            ui.activeDialog = nil
        }) {
            ZStack {
                VStack(alignment: .leading, spacing: 16) {
                Spacer(minLength: 20)
                // Auto-Connect (zentriert)
                HStack {
                    Spacer()
                    Button {
                        if !wifi.snapshot.isWiFiConnected { showWiFiAlert = true; return }
                        debugLog("Auto-Connect pressed", "RTSPConfig")
                        startAutoConnect()
                    } label: {
                        HStack() {
                            Image(systemName: "bolt.badge.automatic")
                                .font(.title2)
                                .foregroundStyle(primary)
                            Text("Auto-Connect").bold()
 
                        }
                        .font(.title.weight(.semibold))
                        .foregroundStyle(primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(primary, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                Spacer(minLength: 20)


                // Toggle-Bereich: Manuelle Konfiguration
                VStack(spacing: 10) {
                    ZStack {
                        Divider().overlay(Color.clear)
                        HStack {
                            Spacer()
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) { showManual.toggle() }
                            } label: {
                                HStack(spacing: 6) {
                                    Text("Manuelle Konfiguration")
                                    Image(systemName: showManual ? "chevron.up" : "chevron.down")
                                }
                                .font(.body.weight(.semibold))
                                //.font(.system(size: 20, weight: .light, design: .default))
                                .foregroundStyle(primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.25))
                                .overlay(
                                    Capsule().stroke(primary.opacity(0.6), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                    }

                    if showManual {
                        VStack(alignment: .leading, spacing: 8) {
                            Spacer(minLength: 7)
                            Text("Kamera-URL (in der Form rtsp://IP/Ressource)")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(primary.opacity(0.9))

                            HStack(spacing: 12) {
                                TextField("rtsp://…", text: Binding(
                                    get: { config.customStreamURL },
                                    set: { config.customStreamURL = $0 }
                                ))
                                .font(.body.weight(.semibold))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .foregroundStyle(primary)
                                .padding(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(primary.opacity(0.6), lineWidth: 1)
                                )
                                Spacer(minLength: 10)
                                Button {
                                    if !wifi.snapshot.isWiFiConnected { showWiFiAlert = true; return }
                                    let url = config.customStreamURL.trimmingCharacters(in: .whitespacesAndNewlines)
                                    debugLog("Test custom URL: \(url)", "RTSPConfig")
                                    if !url.isEmpty {
                                        player.play(urlString: url)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            player.stop()
                                            testResult = "Test ausgelöst"
                                        }
                                    }
                                } label: {
                                    Text("Verbindungstest").bold()
                                        .foregroundStyle(primary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.black)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().stroke(primary, lineWidth: 1.5)
                                        )
                                }
                                .buttonStyle(.plain)
                            }

                            if let testResult {
                                Text(testResult)
                                    .font(.footnote)
                                    .foregroundStyle(primary.opacity(0.8))
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }

                }

                // Modal Overlay für Auto-Connect
                if showAutoConnect {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    AutoConnectDialog(state: acState, onCancel: {
                        showAutoConnect = false
                    }, onClose: {
                        showAutoConnect = false
                    })
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
}

// MARK: - Auto-Connect (Stub)
extension RTSPConfigurationDialog {
    private func startAutoConnect() {
        // Baue Kandidatenliste (Vollscan)
        let list = RTSPScanner.buildCandidates(short: false, config: config, wifi: wifi)
        candidates = list
        debugLog("AutoConnect candidates=\(list.count)", "RTSP")
        for (idx, url) in list.prefix(10).enumerated() {
            debugLog("#\(idx+1): \(url)", "RTSP")
        }

        acState = .scanning
        showAutoConnect = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if Bool.random() {
                acState = .success
            } else {
                acState = .notFound
            }
        }
    }
}
