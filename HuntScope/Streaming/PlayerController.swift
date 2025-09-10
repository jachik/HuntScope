//
//  PlayerController.swift
//  HuntScope
//

import Foundation
import SwiftUI
import MobileVLCKit

/// Platzhalter: Kein VLC, keine I/O.
/// Nur Zustände und leere Methoden, damit die UI bereits funktioniert.
@MainActor
final class PlayerController: NSObject, ObservableObject {
    // MARK: - Zustände für die UI
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var lastSnapshotURL: URL?
    // Gibt an, ob aktuell Videodaten anliegen (Signal vorhanden)
    @Published private(set) var hasStreamSignal: Bool = false

    // Interne Hilfe: letzte Frame-Zeit + Watchdog-Timer
    private var lastFrameAt: Date?
    private var signalTimer: Timer?
    private let signalTimeout: TimeInterval = 5.0 // Sekunden ohne Frames => kein Signal

    // VLC
    private let vlcPlayer = VLCMediaPlayer()
    private weak var surfaceView: UIView?
    private var reconnectScheduled = false
    private var reconnectDelay: TimeInterval = 2.0

    // MARK: - Init
    //init() {}

    // MARK: - Public API (Platzhalter)

    func play(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        reconnectScheduled = false
        hasStreamSignal = false
        isConnected = false
        isPlaying = false
        lastFrameAt = nil

        let media = VLCMedia(url: url)
        // Kein TCP erzwingen; Optionen optional minimal halten
        // media.addOptions(["network-caching=300"]) // ggf. später
        vlcPlayer.media = media
        vlcPlayer.delegate = self
        if let surface = surfaceView { vlcPlayer.drawable = surface }
        vlcPlayer.play()
        startSignalWatchdog()
    }

    func stop() {
        vlcPlayer.stop()
        isPlaying = false
        isConnected = false
        hasStreamSignal = false
        reconnectScheduled = false
        reconnectDelay = 2.0
        stopSignalWatchdog()
    }

    /// "Foto" – Platzhalter, setzt nur den Snapshot-Zustand zurück.
    func takePhoto() {
        // TODO: später Snapshot-Datei erzeugen und URL setzen
        lastSnapshotURL = nil
    }

    /// Aufnahme starten/stoppen – nur Status.
    func startRecording() {
        isRecording = true
        // TODO: später echte Aufnahme starten
    }

    func stopRecording() {
        isRecording = false
        // TODO: später echte Aufnahme stoppen
    }

    func attach(view: UIView) {
        surfaceView = view
        vlcPlayer.drawable = view
    }

    // MARK: - Signal-Überwachung
    private func startSignalWatchdog() {
        signalTimer?.invalidate()
        signalTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = Date()
            if let last = self.lastFrameAt {
                if now.timeIntervalSince(last) > self.signalTimeout {
                    if self.hasStreamSignal {
                        self.hasStreamSignal = false
                        debugLog("stream signal: lost (timeout)", "Player")
                        self.scheduleReconnect()
                    }
                }
            } else {
                // Noch kein Frame angekommen: weiterhin false
            }
        }
        if let t = signalTimer { RunLoop.main.add(t, forMode: .common) }
    }

    private func stopSignalWatchdog() {
        signalTimer?.invalidate()
        signalTimer = nil
        lastFrameAt = nil
    }
}

extension PlayerController: VLCMediaPlayerDelegate {
    @objc func mediaPlayerStateChanged(_ aNotification: Notification) {
        let state = vlcPlayer.state
        switch state {
        case .opening, .buffering:
            isConnected = true
        case .playing:
            isConnected = true
            isPlaying = true
            hasStreamSignal = true
            lastFrameAt = Date()
        case .stopped, .ended, .error:
            isPlaying = false
            isConnected = false
            hasStreamSignal = false
            scheduleReconnect()
        default:
            break
        }
    }

    @objc func mediaPlayerTimeChanged(_ aNotification: Notification) {
        lastFrameAt = Date()
        if hasStreamSignal == false { hasStreamSignal = true }
    }

    private func scheduleReconnect() {
        guard !reconnectScheduled else { return }
        reconnectScheduled = true
        let delay = max(1.5, reconnectDelay)
        debugLog("reconnect in \(Int(delay*1000)) ms", "Player")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            self.reconnectScheduled = false
            // Falls wir inzwischen manuell gestoppt wurden, nicht erneut starten
            // Versuche mit der zuletzt gesetzten URL weiterzuspielen
            if let u = self.vlcPlayer.media?.url.absoluteString, !u.isEmpty {
                self.play(urlString: u)
                // Backoff leicht erhöhen, aber deckeln
                self.reconnectDelay = min(self.reconnectDelay + 1.0, 5.0)
            }
        }
    }
}
