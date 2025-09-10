//
//  PlayerController.swift
//  HuntScope
//

import Foundation
import SwiftUI

/// Platzhalter: Kein VLC, keine I/O.
/// Nur Zustände und leere Methoden, damit die UI bereits funktioniert.
@MainActor
final class PlayerController: ObservableObject {
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
    private let signalTimeout: TimeInterval = 3.0 // Sekunden ohne Frames => kein Signal

    // MARK: - Init
    init() {}

    // MARK: - Public API (Platzhalter)

    /// Startet "logisch" – nur UI-Status toggeln, noch kein echter Stream.
    func play(urlString: String) {
        isConnected = true
        isPlaying = true
        // Beim Start warten wir auf das erste Frame
        hasStreamSignal = false
        lastFrameAt = nil
        startSignalWatchdog()
        // TODO: echte VLC-Initialisierung später
    }

    /// Stoppt "logisch".
    func stop() {
        isPlaying = false
        isConnected = false
        hasStreamSignal = false
        stopSignalWatchdog()
        // TODO: später VLC stoppen/entkoppeln
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

    /// Hook für Video-Frames – aktuell leer.
    func onVideoFrame(/* _ pixelBuffer: CVPixelBuffer */) {
        // Wird vom echten Player bei jedem neuen Videoframe aufgerufen
        lastFrameAt = Date()
        if hasStreamSignal == false {
            hasStreamSignal = true
            debugLog("stream signal: available", "Player")
        }
        // TODO: später Vision/Erkennung aufrufen
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
