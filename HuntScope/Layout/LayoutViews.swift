//
//  LayoutViews.swift
//  HuntScope
//
//  Created by Jacek Schikora on 08.09.25.
//

import SwiftUI
import UIKit

// Zentraler Zustand: steuert, ob ein Dialog aktiv ist
@MainActor
final class UIStateModel: ObservableObject {
    @Published var isDialogActive: Bool = false
    // Persisted snapshot of the splash's last frame
    @Published var lastSplashFrame: UIImage? = nil
}

// Placeholder fuer den RTSP/VLC-Stream
struct StreamView: View {
    @EnvironmentObject private var config: ConfigStore
    @EnvironmentObject private var ui: UIStateModel
    @EnvironmentObject private var player: PlayerController
    var body: some View {
        ZStack {
            Color.black
            // Placeholder for future stream layer lives underneath

            // Overlay the last splash frame, perfectly aligned and non-interactive
            if let image = ui.lastSplashFrame {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    // Subtle watermark when playing, more visible when no stream
                    .opacity((player.isConnected && player.isPlaying) ? 0.08 : 0.15)
                    .animation(.easeInOut(duration: 0.25), value: player.isPlaying)
                    .animation(.easeInOut(duration: 0.25), value: player.isConnected)
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
