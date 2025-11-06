//
//  InterstitialAdManager.swift
//  MobileAdsClient
//
//  Created by Thanh Hai Khong on 4/2/25.
//

#if canImport(UIKit)
import GoogleMobileAds
import MobileAdsClient

final internal class InterstitialAdManager: NSObject, @unchecked Sendable {
    private let lock = NSLock()
    private var interstitials: [String: InterstitialAd] = [:]
    private var dismissContinuations: [String: CheckedContinuation<Void, Error>] = [:]

    override init() {
        super.init()
    }

    private func getInterstitial(for adUnitID: String) -> InterstitialAd? {
        lock.lock()
        defer { lock.unlock() }
        return interstitials[adUnitID]
    }

    private func setInterstitial(_ ad: InterstitialAd, for adUnitID: String) {
        lock.lock()
        defer { lock.unlock() }
        interstitials[adUnitID] = ad
    }

    private func removeInterstitial(for adUnitID: String) {
        lock.lock()
        defer { lock.unlock() }
        interstitials.removeValue(forKey: adUnitID)
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

extension InterstitialAdManager {
    public func shouldShowAd(_ adUnitID: String, rules: [MobileAdsClient.AdRule]) async -> Bool {
        let isSatisfied = await rules.allRulesSatisfied()

        if getInterstitial(for: adUnitID) == nil {
            do {
                try await loadAd(adUnitID: adUnitID)
                #if DEBUG
                print("🍺 INTERSTITIAL ad loaded successfully")
                #endif
                return isSatisfied
            } catch {
                #if DEBUG
                print("🌶️ Failed to loading INTERSTITIAL ad: \(error.localizedDescription)")
                #endif
                return false
            }
        }

        return isSatisfied
    }

    @MainActor
    public func showAd(_ adUnitID: String, from viewController: UIViewController) async throws {
        guard let ad = getInterstitial(for: adUnitID) else {
            throw MobileAdsClient.AdError.adNotReady
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            setContinuation(continuation, for: adUnitID)
            ad.present(from: viewController)
        }
    }
}

// MARK: - Private Methods

extension InterstitialAdManager {
    private func loadAd(adUnitID: String) async throws {
        let ad = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<InterstitialAd, Error>) in
            let request = Request()
            InterstitialAd.load(with: adUnitID, request: request) { ad, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let ad = ad {
                    ad.fullScreenContentDelegate = self
                    continuation.resume(returning: ad)
                }
            }
        }
        setInterstitial(ad, for: adUnitID)
    }
}

// MARK: - FullScreenContentDelegate

extension InterstitialAdManager: FullScreenContentDelegate {
    private func findAdUnitID(for ad: FullScreenPresentingAd) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return interstitials.first(where: { $0.value === ad })?.key
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

extension InterstitialAd: @retroactive @unchecked Sendable {

}
#endif
