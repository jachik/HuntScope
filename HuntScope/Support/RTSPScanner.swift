//
//  RTSPScanner.swift
//  HuntScope
//
//  Baut die Kandidatenliste für Auto-Connect / Tests auf.
//  Reihenfolge:
//  1) customURL (falls vorhanden)
//  2) LastKnownGood (in gespeicherter Reihenfolge)
//  3) Presets – gefiltert auf das aktuelle WLAN-/24-Netz
//  Am Ende dedupliziert (frühe Einträge haben Priorität).
//

import Foundation

struct RTSPScanner {

    // Baut Kandidatenliste auf Basis von App-State
    @MainActor
    static func buildCandidates(config: ConfigStore,
                                wifi: WiFiInfoProvider) -> [String] {
        let custom = config.customStreamURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let lkg = LastKnownGoodStore.shared.entries.map { $0.url }
        let presets = StreamPresetManager.shared.presets
        let snapshot = wifi.snapshot

        return buildCandidates(customURL: custom.isEmpty ? nil : custom,
                               lastKnownGood: lkg,
                               presets: presets,
                               wifiSnapshot: snapshot)
    }

    // Kernfunktion – gut testbar, ohne Abhängigkeit von Singletons
    static func buildCandidates(customURL: String?,
                                lastKnownGood: [String],
                                presets: [String],
                                wifiSnapshot: WiFiSnapshot?) -> [String] {
        var result: [String] = []

        // Debug: Eingangsdaten
        #if DEBUG
        let dbgCustom = (customURL?.isEmpty == false)
        debugLog("scanner: custom=\(dbgCustom), lkg=\(lastKnownGood.count), presets=\(presets.count)", "RTSP")
        debugLog("scanner: wifi ip=\(wifiSnapshot?.ipAddress ?? "nil")", "RTSP")
        #endif

        // 1) custom URL zuerst
        if let u = normalized(url: customURL) { result.append(u) }

        // 2) Last known good (in gespeicherter Reihenfolge)
        for u in lastKnownGood {
            if let n = normalized(url: u) { result.append(n) }
        }

        // 3) Presets (immer, da nur vollständiger Scan unterstützt wird)
        let ip = wifiSnapshot?.ipAddress
        let net = networkPrefix(from: ip)
        var matched = 0
        var skipped = 0
        if let currentNet = net {
            for pattern in presets {
                let candidate = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !candidate.isEmpty else { continue }
                if let hostIP = ipv4Host(from: candidate), let hostNet = networkPrefix(from: hostIP) {
                    if hostNet == currentNet { result.append(candidate); matched += 1 } else { skipped += 1 }
                } else {
                    skipped += 1
                }
            }
        } else {
            // Kein WLAN-IP bekannt: konservativ alle Presets aufnehmen
            for pattern in presets {
                let candidate = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !candidate.isEmpty else { continue }
                result.append(candidate)
                matched += 1
            }
        }
        #if DEBUG
        debugLog("scanner: presets matched=\(matched), skipped=\(skipped)", "RTSP")
        #endif

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
        #if DEBUG
        debugLog("scanner: deduped=\(deduped.count)", "RTSP")
        #endif
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

    // Extrahiert eine IPv4-Adresse aus der URL (Host-Teil) – erwartet rtsp://<ip>[:port]/...
    private static func ipv4Host(from urlString: String) -> String? {
        if let comps = URLComponents(string: urlString), let host = comps.host {
            if isIPv4(host) { return host }
        }
        // Fallback: Regex-Suche nach IPv4-Muster
        let pattern = #"\b((?:\d{1,3}\.){3}\d{1,3})\b"#
        if let re = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: (urlString as NSString).length)
            if let m = re.firstMatch(in: urlString, options: [], range: range) {
                if let r = Range(m.range(at: 1), in: urlString) {
                    let ip = String(urlString[r])
                    return isIPv4(ip) ? ip : nil
                }
            }
        }
        return nil
    }

    private static func isIPv4(_ s: String) -> Bool {
        let parts = s.split(separator: ".")
        if parts.count != 4 { return false }
        for p in parts {
            guard let v = Int(p), v >= 0 && v <= 255 else { return false }
        }
        return true
    }

    // MARK: - Scanning
    // Scannt Kandidatenliste, gruppiert nach Host/IP. Pro Host werden Ressourcen sequentiell getestet,
    // verschiedene Hosts laufen parallel. Abbruch erst bei erstem 200 OK.
    @MainActor
    static func scan(config: ConfigStore,
                     wifi: WiFiInfoProvider,
                     cancel: @escaping () -> Bool = { false },
                     progress: ((Int, Int) -> Void)? = nil) async -> String? {
        let candidates = buildCandidates(config: config, wifi: wifi)
        let total = candidates.count
        if total == 0 { return nil }

        progress?(0, total)

        // Gruppieren nach Host
        var groups: [String: [String]] = [:]
        for url in candidates {
            if let host = URLComponents(string: url)?.host { groups[host, default: []].append(url) }
        }
        var completed = 0

        return await withTaskGroup(of: String?.self) { group in
            for (_, urls) in groups {
                group.addTask {
                    for u in urls {
                        if cancel() { return nil }
                        let res = await RTSPProbe.probe(url: u)
                        await MainActor.run {
                            completed += 1
                            progress?(completed, total)
                        }
                        switch res {
                        case .success:
                            return u
                        case .failure:
                            continue
                        }
                    }
                    return nil
                }
            }

            var found: String? = nil
            for await r in group {
                if let u = r { found = u; group.cancelAll(); break }
            }
            return found
        }
    }
}
