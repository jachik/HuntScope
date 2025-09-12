//
//  Obfuscation.swift
//  HuntScope
//
//  Simple XOR + Base64 obfuscation helper used for stream presets.
//  This is not cryptographic security; it only deters casual inspection.
//

import Foundation

enum Obfuscator {
    // Static key (duplicate in build script). 16 bytes.
    // If you change this, regenerate StreamPresets.json via the build script.
    private static let key: [UInt8] = [
        0x7f, 0x11, 0xa9, 0x23, 0x5d, 0xc4, 0x8b, 0xee,
        0x01, 0x37, 0x49, 0x2a, 0x6c, 0xd0, 0x9e, 0x3b
    ]

    static func decodeBase64XOR(_ base64: String) -> String? {
        guard let data = Data(base64Encoded: base64) else { return nil }
        var out = Data(capacity: data.count)
        for (i, b) in data.enumerated() {
            out.append(b ^ key[i % key.count])
        }
        return String(data: out, encoding: .utf8)
    }
}

