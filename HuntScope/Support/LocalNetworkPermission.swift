//
//  LocalNetworkPermission.swift
//  HuntScope
//
//  Triggers the iOS local network privacy prompt once and optionally waits briefly
//  before starting scans, so the first run does not finish prematurely.
//

import Foundation
import Network

@MainActor
final class LocalNetworkPermission {
    static let shared = LocalNetworkPermission()
    private let attemptedKey = "LocalNetworkPermission_PrimedOnce"
    private let attemptedBonjourKey = "LocalNetworkPermission_PrimedBonjourOnce"

    func primeIfNeeded(wifi: WiFiSnapshot?) async {
        // Only attempt once; OS will remember the user’s choice.
        if UserDefaults.standard.bool(forKey: attemptedKey) {
            return
        }
        UserDefaults.standard.set(true, forKey: attemptedKey)

        // Derive a likely local host (gateway .1) from current Wi-Fi IP.
        let host: String = Self.deriveLocalHost(from: wifi?.ipAddress) ?? "192.168.0.1"
        let queue = DispatchQueue(label: "local.permission.prime")
        let conn = NWConnection(host: NWEndpoint.Host(host), port: 80, using: .tcp)
        conn.stateUpdateHandler = { state in
            switch state {
            case .ready: debugLog("LocalNet prime: ready", "Perm")
            case .failed(let e): debugLog("LocalNet prime: failed=\(e.localizedDescription)", "Perm")
            case .waiting(let e): debugLog("LocalNet prime: waiting=\(e.localizedDescription)", "Perm")
            default: break
            }
        }
        conn.start(queue: queue)
        // Give the system a moment to display and process the prompt.
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        conn.cancel()
    }

    func primeNow(wifi: WiFiSnapshot?) {
        // Only once per install/session; OS shows prompt only once anyway.
        if UserDefaults.standard.bool(forKey: attemptedKey) { return }
        UserDefaults.standard.set(true, forKey: attemptedKey)

        // Build a small set of likely local hosts
        var hosts: [String] = []
        if let derived = Self.deriveLocalHost(from: wifi?.ipAddress) { hosts.append(derived) }
        hosts.append(contentsOf: [
            "192.168.0.1",
            "192.168.1.1",
            "192.168.11.1",
            "192.168.42.1",
            "10.0.0.1",
            "172.16.0.1"
        ])
        let ports: [UInt16] = [80, 554]

        let queue = DispatchQueue(label: "local.permission.prime.now")
        for h in hosts {
            for p in ports {
                guard let port = NWEndpoint.Port(rawValue: p) else { continue }
                let conn = NWConnection(host: NWEndpoint.Host(h), port: port, using: .tcp)
                conn.stateUpdateHandler = { state in
                    switch state {
                    case .ready: debugLog("LocalNet primeNow: ready \(h):\(p)", "Perm")
                    case .failed(let e): debugLog("LocalNet primeNow: failed \(h):\(p) = \(e.localizedDescription)", "Perm")
                    case .waiting(let e): debugLog("LocalNet primeNow: waiting \(h):\(p) = \(e.localizedDescription)", "Perm")
                    default: break
                    }
                }
                conn.start(queue: queue)
                // Cancel after a brief moment (non-blocking)
                queue.asyncAfter(deadline: .now() + 3.0) {
                    conn.cancel()
                }
            }
        }
    }

    func primeBonjourIfNeeded() {
        if UserDefaults.standard.bool(forKey: attemptedBonjourKey) { return }
        UserDefaults.standard.set(true, forKey: attemptedBonjourKey)
        // Browse common service types shortly to trigger prompt reliably
        let types = ["_rtsp._tcp.", "_http._tcp."]
        let queue = DispatchQueue(label: "local.permission.prime.bonjour")
        for t in types {
            let browser = NWBrowser(for: .bonjour(type: t, domain: nil), using: NWParameters())
            browser.stateUpdateHandler = { state in
                switch state {
                case .ready: debugLog("Bonjour prime: ready (\(t))", "Perm")
                case .failed(let e): debugLog("Bonjour prime: failed (\(t)) = \(e.localizedDescription)", "Perm")
                default: break
                }
            }
            browser.browseResultsChangedHandler = { _, _ in }
            browser.start(queue: queue)
            queue.asyncAfter(deadline: .now() + 2.0) {
                browser.cancel()
            }
        }
    }

    private static func deriveLocalHost(from ip: String?) -> String? {
        guard let ip, !ip.isEmpty else { return nil }
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return nil }
        return parts.prefix(3).joined(separator: ".") + ".1"
    }
}
