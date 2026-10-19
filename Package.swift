// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IAP",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(name: "IAP", targets: ["IAP"])
    ],
    targets: [
        .target(name: "IAP"),
        .testTarget(name: "IAPTests", dependencies: ["IAP"])
    ]
)
