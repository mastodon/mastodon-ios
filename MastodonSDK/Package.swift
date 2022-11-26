// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MastodonSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "MastodonSDK",
            targets: [
                "CoreDataStack",
                "MastodonAsset",
                "MastodonCommon",
                "MastodonCore",
                "MastodonExtension",
                "MastodonLocalization",
                "MastodonSDK",
                "MastodonUI",
            ])
    ],
    dependencies: [
        .package(name: "ArkanaKeys", path: "../dependencies/ArkanaKeys"),
        .package(url: "https://github.com/will-lumley/FaviconFinder.git", from: "3.2.2"),
        .package(url: "https://github.com/siteline/SwiftUI-Introspect.git", from: "0.1.3"),
        .package(url: "https://github.com/MainasuK/UITextView-Placeholder.git", from: "1.4.1"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.4.0"),
        .package(url: "https://github.com/Alamofire/AlamofireImage.git", from: "4.1.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.3"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.0.0"),
        .package(url: "https://github.com/Flipboard/FLAnimatedImage.git", from: "1.0.0"),
        .package(url: "https://github.com/kean/Nuke-FLAnimatedImage-Plugin.git", from: "8.0.0"),
        .package(url: "https://github.com/kean/Nuke.git", from: "10.3.1"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(url: "https://github.com/MainasuK/CommonOSLog", from: "0.1.1"),
        .package(url: "https://github.com/MainasuK/FPSIndicator.git", from: "1.0.0"),
        .package(url: "https://github.com/slackhq/PanModal.git", from: "1.2.7"),
        .package(url: "https://github.com/TimOliver/TOCropViewController.git", from: "2.6.1"),
        .package(url: "https://github.com/TwidereProject/MetaTextKit.git", exact: "2.2.5"),
        .package(url: "https://github.com/TwidereProject/TabBarPager.git", from: "0.1.0"),
        .package(url: "https://github.com/uias/Tabman", from: "2.13.0"),
        .package(url: "https://github.com/vtourraine/ThirdPartyMailer.git", from: "2.1.0"),
        .package(url: "https://github.com/woxtu/UIHostingConfigurationBackport.git", from: "0.1.0"),
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.12.0"),
        .package(url: "https://github.com/eneko/Stripes.git", from: "0.2.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.4.1"),
        .package(url: "https://github.com/NextLevel/NextLevelSessionExporter.git", from: "0.4.6"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CoreDataStack",
            dependencies: [
                "MastodonCommon",
            ],
            exclude: [
                "Template/Stencil"
            ]
        ),
        .target(
            name: "MastodonAsset",
            dependencies: [],
            resources: [
                .process("Font"),
            ]
        ),
        .target(
            name: "MastodonCommon",
            dependencies: [
                "MastodonExtension",
            ]
        ),
        .target(
            name: "MastodonCore",
            dependencies: [
                "CoreDataStack",
                "MastodonAsset",
                "MastodonCommon",
                "MastodonLocalization",
                "MastodonSDK",
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "AlamofireImage", package: "AlamofireImage"),
                .product(name: "CommonOSLog", package: "CommonOSLog"),
                .product(name: "ArkanaKeys", package: "ArkanaKeys"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "MetaTextKit", package: "MetaTextKit")
            ]
        ),
        .target(
            name: "MastodonExtension",
            dependencies: []
        ),
        .target(
            name: "MastodonLocalization",
            dependencies: []
        ),
        .target(
            name: "MastodonSDK",
            dependencies: [
                .product(name: "NIOHTTP1", package: "swift-nio"),
            ]
        ),
        .target(
            name: "MastodonUI",
            dependencies: [
                "MastodonCore",
                .product(name: "FLAnimatedImage", package: "FLAnimatedImage"),
                .product(name: "FaviconFinder", package: "FaviconFinder"),
                .product(name: "Nuke", package: "Nuke"),
                .product(name: "Introspect", package: "SwiftUI-Introspect"),
                .product(name: "UITextView+Placeholder", package: "UITextView-Placeholder"),
                .product(name: "UIHostingConfigurationBackport", package: "UIHostingConfigurationBackport"),
                .product(name: "TabBarPager", package: "TabBarPager"),
                .product(name: "ThirdPartyMailer", package: "ThirdPartyMailer"),
                .product(name: "OrderedCollections", package: "swift-collections"),
                .product(name: "Tabman", package: "Tabman"),
                .product(name: "MetaTextKit", package: "MetaTextKit"),
                .product(name: "CropViewController", package: "TOCropViewController"),
                .product(name: "PanModal", package: "PanModal"),
                .product(name: "Stripes", package: "Stripes"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "NextLevelSessionExporter", package: "NextLevelSessionExporter"),
            ]
        ),
        .testTarget(
            name: "MastodonSDKTests",
            dependencies: ["MastodonSDK"]
        ),
    ]
)
