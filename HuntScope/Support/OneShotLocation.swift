//
//  OneShotLocation.swift
//  HuntScope
//
//  Simple one-shot location fetcher for tagging snapshots.
//

import Foundation
import CoreLocation

@MainActor
final class OneShotLocation: NSObject, CLLocationManagerDelegate {
    static let shared = OneShotLocation()

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?
    private var timeoutTask: Task<Void, Never>? = nil

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func currentLocation(timeout: TimeInterval = 4.0) async -> CLLocation? {
        // Check/Request authorization (WhenInUse is sufficient)
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            // wait a moment for user to respond or system to update
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        case .restricted, .denied:
            return nil
        default:
            break
        }

        // Still denied after prompt?
        let st2 = CLLocationManager.authorizationStatus()
        if st2 == .restricted || st2 == .denied { return nil }

        // Request a single location
        return await withCheckedContinuation { (cont: CheckedContinuation<CLLocation?, Never>) in
            self.continuation = cont
            self.manager.requestLocation()
            // Timeout safety
            self.timeoutTask?.cancel()
            self.timeoutTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                await self?.finish(nil)
            }
        }
    }

    private func finish(_ loc: CLLocation?) {
        timeoutTask?.cancel(); timeoutTask = nil
        if let c = continuation { continuation = nil; c.resume(returning: loc) }
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Choose the most recent location
        let loc = locations.last
        finish(loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(nil)
    }
}

