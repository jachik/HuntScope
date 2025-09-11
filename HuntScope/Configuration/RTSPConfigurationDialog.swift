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
    @State private var cancelScan: Bool = false
    @State private var acTitleScanning: String? = nil
    @State private var acTitleSuccess: String? = nil
    @State private var acTitleNotFound: String? = nil

    var body: some View {
        DialogContainer(title: "_configuration_stream_title", backgroundOpacity: 0.7, onClose: {
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
                            Text("_configuration_auto_connect").bold()

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
                                    Text("_configuration_manual_configuration")
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
                            Text("_configuration_camera_url_label")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(primary.opacity(0.9))

                            HStack(spacing: 12) {
                                TextField(String(localized: "_configuration_camera_url_placeholder"), text: Binding(
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
                                    testCustomURL()
                                } label: {
                                    Text("_configuration_connection_test").bold()
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

                    AutoConnectDialog(state: acState,
                                      onCancel: {
                        cancelScan = true
                        showAutoConnect = false
                    }, onClose: {
                        showAutoConnect = false
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

                    MessageDialog(title: String(localized: "_configuration_wifi_required_title"),
                                   message: String(localized: "_configuration_wifi_required_message"),
                                   buttonTitle: String(localized: "_configuration_ok"),
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
        // Baue Kandidatenliste (Vollscan) und logge sie komplett
        let list = RTSPScanner.buildCandidates(config: config, wifi: wifi)
        candidates = list
        debugLog("AutoConnect candidates=\(list.count)", "RTSP")
        for (idx, url) in list.enumerated() { debugLog("#\(idx+1): \(url)", "RTSP") }

        acState = .scanning
        cancelScan = false
        showAutoConnect = true
        acTitleScanning = nil
        acTitleSuccess = nil
        acTitleNotFound = nil

        Task { @MainActor in
            // Optional: fire-and-forget prime (won't block)
            LocalNetworkPermission.shared.primeNow(wifi: wifi.snapshot)
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

    private func testCustomURL() {
        if !wifi.snapshot.isWiFiConnected { showWiFiAlert = true; return }
        let url = config.customStreamURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else { return }
        // Format-Validierung: rtsp://<IP>[:PORT]/<RESSOURCE>
        guard validateRTSPIv4URL(url) else {
            testResult = String(localized: "_configuration_invalid_url_message")
            return
        }

        // Zeige Verbindungsdialog
        acTitleScanning = String(localized: "_configuration_connection_establishing")
        acTitleSuccess = String(localized: "_configuration_connection_success")
        acTitleNotFound = String(localized: "_configuration_connection_failed")
        acState = .scanning
        showAutoConnect = true

        Task { @MainActor in
            LocalNetworkPermission.shared.primeNow(wifi: wifi.snapshot)
            let res = await RTSPProbe.probe(url: url)
            switch res {
            case .success:
                config.streamURL = url
                acState = .success
            case .failure:
                acState = .notFound
            }
        }
    }
}

// MARK: - URL Validation
private extension RTSPConfigurationDialog {
    func validateRTSPIv4URL(_ s: String) -> Bool {
        guard let comps = URLComponents(string: s) else { return false }
        guard let scheme = comps.scheme?.lowercased(), scheme == "rtsp" else { return false }
        guard let host = comps.host, isIPv4(host) else { return false }
        if let port = comps.port { if port <= 0 || port > 65535 { return false } }
        let path = comps.path
        if path.isEmpty || path == "/" { return false }
        return true
    }

    func isIPv4(_ s: String) -> Bool {
        let parts = s.split(separator: ".")
        if parts.count != 4 { return false }
        for p in parts {
            guard let v = Int(p), v >= 0 && v <= 255 else { return false }
        }
        return true
    }
}
