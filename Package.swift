// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MobileAdsClient",
    platforms: [
		.iOS(.v15)
    ],
    products: [
        .singleTargetLibrary("MobileAdsClient"),
        .singleTargetLibrary("MobileAdsClientLive"),
        .singleTargetLibrary("MobileAdsClientUI"),
        .singleTargetLibrary("NativeAdClient"),
        .singleTargetLibrary("NativeAdClientLive"),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", branch: "main"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", branch: "main"),
        .package(url: "https://github.com/ThanhHaiKhong/TCAInitializableReducer.git", branch: "master"),
		.package(url: "https://github.com/ThanhHaiKhong/UIComponents.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "MobileAdsClient",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
				.product(name: "TCAInitializableReducer", package: "TCAInitializableReducer"),
            ]
        ),
        .target(
            name: "MobileAdsClientLive",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
                "MobileAdsClient",
            ]
        ),
        .target(
            name: "MobileAdsClientUI",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
				.product(name: "TCAInitializableReducer", package: "TCAInitializableReducer"),
                "NativeAdClient",
				"UIComponents",
            ],
            resources: [
                .process("Resources/stars_3_5.png"),
                .process("Resources/stars_4.png"),
                .process("Resources/stars_4_5.png"),
                .process("Resources/stars_5.png"),
            ]
        ),
        .target(
            name: "NativeAdClient",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
				.product(name: "TCAInitializableReducer", package: "TCAInitializableReducer"),
            ]
        ),
        .target(
            name: "NativeAdClientLive",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
                "NativeAdClient",
            ]
        ),
    ]
)

extension Product {
    static func singleTargetLibrary(_ name: String) -> Product {
        .library(name: name, targets: [name])
    }
}

