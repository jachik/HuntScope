//
//  RTSPScanner.swift
//  HuntScope
//
//  Baut die Kandidatenliste für Auto-Connect / Tests auf.
//  Reihenfolge:
//  1) customURL (falls vorhanden)
//  2) LastKnownGood (in gespeicherter Reihenfolge)
//  3) (optional, wenn short == false) Presets – mit Netzwerk-bezogenen Platzhaltern
//  Am Ende dedupliziert (frühe Einträge haben Priorität).
//

import Foundation

struct RTSPScanner {

    // Baut Kandidatenliste auf Basis von App-State
    @MainActor
    static func buildCandidates(short: Bool,
                                config: ConfigStore,
                                wifi: WiFiInfoProvider) -> [String] {
        let custom = config.customStreamURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let lkg = LastKnownGoodStore.shared.entries.map { $0.url }
        let presets = StreamPresetManager.shared.presets
        let snapshot = wifi.snapshot

        return buildCandidates(short: short,
                               customURL: custom.isEmpty ? nil : custom,
                               lastKnownGood: lkg,
                               presets: presets,
                               wifiSnapshot: snapshot)
    }

    // Kernfunktion – gut testbar, ohne Abhängigkeit von Singletons
    static func buildCandidates(short: Bool,
                                customURL: String?,
                                lastKnownGood: [String],
                                presets: [String],
                                wifiSnapshot: WiFiSnapshot?) -> [String] {
        var result: [String] = []

        // 1) custom URL zuerst
        if let u = normalized(url: customURL) { result.append(u) }

        // 2) Last known good (in gespeicherter Reihenfolge)
        for u in lastKnownGood {
            if let n = normalized(url: u) { result.append(n) }
        }

        // 3) Presets (nur wenn Vollscan)
        if !short {
            let ip = wifiSnapshot?.ipAddress
            let net = networkPrefix(from: ip)
            for pattern in presets {
                if let expanded = expand(pattern: pattern, ipAddress: ip, networkPrefix: net) {
                    result.append(expanded)
                }
            }
        }

        // 4) Deduplizieren – frühe Einträge behalten Priorität
        var seen = Set<String>()
        var deduped: [String] = []
        for u in result {
            let key = u.lowercased()
            if !seen.contains(key) {
                seen.insert(key)
                deduped.append(u)
            }
        }
        return deduped
    }

    // MARK: - Helpers

    private static func normalized(url: String?) -> String? {
        guard let s = url?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        return s
    }

    // Liefert z.B. aus 192.168.1.34 => "192.168.1"
    private static func networkPrefix(from ip: String?) -> String? {
        guard let ip, !ip.isEmpty else { return nil }
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return nil }
        return parts.prefix(3).joined(separator: ".")
    }

    // Ersetzt einfache Platzhalter in Preset-Patterns.
    // Unterstützt {ip} => konkrete IP, {network} => die ersten drei Oktette (z.B. 192.168.1)
    private static func expand(pattern: String, ipAddress: String?, networkPrefix: String?) -> String? {
        var out = pattern
        if let ip = ipAddress, out.contains("{ip}") { out = out.replacingOccurrences(of: "{ip}", with: ip) }
        if let net = networkPrefix, out.contains("{network}") { out = out.replacingOccurrences(of: "{network}", with: net) }
        // Falls gar keine Platzhalter, einfach zurückgeben
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
