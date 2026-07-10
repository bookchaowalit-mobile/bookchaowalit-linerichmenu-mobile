// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Linerichmenu",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Linerichmenu", targets: ["Linerichmenu"])
    ],
    targets: [
        .target(name: "Linerichmenu", path: "Sources")
    ]
)
