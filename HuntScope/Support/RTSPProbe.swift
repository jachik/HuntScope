//
//  RTSPProbe.swift
//  HuntScope
//
//  Einfacher RTSP-Check über TCP: Verbindet zu host:port und sendet einen DESCRIBE.
//  Erfolg nur bei HTTP-Status 200 in der RTSP-Antwort.
//

import Foundation
import Network

enum RTSPProbeResult {
    case success
    case failure(String)
}

enum RTSPProbeError: Error {
    case invalidURL
    case timeout
    case connectionFailed(String)
    case receiveFailed
}

struct RTSPProbe {
    static func probe(url urlString: String,
                      connectTimeout: TimeInterval = 1.0,
                      ioTimeout: TimeInterval = 0.8) async -> RTSPProbeResult {
        guard let comps = URLComponents(string: urlString),
              let host = comps.host,
              let scheme = comps.scheme, scheme.lowercased().hasPrefix("rtsp") else {
            return .failure("invalid_url")
        }
        let portValue: Int = comps.port ?? 554
        guard let port = NWEndpoint.Port(rawValue: UInt16(portValue)) else {
            return .failure("invalid_port")
        }

        let connection = NWConnection(host: NWEndpoint.Host(host), port: port, using: .tcp)
        let queue = DispatchQueue(label: "rtsp.probe.queue")

        // Connect with timeout
        let connected: Bool = await withCheckedContinuation { cont in
            var didResume = false
            func resume(_ ok: Bool) {
                if !didResume { didResume = true; cont.resume(returning: ok) }
            }
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    resume(true)
                case .failed(let err):
                    debugLog("RTSPProbe connect failed: \(err.localizedDescription)", "RTSP")
                    resume(false)
                default:
                    break
                }
            }
            connection.start(queue: queue)
            queue.asyncAfter(deadline: .now() + connectTimeout) {
                resume(false)
            }
        }

        guard connected else {
            connection.cancel()
            return .failure("connect_timeout")
        }

        // Build DESCRIBE request
        let request = "DESCRIBE \(urlString) RTSP/1.0\r\nCSeq: 1\r\nUser-Agent: HuntScope\r\nAccept: application/sdp\r\n\r\n"
        let reqData = request.data(using: .utf8) ?? Data()

        // Send
        let sendOK: Bool = await withCheckedContinuation { cont in
            connection.send(content: reqData, completion: .contentProcessed { err in
                if let err = err {
                    debugLog("RTSPProbe send failed: \(err.localizedDescription)", "RTSP")
                    cont.resume(returning: false)
                } else { cont.resume(returning: true) }
            })
        }
        guard sendOK else { connection.cancel(); return .failure("send_failed") }

        // Receive minimal response
        let recv: Data? = await withCheckedContinuation { cont in
            var didResume = false
            func resume(_ d: Data?) { if !didResume { didResume = true; cont.resume(returning: d) } }
            connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, isComplete, err in
                if let err = err {
                    debugLog("RTSPProbe recv failed: \(err.localizedDescription)", "RTSP")
                    resume(nil)
                } else {
                    resume(data)
                }
            }
            queue.asyncAfter(deadline: .now() + ioTimeout) { resume(nil) }
        }
        connection.cancel()

        guard let data = recv, !data.isEmpty else { return .failure("recv_timeout") }
        let line = String(decoding: data, as: UTF8.self).components(separatedBy: "\r\n").first ?? ""
        // Expect: RTSP/1.0 200 OK
        if let code = parseStatusCode(from: line), code == 200 {
            return .success
        } else {
            return .failure(line.isEmpty ? "no_status" : line)
        }
    }

    private static func parseStatusCode(from statusLine: String) -> Int? {
        // e.g., "RTSP/1.0 200 OK"
        let parts = statusLine.split(separator: " ")
        guard parts.count >= 2, let code = Int(parts[1]) else { return nil }
        return code
    }
}

