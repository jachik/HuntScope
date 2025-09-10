//
//  WiFiInfoProvider.swift
//  HuntScope
//
//  Liefert Snapshots und Live-Updates zu WLAN-Status und IP der WLAN-Schnittstelle.
//

import Foundation
import Network
import SwiftUI

struct WiFiSnapshot: Equatable {
    let isWiFiConnected: Bool
    let ipAddress: String?
}

@MainActor
final class WiFiInfoProvider: ObservableObject {
    @Published private(set) var snapshot: WiFiSnapshot = .init(isWiFiConnected: false, ipAddress: nil)

    private let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
    private let queue = DispatchQueue(label: "wifi.monitor.queue")
    private var started = false

    func start() {
        guard !started else { return }
        started = true

        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self else { return }
                let connected = (path.status == .satisfied)
                let ip = Self.wifiIPv4Address()
                self.snapshot = .init(isWiFiConnected: connected, ipAddress: ip)
            }
        }
        monitor.start(queue: queue)

        // Initialer Snapshot
        Task { @MainActor in
            let ip = Self.wifiIPv4Address()
            self.snapshot = .init(isWiFiConnected: false, ipAddress: ip)
        }
    }

    func stop() {
        monitor.cancel()
        started = false
    }

    // MARK: - Static helpers
    static func wifiIPv4Address() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                guard let interface = ptr?.pointee else { continue }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                // BSD-Name der WiFi-Schnittstelle ist üblicherweise "en0"
                let name = String(cString: interface.ifa_name)
                if name == "en0" && addrFamily == sa_family_t(AF_INET) {
                    var addr = interface.ifa_addr.pointee
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                    address = String(cString: hostname)
                    break
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
}
