//
//  AdDialog.swift
//  HuntScope
//
//  Fullscreen modal ad dialog for localized MP4 creatives.
//  - White background independent of theme
//  - 5s countdown circle at top-right before showing close button
//  - Close button style matches project dialog close, but gray on white
//

import SwiftUI
import AVFoundation

struct AdDialog: View {
    // Identifier of the ad creative (e.g., "ad01").
    // Resolution strategy:
    // 1) Try localized resource `adID.mp4` via .lproj (preferred)
    // 2) Fallback to suffixed filename `adID_<lang>.mp4` (e.g., ad01_de.mp4)
    let adID: String

    // Configuration
    var showCloseAfter: Int = 5
    var isMuted: Bool = true

    // Lifecycle
    var onClose: () -> Void

    // State
    @State private var remaining: Int = 5
    @State private var canClose: Bool = false
    @State private var timer: Timer? = nil

    private let controlSize: CGFloat = 44

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // White background independent of theme
            Color.white.ignoresSafeArea()

            // Media / Content
            GeometryReader { geo in
                Group {
                    if let url = resolveAdURL() {
                        LoopingVideoView(url: url, isMuted: isMuted, videoGravity: .resizeAspect)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .contentShape(Rectangle())
                            .allowsHitTesting(false) // block interactions to the video layer
                    } else {
                        // Minimal placeholder if no asset found
                        VStack(spacing: 12) {
                            Image(systemName: "play.rectangle")
                                .font(.system(size: 48))
                                .foregroundColor(.gray.opacity(0.6))
                            Text("Ad asset not found")
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }

            // Countdown / Close control (top-right)
            Group {
                if canClose {
                    Button(action: onClose) {
                        ZStack {
                            Circle().stroke(Color.gray, lineWidth: 2)
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundStyle(Color.gray)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(width: controlSize, height: controlSize)
                    .padding(.top, 18)
                    .padding(.trailing, 18)
                } else {
                    CountdownBadge(remaining: remaining)
                        .frame(width: controlSize, height: controlSize)
                        .padding(.top, 18)
                        .padding(.trailing, 18)
                        .accessibilityLabel(Text("Werbung kann in \(remaining) Sekunden geschlossen werden"))
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            stopCountdown()
        }
    }

    // MARK: - Countdown

    private func startCountdown() {
        remaining = max(0, showCloseAfter)
        canClose = (remaining == 0)
        timer?.invalidate()
        guard remaining > 0 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remaining > 1 {
                remaining -= 1
            } else {
                remaining = 0
                canClose = true
                stopCountdown()
            }
        }
        if let t = timer {
            RunLoop.main.add(t, forMode: .common)
        }
    }

    private func stopCountdown() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Resource resolution

    private func resolveAdURL() -> URL? {
        // Preferred localized resource (adID.mp4) via .lproj
        if let url = Bundle.main.url(forResource: adID, withExtension: "mp4") {
            return url
        }
        // Optional: if you place localized files under an 'Ads' folder reference
        if let url = Bundle.main.url(forResource: adID, withExtension: "mp4", subdirectory: "Ads") {
            return url
        }
        return nil
    }
}

// Simple circular badge showing the remaining seconds
private struct CountdownBadge: View {
    let remaining: Int
    var body: some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.6), lineWidth: 2)
            Text("\(remaining)")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
}
