//
//  AdMediaView.swift
//  HuntScope
//
//  Reusable, looping MP4 player view for in-app ads.
//

import SwiftUI
import AVFoundation

// Internal UIView hosting an AVPlayerLayer
final class _PlayerContainerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

struct LoopingVideoView: UIViewRepresentable {
    let url: URL
    var isMuted: Bool = true
    var videoGravity: AVLayerVideoGravity = .resizeAspect

    final class Coordinator {
        var player: AVQueuePlayer?
        var looper: AVPlayerLooper?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> _PlayerContainerView {
        let view = _PlayerContainerView()
        view.backgroundColor = .clear

        let item = AVPlayerItem(asset: AVURLAsset(url: url))
        let player = AVQueuePlayer()
        player.isMuted = isMuted
        player.actionAtItemEnd = .advance

        view.playerLayer.player = player
        view.playerLayer.videoGravity = videoGravity

        let looper = AVPlayerLooper(player: player, templateItem: item)
        context.coordinator.player = player
        context.coordinator.looper = looper

        player.play()
        return view
    }

    func updateUIView(_ uiView: _PlayerContainerView, context: Context) {
        uiView.playerLayer.videoGravity = videoGravity
        context.coordinator.player?.isMuted = isMuted
    }

    static func dismantleUIView(_ uiView: _PlayerContainerView, coordinator: Coordinator) {
        coordinator.player?.pause()
        coordinator.looper = nil
        coordinator.player = nil
    }
}

