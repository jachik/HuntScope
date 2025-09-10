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
}

// Zentraler Zustand: steuert, ob ein Dialog aktiv ist
@MainActor
final class UIStateModel: ObservableObject {
    @Published var isDialogActive: Bool = false
    // Persisted snapshot of the splash's last frame
    @Published var lastSplashFrame: UIImage? = nil
    // Aktiver Dialog-Typ (nil = keiner)
    @Published var activeDialog: DialogKind? = nil
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
            // Placeholder for future stream layer lives underneath

            // Overlay the last splash frame, perfectly aligned and non-interactive
            if let image = ui.lastSplashFrame {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    // Apply grayscale only in s/w (white) theme
                    .saturation(config.theme == .white ? 0 : 1)
                    // Subtle watermark when playing, more visible when no stream
                    .opacity((player.isConnected && player.isPlaying) ? 0.08 : ((config.theme) == .red ? 0.15 : 0.25))
                    .animation(.easeInOut(duration: 0.25), value: player.isPlaying)
                    .animation(.easeInOut(duration: 0.25), value: player.isConnected)
                    .allowsHitTesting(false)
            }

            // No-connection indicator: large flashing icon when no signal/connection
            let noSignal = (!player.isConnected) || (!player.hasStreamSignal)
            if noSignal {
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
