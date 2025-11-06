//
//  NativeAdClient.swift
//  MobileAdsClient
//
//  Created by Thanh Hai Khong on 13/2/25.
//

import DependenciesMacros
#if canImport(UIKit)
import GoogleMobileAds
import UIKit

@DependencyClient
public struct NativeAdClient: Sendable {
	public var loadAd: @Sendable (_ adUnitID: String, _ rootViewController: UIViewController?, _ options: [NativeAdClient.AnyAdLoaderOption]?) async throws -> NativeAd
}
#endif
