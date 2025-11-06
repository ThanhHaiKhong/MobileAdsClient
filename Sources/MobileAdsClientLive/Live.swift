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

                return await withCheckedContinuation { continuation in
                    ATTrackingManager.requestTrackingAuthorization { status in
                        continuation.resume(returning: ())
                    }
                }
            },
            shouldShowAd: { adType, rules in
                return await AdsManager.shared.shouldShowAd(adType, rules: rules)
            },
            showAd: {
                try await AdsManager.shared.showAd()
            }
        )
    }()
}
#endif
