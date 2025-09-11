//
//  PlayerController.swift
//  HuntScope
//

import Foundation
import SwiftUI
import MobileVLCKit
import Photos
import CoreLocation

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
    private var recordingSessionBase: String? = nil
    private var recordingSegmentIndex: Int = 0
    private var startNewSegmentOnNextPlay: Bool = false

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

        // If recording is active, ensure we have a target URL and roll segment when requested
        var recURL = currentRecordingURL
        if isRecording {
            if let dir = ensureRecordingsDirectory() {
                if recordingSessionBase == nil { recordingSessionBase = makeRecordingBaseName() }
                if startNewSegmentOnNextPlay || recURL == nil {
                    recURL = nextRecordingURL(in: dir)
                    currentRecordingURL = recURL
                    startNewSegmentOnNextPlay = false
                    debugLog("record segment started -> \(recURL!.lastPathComponent)", "Player")
                }
            }
        }
        let media = buildMedia(url: url, recordingTo: recURL)
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

    /// Foto-Snapshot: Wasserzeichen und optional Standort in Fotos-Mediathek speichern.
    func takePhoto() {
        Task { @MainActor in
            let ts = Self.snapshotTimestamp()
            let fileName = "HuntScope_\(ts).jpg"
            // Request Photos permission (add-only) 
            guard await Self.ensurePhotoPermission() else {
                debugLog("Photo permission denied", "Snapshot")
                return
            }
            // Create temp path and ask VLC to write a snapshot
            let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            vlcPlayer.saveVideoSnapshot(at: tmpURL.path, withWidth: 0, andHeight: 0)

            // Load an image (from file or VLC lastSnapshot)
            var baseImage: UIImage? = UIImage(contentsOfFile: tmpURL.path)
            if baseImage == nil { baseImage = vlcPlayer.lastSnapshot }
            guard let image = baseImage else {
                debugLog("Failed to capture snapshot image", "Snapshot")
                return
            }

            // Apply watermark
            let watermarked = Self.renderWatermarked(image: image, text: "HuntScope")
            guard let data = watermarked.jpegData(compressionQuality: 0.9) else {
                debugLog("Failed to encode watermarked JPEG", "Snapshot")
                return
            }

            // Try to attach location (optional)
            let location = await OneShotLocation.shared.currentLocation()

            PHPhotoLibrary.shared().performChanges({
                let req = PHAssetCreationRequest.forAsset()
                let opts = PHAssetResourceCreationOptions()
                opts.originalFilename = fileName
                req.addResource(with: .photo, data: data, options: opts)
                req.creationDate = Date()
                if let loc = location { req.location = loc }
            }, completionHandler: { success, error in
                Task { @MainActor in
                    if success {
                        debugLog("Snapshot saved: \(fileName)", "Snapshot")
                    } else {
                        debugLog("Snapshot save failed: \(error?.localizedDescription ?? "unknown")", "Snapshot")
                    }
                }
            })
            try? FileManager.default.removeItem(at: tmpURL)
        }
    }

    /// Aufnahme starten/stoppen – nur Status.
    func startRecording() {
        guard !isRecording else { return }
        // Ziel-Datei anlegen (unter Documents/Recordings/*.ts)
        guard let recordingsDir = ensureRecordingsDirectory() else {
            debugLog("recordings directory unavailable", "Player")
            return
        }
        // Start neue Session und erstes Segment
        recordingSessionBase = makeRecordingBaseName()
        recordingSegmentIndex = 0
        let fileURL = nextRecordingURL(in: recordingsDir)
        currentRecordingURL = fileURL
        startNewSegmentOnNextPlay = false
        isRecording = true
        debugLog("record start -> \(fileURL.lastPathComponent)", "Player")
        // Wenn eine URL bekannt ist, Player mit Aufnahme neu binden (State egal)
        if let urlStr = currentURLString, !urlStr.isEmpty {
            // Neustart mit Aufnahme
            intentionallyStopped = true
            vlcPlayer.stop()
            let url = URL(string: urlStr)!
            let media = buildMedia(url: url, recordingTo: fileURL)
            vlcPlayer.media = media
            if let surface = surfaceView { vlcPlayer.drawable = surface }
            vlcPlayer.play()
            intentionallyStopped = false
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        let lastFile = currentRecordingURL
        currentRecordingURL = nil
        recordingSessionBase = nil
        recordingSegmentIndex = 0
        startNewSegmentOnNextPlay = false
        debugLog("record stop (file=\(lastFile?.lastPathComponent ?? "nil"))", "Player")
        // Wenn eine URL bekannt ist, Player ohne Aufnahme neu binden (State egal)
        if let urlStr = currentURLString, !urlStr.isEmpty {
            intentionallyStopped = true
            vlcPlayer.stop()
            let url = URL(string: urlStr)!
            let media = buildMedia(url: url, recordingTo: nil)
            vlcPlayer.media = media
            if let surface = surfaceView { vlcPlayer.drawable = surface }
            vlcPlayer.play()
            intentionallyStopped = false
        }
    }

    func attach(view: UIView) {
        surfaceView = view
        vlcPlayer.drawable = view
    }

    // MARK: - Media/Recording Helpers
    private func buildMedia(url: URL, recordingTo: URL?) -> VLCMedia {
        let media = VLCMedia(url: url)
        
        // die folgenden Optionen sind für eine
        // geringe Latenz sehr wichtig
        media.addOption(":network-caching=120")
        media.addOption(":live-caching=120")
        media.addOption(":drop-late-frames")
        media.addOption(":skip-frames")
        media.addOption(":clock-synchro=0")
        media.addOption(":clock-jitter=0")
        media.addOption(":avcodec-fast")
        media.addOption(":rtsp-caching=120")
        media.addOption(":tcp-caching=0")
        media.addOption(":file-caching=0")
        media.addOption(":rtsp-mtu=1200")
        media.addOption(":no-audio")
        media.addOption(":no-zeroconf")
        media.addOption(":services-discovery=")
        media.addOption(":sap-timeout=0")
        media.addOption(":ipv4")
        media.addOption(":no-ipv6")
        
        if let file = recordingTo {
            let path = file.path.replacingOccurrences(of: "'", with: "''")
            // MP4-Datei (Container) – finalisiert beim Stop
            let sout = ":sout=#duplicate{dst=display,dst=std{access=file,mux=mp4,dst='\(path)'}}"
            media.addOption(sout)
            media.addOption(":sout-all")
            media.addOption(":sout-keep")
            debugLog("sout=\(sout)", "Player")
        }
        //media.addOptions(opts)
        return media
    }

    // MARK: - Snapshot helpers
    private static func snapshotTimestamp() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyMMdd_HHmmss"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        return df.string(from: Date())
    }

    private static func ensurePhotoPermission() async -> Bool {
        if #available(iOS 14, *) {
            let s = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            if s == .authorized { return true }
            if s == .denied || s == .restricted { return false }
            return await withCheckedContinuation { cont in
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                    cont.resume(returning: status == .authorized)
                }
            }
        } else {
            let s = PHPhotoLibrary.authorizationStatus()
            if s == .authorized { return true }
            if s == .denied || s == .restricted { return false }
            return await withCheckedContinuation { cont in
                PHPhotoLibrary.requestAuthorization { status in
                    cont.resume(returning: status == .authorized)
                }
            }
        }
    }
    
    private static func renderWatermarked(image: UIImage, text: String) -> UIImage {
        let size = image.size
        let scale = image.scale
        UIGraphicsBeginImageContextWithOptions(size, true, scale)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: size))

        // Watermark style
        let fontSize = max(14, min(48, size.width * 0.03))
        let font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .right
        let shadow = NSShadow()
        shadow.shadowColor = UIColor.black.withAlphaComponent(0.6)
        shadow.shadowBlurRadius = 3
        shadow.shadowOffset = CGSize(width: 0, height: 1)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraph,
            .shadow: shadow
        ]
        let inset: CGFloat = max(8, size.width * 0.015)
        let textRect = CGRect(x: inset, y: size.height - inset - font.lineHeight,
                              width: size.width - inset * 2, height: font.lineHeight)
        (text as NSString).draw(in: textRect, withAttributes: attributes)

        return UIGraphicsGetImageFromCurrentImageContext() ?? image
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

    private func makeRecordingBaseName() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd_HHmmss"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        let ts = df.string(from: Date())
        return "HuntScope_\(ts)"
    }

    private func nextRecordingURL(in dir: URL) -> URL {
        recordingSegmentIndex += 1
        let base = recordingSessionBase ?? makeRecordingBaseName()
        if recordingSegmentIndex == 1 {
            // Erstes Segment: kein Suffix, nur .mp4
            return dir.appendingPathComponent("\(base).mp4")
        } else {
            // Ab zweitem Segment: _partXX.mp4
            let name = String(format: "%@_part%02d.mp4", base, recordingSegmentIndex)
            return dir.appendingPathComponent(name)
        }
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
                if isRecording { startNewSegmentOnNextPlay = true }
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
