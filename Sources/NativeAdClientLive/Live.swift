//
//  Live.swift
//  MobileAdsClient
//
//  Created by Thanh Hai Khong on 13/2/25.
//

#if canImport(UIKit)
import ComposableArchitecture
import NativeAdClient

extension NativeAdClient: DependencyKey {
    public static let liveValue: NativeAdClient = {
		let actor = NativeActor()
		
        return NativeAdClient(
            loadAd: { adUnitID, viewController, options in
				try await actor.loadAd(
					adUnitID: adUnitID,
					from: viewController,
					options: options
				)
            }
        )
    }()
}
#endif
