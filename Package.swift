// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "GlucoseRelay",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "GlucoseRelay",
            targets: ["GlucoseRelay"]
        ),
    ],
    targets: [
        .target(
            name: "GlucoseRelay",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .unsafeFlags(["-Xfrontend", "-disable-availability-checking"]),
                .unsafeFlags(["-Xfrontend", "-strict-concurrency=minimal"]),
            ]
        ),
        .testTarget(
            name: "GlucoseRelayTests",
            dependencies: ["GlucoseRelay"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
