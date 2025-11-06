//
//  AdManager.swift
//  MobileAdsClient
//
//  Created by Thanh Hai Khong on 4/2/25.
//

#if canImport(UIKit)
import GoogleMobileAds
import MobileAdsClient

final internal actor AdsManager {
    internal static let shared = AdsManager()
    
    private let openAdManager = OpenAdManager()
    private let interstitialAdManager = InterstitialAdManager()
    private let rewardedAdManager = RewardedAdManager()
    private var lastAdType: MobileAdsClient.AdType?
    
    private init() {
        MobileAds.shared.start(completionHandler: nil)
    }
}

// MARK: - Public Methods

extension AdsManager {
    internal func shouldShowAd(_ adType: MobileAdsClient.AdType, rules: [MobileAdsClient.AdRule]) async -> Bool {
        let shouldShow: Bool

        switch adType {
        case let .appOpen(adUnitID):
            shouldShow = await openAdManager.shouldShowAd(adUnitID, rules: rules)

        case let .interstitial(adUnitID):
            shouldShow = await interstitialAdManager.shouldShowAd(adUnitID, rules: rules)

        case let .rewarded(adUnitID):
            shouldShow = await rewardedAdManager.shouldShowAd(adUnitID, rules: rules)
        }

        // Only store the ad type if it will actually be shown
        if shouldShow {
            lastAdType = adType
        }

        return shouldShow
    }
    
    @MainActor
    internal func showAd() async throws {
        guard let rootVC = UIApplication.shared.topViewController(), let adType = await lastAdType else {
            return
        }
        
        switch adType {
        case let .appOpen(adUnitID):
            try await openAdManager.showAd(adUnitID, from: rootVC)
            
        case let .interstitial(adUnitID):
            try await interstitialAdManager.showAd(adUnitID, from: rootVC)
            
        case let .rewarded(adUnitID):
            try await rewardedAdManager.showAd(adUnitID, from: rootVC)
        }

        debugPrint("👉 The \(adType.description) ad has been closed, proceeding with the next action!")
    }
}
#endif
