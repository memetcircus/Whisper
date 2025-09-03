// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WhisperApp",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "WhisperCore",
            targets: ["WhisperCore"]
        ),
    ],
    dependencies: [
        // No external dependencies - we use only system frameworks
    ],
    targets: [
        .target(
            name: "WhisperCore",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "WhisperCoreTests",
            dependencies: ["WhisperCore"],
            path: "Tests"
        ),
    ]
)