//
//  AppDelegate.swift
//  HuntScope
//
//  Created by Jacek Schikora on 09.09.25.
//

import UIKit
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Sanity-Check: sieht die App die App-ID wirklich?
        let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String
        assert(appID?.hasPrefix("ca-app-pub-") == true, "GADApplicationIdentifier fehlt/ungueltig: \(String(describing: appID))")

        MobileAds.shared.start()

        return true
    }
}
