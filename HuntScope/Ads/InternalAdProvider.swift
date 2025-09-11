//
//  InternalAdProvider.swift
//  HuntScope
//
//  Discovers and picks a random localized internal ad (MP4) by ID pattern ad01, ad02, ...
//

import Foundation

struct InternalAdProvider {
    /// Returns the URL for a localized internal ad by ID (e.g., "ad01").
    static func url(forAdID id: String) -> URL? {
        // Preferred: localized resource in the main bundle
        if let url = Bundle.main.url(forResource: id, withExtension: "mp4") {
            return url
        }
        // Optional: localized resource under an 'Ads' folder reference
        if let url = Bundle.main.url(forResource: id, withExtension: "mp4", subdirectory: "Ads") {
            return url
        }
        return nil
    }

    /// Build a list of available IDs by probing ad01...adNN
    static func availableAdIDs(range: ClosedRange<Int> = 1...10, baseName: String = "ad") -> [String] {
        var ids: [String] = []
        for i in range {
            let id = String(format: "%@%02d", baseName, i)
            if url(forAdID: id) != nil {
                ids.append(id)
            }
        }
        return ids
    }

    /// Pick a random available ad ID. Returns nil if none found.
    static func chooseRandomAdID(range: ClosedRange<Int> = 1...10, baseName: String = "ad") -> String? {
        let candidates = availableAdIDs(range: range, baseName: baseName)
        return candidates.randomElement()
    }
}

