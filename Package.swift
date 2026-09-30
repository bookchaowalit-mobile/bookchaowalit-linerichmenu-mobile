// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Linerichmenu",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "LinerichmenuCore", targets: ["LinerichmenuCore"]),
        .library(name: "LinerichmenuUI", targets: ["LinerichmenuUI"]),
    ],
    targets: [
        // Foundation-only domain logic; no SwiftUI so it also builds on Linux.
        .target(name: "LinerichmenuCore", path: "Sources/LinerichmenuCore"),
        .target(name: "LinerichmenuUI", dependencies: ["LinerichmenuCore"], path: "Sources/LinerichmenuUI"),
        .testTarget(name: "LinerichmenuCoreTests", dependencies: ["LinerichmenuCore"], path: "Tests/LinerichmenuCoreTests"),
    ]
)
