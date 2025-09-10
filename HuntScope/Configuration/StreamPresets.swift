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
        // 1) Versuche, App-Support-Datei zu laden (neues Schema)
        if let url = Self.fileURL, FileManager.default.fileExists(atPath: url.path) {
            if let data = try? Data(contentsOf: url) {
                if let decoded = try? Self.decoder.decode(StreamPresetList.self, from: data) {
                    var current = decoded
                    // Prüfe, ob das Bundle eine neuere Version enthält
                    if let bundled = Bundle.main.url(forResource: "StreamPresets", withExtension: "json"),
                       let bdata = try? Data(contentsOf: bundled) {
                        if let seed = try? Self.decoder.decode(StreamPresetList.self, from: bdata) {
                            if seed.version > current.version {
                                list = seed
                                save()
                                debugLog("Presets reseeded from newer Bundle (v\(seed.version) > v\(current.version)) — count=\(list.presets.count)", "StreamPresets")
                                return
                            }
                        } else if let legacySeed = try? Self.decoder.decode(LegacyPresetList.self, from: bdata) {
                            let seedList = StreamPresetList(version: legacySeed.version, presets: legacySeed.flattened())
                            if seedList.version > current.version {
                                list = seedList
                                save()
                                debugLog("Presets reseeded from newer Bundle (legacy) (v\(seedList.version) > v\(current.version)) — count=\(list.presets.count)", "StreamPresets")
                                return
                            }
                        }
                    }
                    list = current
                    debugLog("Presets loaded from Application Support (\(list.presets.count)), v\(current.version)", "StreamPresets")
                    return
                } else if let legacy = try? Self.decoder.decode(LegacyPresetList.self, from: data) {
                    // Migration: Legacy -> neues Schema (flatten) und ggf. gegen Bundle-Version prüfen
                    var current = StreamPresetList(version: legacy.version, presets: legacy.flattened())
                    if let bundled = Bundle.main.url(forResource: "StreamPresets", withExtension: "json"),
                       let bdata = try? Data(contentsOf: bundled) {
                        if let seed = try? Self.decoder.decode(StreamPresetList.self, from: bdata) {
                            if seed.version > current.version {
                                list = seed
                                save()
                                debugLog("Presets reseeded from newer Bundle (v\(seed.version) > v\(current.version)) — count=\(list.presets.count)", "StreamPresets")
                                return
                            }
                        } else if let legacySeed = try? Self.decoder.decode(LegacyPresetList.self, from: bdata) {
                            let seedList = StreamPresetList(version: legacySeed.version, presets: legacySeed.flattened())
                            if seedList.version > current.version {
                                list = seedList
                                save()
                                debugLog("Presets reseeded from newer Bundle (legacy) (v\(seedList.version) > v\(current.version)) — count=\(list.presets.count)", "StreamPresets")
                                return
                            }
                        }
                    }
                    list = current
                    save()
                    debugLog("Presets migrated from legacy format (\(list.presets.count)), v\(current.version)", "StreamPresets")
                    return
                }
            }
        }

        // 2) Seed aus Bundle (neues Schema, danach Legacy-Schema versuchen)
        if let bundled = Bundle.main.url(forResource: "StreamPresets", withExtension: "json"),
           let data = try? Data(contentsOf: bundled) {
            if let decoded = try? Self.decoder.decode(StreamPresetList.self, from: data) {
                list = decoded
                save()
                debugLog("Presets seeded from Bundle (\(list.presets.count))", "StreamPresets")
                return
            } else if let legacy = try? Self.decoder.decode(LegacyPresetList.self, from: data) {
                list = StreamPresetList(version: legacy.version, presets: legacy.flattened())
                save()
                debugLog("Presets seeded from Bundle (legacy migrated, \(list.presets.count))", "StreamPresets")
                return
            } else {
                debugLog("Failed to decode Bundle StreamPresets.json", "StreamPresets")
            }
        } else {
            debugLog("Bundle StreamPresets.json not found", "StreamPresets")
        }

        // 3) Fallback: leer speichern
        list = .empty
        save()
        debugLog("Presets empty — no seed available", "StreamPresets")
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

// MARK: - Legacy decoding support (vor Vereinfachung)
private struct LegacyPreset: Codable { let defaultURLs: [String] }
private struct LegacyPresetList: Codable {
    var version: Int
    var presets: [LegacyPreset]

    func flattened() -> [String] {
        presets.flatMap { $0.defaultURLs }.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
}
