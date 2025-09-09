//
//  ConfigStore.swift
//  HuntScope
//
//  Created by Jacek Schikora on 08.09.25.
//

import Foundation
import Combine

// Reines Farbmodell: passe dies an deine zentrale Theme-Quelle an.
enum AppTheme: String, CaseIterable, Codable {
    case red
    case white
}

@MainActor
final class ConfigStore: ObservableObject {
    // Published -> direkt als $store.streamURL bindbar
    @Published var streamURL: String
    @Published var customStreamURL: String
    @Published var theme: AppTheme = .red


    private var saveDebounce: AnyCancellable?

    init(manager: ConfigManager = .shared) {
        self.streamURL = manager.streamURL
        self.customStreamURL = manager.customStreamURL
        self.theme = manager.theme

        // Debounced Autosave (verhindert exzessives Schreiben bei Tippen)
        saveDebounce = Publishers.CombineLatest($streamURL, $customStreamURL)
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { url, custom in
                let m = ConfigManager.shared
                if m.streamURL != url { m.streamURL = url }
                if m.customStreamURL != custom { m.customStreamURL = custom }
            }

        // Persistiere Theme-Wechsel sofort
        _ = $theme
            .removeDuplicates()
            .sink { newTheme in
                let m = ConfigManager.shared
                if m.theme != newTheme {
                    m.theme = newTheme
                }
            }
    }

    func reloadFromDisk() {
        // Falls du spaeter externe Aenderungen erlaubst
        streamURL = ConfigManager.shared.streamURL
        customStreamURL = ConfigManager.shared.customStreamURL
        theme = ConfigManager.shared.theme
    }
}
