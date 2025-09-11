//
//  ViewerView.swift
//  HuntScope
//
//  SwiftUI Host für die VLC-Videoausgabe (UIViewRepresentable).
//

import SwiftUI

final class VideoSurfaceView: UIView {}

struct ViewerView: UIViewRepresentable {
    @EnvironmentObject private var player: PlayerController
    @EnvironmentObject private var ui: UIStateModel
    @EnvironmentObject private var config: ConfigStore

    func makeUIView(context: Context) -> VideoSurfaceView {
        let v = VideoSurfaceView()
        player.attach(view: v)
        // Auto-Start kurz nach Instanziierung (falls erlaubt)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if !ui.isDialogActive, !config.streamURL.isEmpty {
                player.play(urlString: config.streamURL)
            }
        }
        return v
    }

    func updateUIView(_ uiView: VideoSurfaceView, context: Context) {
        // No-op. Surface bleibt angehängt.
    }
}

