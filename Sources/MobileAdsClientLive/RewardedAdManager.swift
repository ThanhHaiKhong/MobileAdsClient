//
//  RewardedAdManager.swift
//  MobileAdsClient
//
//  Created by Thanh Hai Khong on 4/2/25.
//

#if canImport(UIKit)
import GoogleMobileAds
import MobileAdsClient

final internal class RewardedAdManager: NSObject, @unchecked Sendable {
    private let lock = NSLock()
    private var rewardeds: [String: RewardedAd] = [:]
    private var dismissContinuations: [String: CheckedContinuation<Void, Error>] = [:]

    override init() {
        super.init()
    }

    private func getRewardedAd(for adUnitID: String) -> RewardedAd? {
        lock.lock()
        defer { lock.unlock() }
        return rewardeds[adUnitID]
    }

    private func setRewardedAd(_ ad: RewardedAd, for adUnitID: String) {
        lock.lock()
        defer { lock.unlock() }
        rewardeds[adUnitID] = ad
    }

    private func removeRewardedAd(for adUnitID: String) {
        lock.lock()
        defer { lock.unlock() }
        rewardeds.removeValue(forKey: adUnitID)
    }

    private func setContinuation(_ continuation: CheckedContinuation<Void, Error>, for adUnitID: String) {
        lock.lock()
        defer { lock.unlock() }
        dismissContinuations[adUnitID] = continuation
    }

    private func removeContinuation(for adUnitID: String) -> CheckedContinuation<Void, Error>? {
        lock.lock()
        defer { lock.unlock() }
        return dismissContinuations.removeValue(forKey: adUnitID)
    }
}

// MARK: - Public Methods

extension RewardedAdManager {
    public func shouldShowAd(_ adUnitID: String, rules: [MobileAdsClient.AdRule]) async -> Bool {
        let isSatisfied = await rules.allRulesSatisfied()

        if getRewardedAd(for: adUnitID) == nil {
            do {
                try await loadAd(adUnitID: adUnitID)
                #if DEBUG
                print("🍺 REWARDED ad loaded successfully")
                #endif
                return isSatisfied
            } catch {
                #if DEBUG
                print("🌶️ Failed to loading REWARDED ad: \(error.localizedDescription)")
                #endif
                return false
            }
        }

        return isSatisfied
    }

    @MainActor
    public func showAd(_ adUnitID: String, from viewController: UIViewController) async throws {
        guard let ad = getRewardedAd(for: adUnitID) else {
            throw MobileAdsClient.AdError.adNotReady
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            setContinuation(continuation, for: adUnitID)
            ad.present(from: viewController) {
                // Reward callback can be handled here if needed
            }
        }
    }
}

// MARK: - Private Methods

extension RewardedAdManager {
    private func loadAd(adUnitID: String) async throws {
        let ad = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<RewardedAd, Error>) in
            let request = Request()
            RewardedAd.load(with: adUnitID, request: request) { ad, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let ad = ad {
                    ad.fullScreenContentDelegate = self
                    continuation.resume(returning: ad)
                }
            }
        }
        setRewardedAd(ad, for: adUnitID)
    }
}

// MARK: - FullScreenContentDelegate

extension RewardedAdManager: FullScreenContentDelegate {
    private func findAdUnitID(for ad: FullScreenPresentingAd) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return rewardeds.first(where: { $0.value === ad })?.key
    }

    @objc
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        guard let adUnitID = findAdUnitID(for: ad) else { return }

        removeContinuation(for: adUnitID)?.resume(returning: ())

        Task {
            try? await loadAd(adUnitID: adUnitID)
        }
    }

    @objc
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        guard let adUnitID = findAdUnitID(for: ad) else { return }

        removeContinuation(for: adUnitID)?.resume(throwing: error)
    }
}

extension RewardedAd: @retroactive @unchecked Sendable {

}
#endif
