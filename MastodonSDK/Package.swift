// swift-tools-version:5.3
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
                "MastodonSDK",
                "MastodonExtension",
                "MastodonAsset",
                "MastodonLocalization",
                "MastodonUI",
            ]),
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.0.0"),
        .package(url: "https://github.com/kean/Nuke.git", from: "10.3.1"),
        .package(url: "https://github.com/Flipboard/FLAnimatedImage.git", from: "1.0.0"),
        .package(url: "https://github.com/TwidereProject/MetaTextKit.git", .exact("2.1.2")),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.4.0"),
        .package(url: "https://github.com/Alamofire/AlamofireImage.git", from: "4.1.0"),
        .package(name: "NukeFLAnimatedImagePlugin", url: "https://github.com/kean/Nuke-FLAnimatedImage-Plugin.git", from: "8.0.0"),
        .package(name: "UITextView+Placeholder", url: "https://github.com/MainasuK/UITextView-Placeholder.git", from: "1.4.1"),
        .package(name: "Introspect", url: "https://github.com/siteline/SwiftUI-Introspect.git", from: "0.1.3")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MastodonSDK",
            dependencies: [
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
            ]
        ),
        .target(
            name: "MastodonExtension",
            dependencies: []
        ),
        .target(
            name: "MastodonAsset",
            dependencies: []
        ),
        .target(
            name: "MastodonLocalization",
            dependencies: []
        ),
        .target(
            name: "MastodonUI",
            dependencies: [
                "MastodonSDK",
                "MastodonExtension",
                "MastodonAsset",
                "MastodonLocalization",
                "Nuke",
                "NukeFLAnimatedImagePlugin",
                "UITextView+Placeholder",
                "Introspect",
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "AlamofireImage", package: "AlamofireImage"),
                .product(name: "MetaTextKit", package: "MetaTextKit"),
                .product(name: "FLAnimatedImage", package: "FLAnimatedImage"),
            ]
        ),
        .testTarget(
            name: "MastodonSDKTests",
            dependencies: ["MastodonSDK"]
        ),
    ]
)
