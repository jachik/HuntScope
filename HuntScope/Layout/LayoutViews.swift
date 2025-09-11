//
//  LayoutViews.swift
//  HuntScope
//
//  Created by Jacek Schikora on 08.09.25.
//

import SwiftUI
import UIKit

enum DialogKind {
    case mainConfig
    case rtspConfig
    case testConfig
    case firstLaunch
}

// Zentraler Zustand: steuert, ob ein Dialog aktiv ist
@MainActor
final class UIStateModel: ObservableObject {
    @Published var isDialogActive: Bool = false
    // Persisted snapshot of the splash's last frame
    @Published var lastSplashFrame: UIImage? = nil
    // After first successful video, keep watermark hidden forever (until app relaunch)
    @Published var splashWatermarkLockedOff: Bool = false
    // Aktiver Dialog-Typ (nil = keiner)
    @Published var activeDialog: DialogKind? = nil
    // Vollbild-Werbung aktiv (unterdrueckt Overlays kurzfristig)
    @Published var isAdActive: Bool = false
    // Zeit bis zu der Overlays (Wasserzeichen/Keine-Verbindung) unterdrueckt werden
    @Published var suppressOverlaysUntil: Date? = nil
    // Lokaler (interner) Vollbild-AdDialog sichtbar
    @Published var isAdDialogPresented: Bool = false
    // Gewählte interne Ad-ID (z.B. "ad01")
    @Published var internalAdID: String? = nil
}

// Placeholder fuer den RTSP/VLC-Stream
struct StreamView: View {
    @EnvironmentObject private var config: ConfigStore
    @EnvironmentObject private var ui: UIStateModel
    @EnvironmentObject private var player: PlayerController
    @State private var blinkNoSignal: Bool = false
    var body: some View {
        ZStack {
            Color.black
            // VLC Video Surface underneath overlays (tinted in red mode)
            ViewerView()
                .colorMultiply(config.theme == .red ? .red : .white)

            // Signal-Definition: ausschliesslich basierend auf dem letzten Frame-Timestamp
            let hasSignal = player.hasStreamSignal
            // Unterdruecke Overlays waehrend aktiver Werbung oder fuer kurze Zeit nach Schliessen
            let overlaysSuppressed: Bool = {
                if ui.isAdActive { return true }
                if let until = ui.suppressOverlaysUntil { return until > Date() }
                return false
            }()

            // Overlay the last splash frame only when no frames/signal are present
            if !hasSignal, !overlaysSuppressed, !ui.splashWatermarkLockedOff, let image = ui.lastSplashFrame {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .saturation(config.theme == .white ? 0 : 1)
                    .opacity((config.theme == .red) ? 0.15 : 0.25)
                    .allowsHitTesting(false)
            }

            // No-connection indicator: hide while configuration dialogs are active
            if !hasSignal, !overlaysSuppressed, !ui.isDialogActive {
                GeometryReader { geo in
                    let side = min(geo.size.width, geo.size.height) * 0.6
                    let primary: Color = (config.theme == .red) ? .red : .white
                    Image(systemName: "video.slash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: side, height: side)
                        .foregroundStyle(primary)
                        .opacity(blinkNoSignal ? 1.0 : 0.0)
                        .onAppear {
                            blinkNoSignal = false
                            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                blinkNoSignal = true
                            }
                        }
                        .onDisappear { blinkNoSignal = false }
                        // Center within the available stream area
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                }
                .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
        // Sobald echter Stream laeuft, Splash-Wasserzeichen dauerhaft entfernen
        .onChange(of: player.hasStreamSignal) { hasSignal in
            if hasSignal {
                ui.lastSplashFrame = nil
                ui.splashWatermarkLockedOff = true
            }
        }
        .onChange(of: player.isPlaying) { _ in
            if player.hasStreamSignal {
                ui.lastSplashFrame = nil
                ui.splashWatermarkLockedOff = true
            }
        }
    }
}



// Vollbild-Layer fuer Dialoge, liegt ueber dem Stream
struct DialogOverlay<Content: View>: View {
    let isVisible: Bool
    let content: Content

    init(isVisible: Bool, @ViewBuilder content: () -> Content) {
        self.isVisible = isVisible
        self.content = content()
    }

    var body: some View {
        Group {
            if isVisible {
                ZStack {
                    // Keine globale Abdunkelung mehr hier; diese wird gezielt im MainLayout
                    // nur über dem Center-Bereich gelegt, damit Seiten-Buttons klar sichtbar bleiben.
                    content
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isVisible)
    }
}
