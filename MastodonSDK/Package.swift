// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MastodonSDK",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "MastodonSDK",
            targets: ["MastodonSDK"]),
        .library(
            name: "MastodonUI",
            targets: ["MastodonUI"]),
        .library(
            name: "MastodonExtension",
            targets: ["MastodonExtension"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.0.0"),
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
            name: "MastodonUI",
            dependencies: ["MastodonExtension"]
        ),
        .target(
            name: "MastodonExtension",
            dependencies: []
        ),
        .testTarget(
            name: "MastodonSDKTests",
            dependencies: ["MastodonSDK"]
        ),
    ]
)
