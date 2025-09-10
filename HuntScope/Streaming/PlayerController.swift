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
    private let signalTimeout: TimeInterval = 2.0 // Sekunden ohne Frames => kein Signal

    // VLC
    private let vlcPlayer: VLCMediaPlayer
    private weak var surfaceView: UIView?
    private var reconnectScheduled = false
    private var reconnectWorkItem: DispatchWorkItem?
    private var reconnectDelay: TimeInterval = 2.0
    private var intentionallyStopped = false
    private var currentURLString: String? = nil
    private var currentRecordingURL: URL? = nil

    // MARK: - Init
    override init() {
        // Use default MobileVLCKit configuration.
        // Some global libVLC flags are not supported on iOS builds
        // and can cause instability if passed at player init time.
        vlcPlayer = VLCMediaPlayer()
        super.init()
    }

    // MARK: - Public API (Platzhalter)

    func play(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        // Cancel any pending reconnects and clear stop flag
        reconnectWorkItem?.cancel(); reconnectWorkItem = nil
        reconnectScheduled = false
        intentionallyStopped = false
        hasStreamSignal = false
        isConnected = false
        isPlaying = false
        lastFrameAt = nil
        currentURLString = urlString

        let media = buildMedia(url: url, recordingTo: currentRecordingURL)
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
        // Prevent any queued reconnect from firing
        reconnectWorkItem?.cancel(); reconnectWorkItem = nil
        reconnectScheduled = false
        reconnectDelay = 2.0
        intentionallyStopped = true
        stopSignalWatchdog()
    }

    /// "Foto" – Platzhalter, setzt nur den Snapshot-Zustand zurück.
    func takePhoto() {
        // TODO: später Snapshot-Datei erzeugen und URL setzen
        lastSnapshotURL = nil
    }

    /// Aufnahme starten/stoppen – nur Status.
    func startRecording() {
        guard !isRecording else { return }
        // Ziel-Datei anlegen (unter Documents/Recordings/*.ts)
        guard let recordingsDir = ensureRecordingsDirectory() else {
            debugLog("recordings directory unavailable", "Player")
            return
        }
        let fileURL = recordingsDir.appendingPathComponent(makeRecordingFileName())
        currentRecordingURL = fileURL
        isRecording = true
        debugLog("record start -> \(fileURL.lastPathComponent)", "Player")
        // Läuft bereits? -> mit sout neu starten (kurzer Reconnect)
        if let urlStr = currentURLString, !urlStr.isEmpty, isPlaying {
            // Neustart mit Aufnahme
            vlcPlayer.stop()
            let url = URL(string: urlStr)!
            let media = buildMedia(url: url, recordingTo: fileURL)
            vlcPlayer.media = media
            if let surface = surfaceView { vlcPlayer.drawable = surface }
            vlcPlayer.play()
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        let lastFile = currentRecordingURL
        currentRecordingURL = nil
        debugLog("record stop (file=\(lastFile?.lastPathComponent ?? "nil"))", "Player")
        // Läuft bereits? -> ohne sout neu starten (kurzer Reconnect)
        if let urlStr = currentURLString, !urlStr.isEmpty, isPlaying {
            vlcPlayer.stop()
            let url = URL(string: urlStr)!
            let media = buildMedia(url: url, recordingTo: nil)
            vlcPlayer.media = media
            if let surface = surfaceView { vlcPlayer.drawable = surface }
            vlcPlayer.play()
        }
    }

    func attach(view: UIView) {
        surfaceView = view
        vlcPlayer.drawable = view
    }

    // MARK: - Media/Recording Helpers
    private func buildMedia(url: URL, recordingTo: URL?) -> VLCMedia {
        let media = VLCMedia(url: url)
        var opts: [String: Any] = [
            //"rtsp-tcp": true,
            "network-caching": 300
        ]
        if let file = recordingTo {
            let path = file.path
            // Duplicate to display and file (MPEG-TS)
            let sout = "#duplicate{dst=display,dst=std{access=file,mux=ts,dst=\(path)}}"
            opts["sout"] = sout
            opts["sout-keep"] = true
        }
        media.addOptions(opts)
        return media
    }

    private func ensureRecordingsDirectory() -> URL? {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let dir = docs.appendingPathComponent("Recordings", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            do { try fm.createDirectory(at: dir, withIntermediateDirectories: true) }
            catch {
                debugLog("failed to create Recordings dir: \(error.localizedDescription)", "Player")
                return nil
            }
        }
        return dir
    }

    private func makeRecordingFileName() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd_HHmmss"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        let ts = df.string(from: Date())
        return "HuntScope_\(ts).ts"
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
            // Noch kein echter Verbindungsaufbau bestätigt
            isConnected = false
            isPlaying = false
        case .playing:
            isConnected = true
            isPlaying = true
            // Signal wird ausschließlich über lastFrameAt/Timer bestimmt
        case .stopped, .ended, .error:
            isPlaying = false
            isConnected = false
            hasStreamSignal = false
            if !intentionallyStopped {
                scheduleReconnect()
            }
        default:
            break
        }
    }

    @objc func mediaPlayerTimeChanged(_ aNotification: Notification) {
        lastFrameAt = Date()
        if hasStreamSignal == false { hasStreamSignal = true }
    }

    private func scheduleReconnect() {
        // Don't reconnect if the user intentionally stopped playback
        guard !intentionallyStopped else { return }
        guard !reconnectScheduled else { return }
        reconnectScheduled = true
        let delay = max(1.5, reconnectDelay)
        debugLog("reconnect in \(Int(delay*1000)) ms", "Player")
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.reconnectWorkItem = nil
            self.reconnectScheduled = false
            // If it was stopped intentionally in the meantime, abort
            guard !self.intentionallyStopped else { return }
            // Try to resume with last URL
            if let u = self.vlcPlayer.media?.url.absoluteString, !u.isEmpty {
                self.play(urlString: u)
                // Backoff leicht erhöhen, aber deckeln
                self.reconnectDelay = min(self.reconnectDelay + 1.0, 5.0)
            }
        }
        reconnectWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }
}
