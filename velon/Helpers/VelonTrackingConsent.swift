//
//  VelonTrackingConsent.swift
//  velon
//

import AppTrackingTransparency
import UIKit

enum VelonTrackingConsent {
    /// Call when the scene becomes active. Shows the system ATT prompt only while status is notDetermined.
    static func requestIfNeededWhenActive() {
        guard #available(iOS 14, *) else { return }
        guard UIApplication.shared.applicationState == .active else { return }
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard UIApplication.shared.applicationState == .active else { return }
            guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
            ATTrackingManager.requestTrackingAuthorization { _ in
                // Allowed or denied: the App remains fully usable either way.
            }
        }
    }
}
