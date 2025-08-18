// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SpotLightSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "SpotLightSDK", targets: ["SpotLightSDK"])
    ],
    targets: [
        .target(
            name: "SpotLightSDK",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
