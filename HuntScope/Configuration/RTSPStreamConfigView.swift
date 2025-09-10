//
//  RTSPStreamConfigView.swift
//  HuntScope
//
//  Stream-spezifische Konfiguration im gleichen Stil wie ConfigDialogView.
//

import SwiftUI

struct RTSPStreamConfigView: View {
    @EnvironmentObject private var config: ConfigStore
    @EnvironmentObject private var ui: UIStateModel
    @EnvironmentObject private var player: PlayerController

    private var primary: Color { (config.theme == .red) ? .red : .white }

    @State private var testResult: String? = nil
    @State private var showManual: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Panel + Inhalt
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("Stream-Konfiguration")
                        .font(.title.weight(.bold))
                        .foregroundStyle(primary)
                    Spacer()
                }

                // Auto-Connect (zentriert)
                HStack {
                    Spacer()
                    Button {
                        debugLog("Auto-Connect pressed", "RTSPConfig")
                        // TODO: Auto-Connect Implementierung
                    } label: {
                        Text("Auto-Connect").bold().foregroundStyle(primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.black)
                    Spacer()
                }

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
                                .font(.footnote.weight(.semibold))
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
                            Text("Kamera-URL (in der Form rtsp://IP/Ressource)")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(primary.opacity(0.9))

                            HStack(spacing: 12) {
                                TextField("rtsp://…", text: Binding(
                                    get: { config.customStreamURL },
                                    set: { config.customStreamURL = $0 }
                                ))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .foregroundStyle(primary)
                                .padding(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(primary.opacity(0.6), lineWidth: 1)
                                )

                                Button {
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
                                    Text("Test").bold().foregroundStyle(primary)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.black)
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

                Spacer(minLength: 0)
            }
            .foregroundColor(primary)
            .padding(24)
            .background(Color.black.opacity(0.7))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(primary.opacity(0.8), lineWidth: 1)
            )
            .cornerRadius(16)
            .shadow(radius: 8)

            // Close-Button identisch zum Hauptdialog
            Button {
                ui.isDialogActive = false
                ui.activeDialog = nil
            } label: {
                ZStack {
                    Circle().stroke(primary, lineWidth: 2)
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundStyle(primary)
                }
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)
            .padding(.top, 5)
            .padding(.trailing, 5)
        }
    }
}
