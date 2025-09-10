//
//  StreamPresets.swift
//  HuntScope
//
//  Struktur + Persistenz für RTSP-Stream-Presets.
//  Presets werden initial aus dem Bundle nach Application Support kopiert
//  ("StreamPresets.json"). Danach sind sie editier-/aktualisierbar.
//

import Foundation

// Bündel von Presets (mit Version für künftige Migrationen)
struct StreamPresetList: Codable, Equatable {
    var version: Int
    // Einfaches Schema: Liste von URL-Patterns (Strings)
    var presets: [String]

    static let empty = StreamPresetList(version: 1, presets: [])
}

// Manager kümmert sich um Laden/Speichern im Application-Support-Ordner.
final class StreamPresetManager {
    static let shared = StreamPresetManager()

    private let fileName = "StreamPresets.json"
    private(set) var list: StreamPresetList = .empty

    private init() {
        loadOrSeed()
    }

    // MARK: - API
    var presets: [String] { list.presets }

    func replaceAll(with newList: StreamPresetList) {
        list = newList
        save()
    }

    func upsert(_ url: String) {
        let norm = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !norm.isEmpty else { return }
        if !list.presets.contains(where: { $0.caseInsensitiveCompare(norm) == .orderedSame }) {
            list.presets.append(norm)
            save()
        }
    }

    // MARK: - Persistenz
    private func loadOrSeed() {
        if let url = Self.fileURL, FileManager.default.fileExists(atPath: url.path) {
            if let data = try? Data(contentsOf: url), let decoded = try? Self.decoder.decode(StreamPresetList.self, from: data) {
                list = decoded
                return
            }
        }

        // Falls nicht vorhanden: versuche aus Bundle zu kopieren, sonst leere Defaults speichern
        if let bundled = Bundle.main.url(forResource: "StreamPresets", withExtension: "json"),
           let data = try? Data(contentsOf: bundled),
           let decoded = try? Self.decoder.decode(StreamPresetList.self, from: data) {
            list = decoded
        } else {
            list = .empty
        }
        save()
    }

    private func save() {
        guard let url = Self.fileURL else { return }
        do {
            let data = try Self.encoder.encode(list)
            try data.write(to: url, options: [.atomic])
        } catch {
            debugLog("Failed to save \(fileName): \(error.localizedDescription)", "StreamPresets")
        }
    }

    private static var fileURL: URL? {
        do {
            let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return support.appendingPathComponent("StreamPresets.json")
        } catch { return nil }
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
