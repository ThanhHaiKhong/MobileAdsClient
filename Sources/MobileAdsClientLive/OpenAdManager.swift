//
//  OpenAdManager.swift
//  MobileAdsClient
//
//  Created by Thanh Hai Khong on 4/2/25.
//

#if canImport(UIKit)
import GoogleMobileAds
import MobileAdsClient

final internal class OpenAdManager: NSObject, @unchecked Sendable {
    private let lock = NSLock()
    private var appOpenAds: [String: AppOpenAd] = [:]
    private var dismissContinuations: [String: CheckedContinuation<Void, Error>] = [:]

    override init() {
        super.init()
    }

    private func getAppOpenAd(for adUnitID: String) -> AppOpenAd? {
        lock.lock()
        defer { lock.unlock() }
        return appOpenAds[adUnitID]
    }

    private func setAppOpenAd(_ ad: AppOpenAd, for adUnitID: String) {
        lock.lock()
        defer { lock.unlock() }
        appOpenAds[adUnitID] = ad
    }

    private func removeAppOpenAd(for adUnitID: String) {
        lock.lock()
        defer { lock.unlock() }
        appOpenAds.removeValue(forKey: adUnitID)
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

extension OpenAdManager {
    public func shouldShowAd(_ adUnitID: String, rules: [MobileAdsClient.AdRule]) async -> Bool {
        let isSatisfied = await rules.allRulesSatisfied()

        if getAppOpenAd(for: adUnitID) == nil {
            do {
                try await loadAd(adUnitID: adUnitID)
                #if DEBUG
                print("🍺 APP_OPEN ad loaded successfully: \(isSatisfied)")
                #endif
                return isSatisfied
            } catch {
                #if DEBUG
                print("🌶️ Failed to loading APP_OPEN ad: \(error.localizedDescription)")
                #endif
                return false
            }
        }

        return isSatisfied
    }

    @MainActor
    public func showAd(_ adUnitID: String, from viewController: UIViewController) async throws {
        guard let ad = getAppOpenAd(for: adUnitID) else {
            throw MobileAdsClient.AdError.adNotReady
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            setContinuation(continuation, for: adUnitID)
            ad.present(from: viewController)
        }
    }
}

// MARK: - Private Methods

extension OpenAdManager {
    private func loadAd(adUnitID: String) async throws {
        let ad = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AppOpenAd, Error>) in
            let request = Request()
            AppOpenAd.load(with: adUnitID, request: request) { ad, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let ad = ad {
                    ad.fullScreenContentDelegate = self
                    continuation.resume(returning: ad)
                }
            }
        }
        setAppOpenAd(ad, for: adUnitID)
    }
}

// MARK: - FullScreenContentDelegate

extension OpenAdManager: FullScreenContentDelegate {
    private func findAdUnitID(for ad: FullScreenPresentingAd) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return appOpenAds.first(where: { $0.value === ad })?.key
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

extension AppOpenAd: @retroactive @unchecked Sendable {

}
#endif
