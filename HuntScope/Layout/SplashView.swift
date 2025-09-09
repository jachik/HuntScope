//
//  SplashScreen.swift
//  HuntScope
//
//  Created by Jacek Schikora on 09.09.25.
//
//
//  SplashView.swift
//  HuntScope
//

import SwiftUI
import AVFoundation
import AVKit

/// Spielt ein kurzes MP4 aus dem Bundle ab und meldet sich, wenn fertig.
/// Läuft stumm, ohne Controls.
struct SplashView: View {
    var onFinished: () -> Void

    @State private var player: AVPlayer? = nil
    @State private var didFinish = false
    @State private var fading = false

    var body: some View {
        ZStack {
            // Schwarzer Hintergrund
            Color.black.ignoresSafeArea()

            // Video
            if let player {
                VideoPlayerView(player: player)
                    .onAppear {
                        // Wieder ans Anfang spulen (falls jemals erneut genutzt)
                        player.seek(to: .zero)
                        player.play()
                    }
            }
        }
        // Sanftes Ausblenden, wenn "fading" gesetzt wird
        .opacity(fading ? 0 : 1)
        .animation(.easeInOut(duration: 0.6), value: fading)
        .onAppear {
            // Player vorbereiten (huntscope_intro.mp4 im Bundle)
            if let url = Bundle.main.url(forResource: "huntscope_intro", withExtension: "mp4")
                ?? Bundle.main.url(forResource: "splash", withExtension: "mp4") {
                let p = AVPlayer(url: url)
                p.isMuted = true
                p.actionAtItemEnd = .pause // letztes Frame stehen lassen
                p.currentItem?.preferredForwardBufferDuration = 0
                // Ende beobachten
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                       object: p.currentItem, queue: .main) { _ in
                    guard !didFinish else { return }
                    didFinish = true
                    // Erst ausblenden, dann Callback
                    fading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        onFinished()
                    }
                }
                self.player = p
            } else {
                // Fallback: kein Video gefunden -> sofort weiter
                onFinished()
            }
        }
    }
}

/// Kleiner Wrapper um AVPlayerLayer ohne Controls.
private struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerView {
        let v = PlayerContainerView()
        v.playerLayer.player = player
        v.playerLayer.videoGravity = .resizeAspect // oder .resizeAspectFill
        return v
    }
    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.playerLayer.player = player
    }

    final class PlayerContainerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}
