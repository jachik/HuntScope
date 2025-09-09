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

    // MARK: - Init
    init() {}

    // MARK: - Public API (Platzhalter)

    /// Startet "logisch" – nur UI-Status toggeln, noch kein echter Stream.
    func play(urlString: String) {
        isConnected = true
        isPlaying = true
        // TODO: echte VLC-Initialisierung später
    }

    /// Stoppt "logisch".
    func stop() {
        isPlaying = false
        isConnected = false
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
        // TODO: später Vision/Erkennung aufrufen
    }
}
