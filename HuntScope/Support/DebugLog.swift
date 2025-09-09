//
//  DebugLog.swift
//  HuntScope
//
//  Provides a simple global debug logging helper.
//

import Foundation

fileprivate let _debugDateFormatter: DateFormatter = {
    let df = DateFormatter()
    // Calendar year, month, day; 24h hour and minute
    df.dateFormat = "yyyyMMdd-HH:mm"
    df.locale = Locale(identifier: "en_US_POSIX")
    df.timeZone = .current
    return df
}()

/// Prints a formatted debug log line: "YYYYMMDD-HH:mm [Quelle] Meldung"
/// Usage: `debugLog("meldung", "Quelle")`
public func debugLog(_ message: String, _ source: String = "App") {
    #if DEBUG
    let ts = _debugDateFormatter.string(from: Date())
    print("\(ts) [\(source)] \(message)")
    #endif
}

