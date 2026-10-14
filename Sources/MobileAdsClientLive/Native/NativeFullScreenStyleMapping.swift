//
//  NativeFullScreenStyleMapping.swift
//  MobileAdsClient
//
//  Translates a caller's close-gate request into the renderer's configuration.
//

#if canImport(UIKit)
import ComposableArchitecture
import MobileAdsClient
import NativeAdClient

extension MobileAdsClient {
    /// The host's app-wide appearance for the native full-screen ad, built with the
    /// `NativeAdClient` `Style` API. Set once at launch; `nil` keeps the renderer's
    /// `.default`. The funnel's close gate is layered on in `applying(_:)`, not here.
    public static func configureNativeFullScreen(_ config: NativeAdClient.Configuration.FullScreen?) {
        nativeFullScreenStore.setValue(config)
    }

    static let nativeFullScreenStore = LockIsolated<NativeAdClient.Configuration.FullScreen?>(nil)
}

extension NativeAdClient.Configuration.FullScreen {
    /// The renderer config for a present: the host's `configureNativeFullScreen`
    /// base (else `.default`), with the funnel's close gate overlaid on top. The one
    /// place `MobileAdsClient`'s vocabulary and `NativeAdClient`'s config meet.
    static func applying(_ style: MobileAdsClient.NativeFullScreenStyle?) -> Self {
        var configuration = MobileAdsClient.nativeFullScreenStore.value ?? .default
        if let style {
            configuration.closeCountdown = style.closeCountdownSeconds
            configuration.closeHitSlop = style.closeHitSlop
        }
        return configuration
    }
}
#endif
