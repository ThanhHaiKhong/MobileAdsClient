//
//  Live.swift
//  MobileAdsClient
//
//  Created by Thanh Hai Khong on 4/2/25.
//

#if canImport(UIKit)
import AppTrackingTransparency
import ComposableArchitecture
import MobileAdsClient

extension MobileAdsClient: DependencyKey {
    public static let liveValue: Self = {
        return Self(
            requestTrackingAuthorizationIfNeeded: {
                guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
                    return
                }

                await withCheckedContinuation { continuation in
                    ATTrackingManager.requestTrackingAuthorization { _ in
                        continuation.resume(returning: ())
                    }
                }
            },
            shouldShowAd: { adType, rules in
                await AdsManager.shared.shouldShowAd(adType, rules: rules)
            },
            showAd: { adType in
                try await AdsManager.shared.showAd(adType)
            }
        )
    }()
}
#endif
