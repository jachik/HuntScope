//
//  LastKnownGoodStore.swift
//  HuntScope
//
//  Verwaltung der zuletzt erfolgreichen RTSP-URLs (LRU-ähnlich).
//

import Foundation

struct LastKnownGoodEntry: Codable, Equatable {
    var url: String
    var vendor: String?
    var lastSuccessAt: Date
    var hits: Int
}

struct LastKnownGood: Codable, Equatable {
    var entries: [LastKnownGoodEntry]
    static let empty = LastKnownGood(entries: [])
}

final class LastKnownGoodStore {
    static let shared = LastKnownGoodStore()

    private let fileName = "LastKnownGood.json"
    private let maxEntries = 20
    private(set) var model: LastKnownGood = .empty

    private init() {
        load()
    }

    var entries: [LastKnownGoodEntry] { model.entries }

    // Aufzeichnen eines Erfolgs: an den Anfang, hits++, Timestamp aktualisieren, deduplizieren und begrenzen
    func recordSuccess(url: String, vendor: String?) {
        let norm = url.trimmingCharacters(in: .whitespacesAndNewlines)
        var list = model.entries.filter { $0.url.caseInsensitiveCompare(norm) != .orderedSame }
        let now = Date()
        if let idx = model.entries.firstIndex(where: { $0.url.caseInsensitiveCompare(norm) == .orderedSame }) {
            var e = model.entries[idx]
            e.hits += 1
            e.lastSuccessAt = now
            e.vendor = e.vendor ?? vendor
            list.insert(e, at: 0)
        } else {
            list.insert(LastKnownGoodEntry(url: norm, vendor: vendor, lastSuccessAt: now, hits: 1), at: 0)
        }
        if list.count > maxEntries {
            list = Array(list.prefix(maxEntries))
        }
        model.entries = list
        save()
    }

    func remove(url: String) {
        let norm = url.trimmingCharacters(in: .whitespacesAndNewlines)
        model.entries.removeAll { $0.url.caseInsensitiveCompare(norm) == .orderedSame }
        save()
    }

    func clear() {
        model = .empty
        save()
    }

    // MARK: - Persistenz
    private func load() {
        if let url = Self.fileURL, FileManager.default.fileExists(atPath: url.path),
           let data = try? Data(contentsOf: url),
           let decoded = try? Self.decoder.decode(LastKnownGood.self, from: data) {
            model = decoded
        } else {
            model = .empty
            save()
        }
    }

    private func save() {
        guard let url = Self.fileURL else { return }
        do {
            let data = try Self.encoder.encode(model)
            try data.write(to: url, options: [.atomic])
        } catch {
            debugLog("Failed to save \(fileName): \(error.localizedDescription)", "LKG")
        }
    }

    private static var fileURL: URL? {
        do {
            let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return support.appendingPathComponent("LastKnownGood.json")
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

