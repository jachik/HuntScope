//
//  InterstitialAdScheduler.swift
//  HuntScope
//
//  Schedules interstitial ads at random intervals (7–17 min),
//  preloads/caches ads between shows, and respects app state.
//

import Foundation
import SwiftUI

@MainActor
final class InterstitialAdScheduler {
    private let interstitial: InterstitialViewModel
    private let ui: UIStateModel
    private let player: PlayerController
    private let entitlements: EntitlementStore?

    private var timer: Timer?
    private(set) var nextFireAt: Date?
    private var lastShownAt: Date?

    // Tunables
    private let minGapAfterStart: TimeInterval = 60        // no ad immediately after start/splash
    private let retryWhenBlocked: TimeInterval = 60        // retry if dialog/recording blocks
    private let preloadRetry: TimeInterval = 30            // retry soon if not loaded yet
    private let minGapBetweenShows: TimeInterval = 120     // safety gap

    private var entitlementObserver: NSObjectProtocol?

    init(interstitial: InterstitialViewModel, ui: UIStateModel, player: PlayerController, entitlements: EntitlementStore? = nil) {
        self.interstitial = interstitial
        self.ui = ui
        self.player = player
        self.entitlements = entitlements
    }

    func start() {
        // If premium is active, keep ads disabled
        if entitlements?.isPremiumActive == true {
            stop()
            beginObservingEntitlementChanges()
            return
        }
        // Preload immediately
        Task { await interstitial.loadAd() }
        // Bridge ad lifecycle -> UI state
        interstitial.onWillPresent = { [weak self] in
            guard let self = self else { return }
            self.ui.isAdActive = true
        }
        interstitial.onDidDismiss = { [weak self] in
            guard let self = self else { return }
            self.ui.isAdActive = false
            // Suppress overlays briefly after ad to avoid flicker
            self.ui.suppressOverlaysUntil = Date().addingTimeInterval(3)
        }
        interstitial.onFailedToPresent = { [weak self] in
            guard let self = self else { return }
            self.presentInternalAd()
        }
        // Schedule first window a bit after start
        scheduleNext(from: Date().addingTimeInterval(minGapAfterStart))
        beginObservingEntitlementChanges()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // If the planned fire was missed while backgrounded, give a short grace then try
            if let fire = nextFireAt, fire < Date() {
                reschedule(in: 45)
            }
        case .background:
            // Pause timers while in background; they don't fire reliably there
            stop()
        default:
            break
        }
    }

    // MARK: - Internals

    private func scheduleNext(from date: Date) {
        let delayMinutes = Int.random(in: 7...17) // 7–17 minutes
        let delay = TimeInterval(delayMinutes * 60)
        let fireAt = date.addingTimeInterval(delay)
        nextFireAt = fireAt
        let interval = max(0, fireAt.timeIntervalSinceNow)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.attemptShow()
            }
        }
        if let t = timer { RunLoop.main.add(t, forMode: .common) }
        debugLog("scheduled in \(Int(interval))s (next \(delayMinutes) min)", "Ads")
    }

    private func reschedule(in seconds: TimeInterval) {
        nextFireAt = Date().addingTimeInterval(seconds)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.attemptShow()
            }
        }
        if let t = timer { RunLoop.main.add(t, forMode: .common) }
        debugLog("rescheduled in \(Int(seconds))s", "Ads")
    }

    private func attemptShow() {
        guard shouldShowNow() else {
            reschedule(in: retryWhenBlocked)
            return
        }
        // Decide whether to show internal ad instead of AdMob
        let divertToInternal: Bool = {
            // 1) If AdMob not ready
            if !interstitial.isReady { return true }
            // 2) Random 1/6 chance
            return Int.random(in: 1...6) == 1
        }()

        if divertToInternal {
            presentInternalAd()
            // Preload next interstitial for future use
            Task { await interstitial.loadAd() }
            // Plan the next regular window
            scheduleNext(from: Date())
            return
        }

        // Try to present external ad; if it fails, delegate will fall back
        interstitial.showAd()
        lastShownAt = Date()
        // Preload next ad
        Task { await interstitial.loadAd() }
        // Plan the next regular window
        scheduleNext(from: Date())
    }

    private func shouldShowNow() -> Bool {
        if entitlements?.isPremiumActive == true { return false }
        if ui.isDialogActive { return false }
        if player.isRecording { return false }
        if let last = lastShownAt, Date().timeIntervalSince(last) < minGapBetweenShows { return false }
        return true
    }

    deinit {
        if let token = entitlementObserver {
            NotificationCenter.default.removeObserver(token)
        }
    }
}

// MARK: - Internal helpers
extension InterstitialAdScheduler {
    fileprivate func presentInternalAd() {
        if entitlements?.isPremiumActive == true { return }
        if ui.isAdDialogPresented { return }
        if let id = InternalAdProvider.chooseRandomAdID(range: 1...10) {
            ui.internalAdID = id
        } else {
            ui.internalAdID = "ad01" // fallback id
        }
        ui.isAdDialogPresented = true
    }
}

// MARK: - Entitlement observation
private extension InterstitialAdScheduler {
    func beginObservingEntitlementChanges() {
        guard entitlementObserver == nil else { return }
        entitlementObserver = NotificationCenter.default.addObserver(forName: .premiumStatusChanged, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            if self.entitlements?.isPremiumActive == true {
                self.stop()
                // Ensure any internal ad overlay is closed
                self.ui.isAdDialogPresented = false
                self.ui.isAdActive = false
            } else {
                // Resume scheduling if previously stopped
                if self.timer == nil {
                    self.start()
                }
            }
        }
    }
}
