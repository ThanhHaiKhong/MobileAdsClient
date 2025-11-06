//
//  Mocks.swift
//  MobileAdsClient
//
//  Created by Thanh Hai Khong on 4/2/25.
//

import ComposableArchitecture

extension DependencyValues {
	public var mobileAdsClient: MobileAdsClient {
		get { self[MobileAdsClient.self] }
		set { self[MobileAdsClient.self] = newValue }
	}
}

extension MobileAdsClient: TestDependencyKey {
    public static let testValue: MobileAdsClient = {
        return Self(
            requestTrackingAuthorizationIfNeeded: { },
            shouldShowAd: { _, _ in true },
            showAd: { }
        )
    }()

    public static let previewValue: MobileAdsClient = {
        return Self(
            requestTrackingAuthorizationIfNeeded: { },
            shouldShowAd: { _, _ in true },
            showAd: {
                // Simulate ad display delay for previews
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
        )
    }()
}
