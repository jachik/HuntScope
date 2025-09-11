//
//  InterstitialViewModel.swift
//  HuntScope
//
//  Created by Jacek Schikora on 09.09.25.
//

//
//  Copyright 2022 Google LLC
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

// [START load_ad]
import GoogleMobileAds
import Combine

@MainActor
class InterstitialViewModel: NSObject, ObservableObject, FullScreenContentDelegate {
  private var interstitialAd: InterstitialAd?
  // Lifecycle hooks to inform UI / scheduler
  var onWillPresent: (() -> Void)?
  var onDidDismiss: (() -> Void)?
  var onFailedToPresent: (() -> Void)?

  // Readiness state so the scheduler can decide a fallback before presenting
  @Published private(set) var isReady: Bool = false

  // Compile-time selection of the ad unit ID
  private var adUnitID: String {
    #if DEBUG
    return "ca-app-pub-3940256099942544/4411468910" // Google test interstitial
    #else
    return "ca-app-pub-6563188845008038/9484101483" // Production interstitial
    #endif
  }

  func loadAd() async {
    do {
      interstitialAd = try await InterstitialAd.load(
        with: adUnitID, request: Request())

      // [START set_the_delegate]
      interstitialAd?.fullScreenContentDelegate = self
      // [END set_the_delegate]
      isReady = true
    } catch {
      print("Failed to load interstitial ad with error: \(error.localizedDescription)")
      isReady = false
    }
  }
  // [END load_ad]

  // [START show_ad]
  func showAd() {
    guard let interstitialAd = interstitialAd else {
      return print("Ad wasn't ready.")
    }
    // Double-check presentability just before presenting
    do {
      try interstitialAd.canPresent(from: nil)
    } catch {
      print("Interstitial cannot present: \(error.localizedDescription)")
      isReady = false
      onFailedToPresent?()
      return
    }
    interstitialAd.present(from: nil)
  }
  // [END show_ad]

  // MARK: - GADFullScreenContentDelegate methods

  // [START ad_events]
  func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
    print("\(#function) called")
  }

  func adDidRecordClick(_ ad: FullScreenPresentingAd) {
    print("\(#function) called")
  }

  func ad(
    _ ad: FullScreenPresentingAd,
    didFailToPresentFullScreenContentWithError error: Error
  ) {
    print("\(#function) called")
    isReady = false
    interstitialAd = nil
    onFailedToPresent?()
  }

  func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
    print("\(#function) called")
    isReady = false
    onWillPresent?()
  }

  func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
    print("\(#function) called")
  }

  func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
    print("\(#function) called")
    // Clear the interstitial ad.
    interstitialAd = nil
    isReady = false
    onDidDismiss?()
  }
  // [END ad_events]
}
