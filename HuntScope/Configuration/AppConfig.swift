//
//  AppConfig.swift
//  HuntScope
//
//  Created by Jacek Schikora on 08.09.25.
//

import Foundation

struct AppConfig: Codable {
    var streamURL: String
    var customStreamURL: String
    var theme: AppTheme
    var lastBackgroundAt: Date? = nil
    var hasLaunchedBefore: Bool = false


    // Standard-Werte (falls Datei noch nicht existiert)
    static let `default` = AppConfig(
        streamURL: "rtsp://192.168.11.220/1/h264major",
        customStreamURL: "",
        theme: .red,
        lastBackgroundAt: nil,
        hasLaunchedBefore: false
    )
}

final class ConfigManager {
    static let shared = ConfigManager()

    private let fileName = "Settings.json"
    private var config: AppConfig

    private init() {
        // Versuche zu laden, sonst Defaults
        if let loaded = try? Self.loadFromDisk() {
            self.config = loaded
        } else {
            self.config = AppConfig.default
            save() // Defaults gleich ablegen
        }
    }

    // Zugriff auf Werte
    var streamURL: String {
        get { config.streamURL }
        set {
            config.streamURL = newValue
            save()
        }
    }

    var customStreamURL: String {
        get { config.customStreamURL }
        set {
            config.customStreamURL = newValue
            save()
        }
    }
    
    var theme: AppTheme {
        get { config.theme }
        set {
            config.theme = newValue
            save()
        }
    }

    var lastBackgroundAt: Date? {
        get { config.lastBackgroundAt }
        set {
            config.lastBackgroundAt = newValue
            save()
        }
    }

    var hasLaunchedBefore: Bool {
        get { config.hasLaunchedBefore }
        set {
            config.hasLaunchedBefore = newValue
            save()
        }
    }

    // MARK: - Persistenz
    private func save() {
        if let url = Self.fileURL {
            try? JSONEncoder().encode(config).write(to: url)
        }
    }

    private static func loadFromDisk() throws -> AppConfig {
        guard let url = fileURL else { throw NSError(domain: "Config", code: -1) }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(AppConfig.self, from: data)
    }

    private static var fileURL: URL? {
        do {
            let support = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            return support.appendingPathComponent("Settings.json")
        } catch {
            return nil
        }
    }
}
