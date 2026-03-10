// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Okmain",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "Okmain",
            targets: ["Okmain"]
        ),
    ],
    targets: [
        .target(
            name: "Okmain"
        ),
        .testTarget(
            name: "OkmainTests",
            dependencies: ["Okmain"]
        ),
    ]
)
