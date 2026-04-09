// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "CryptoCharts",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "CryptoCharts",
            path: "Sources"
        )
    ]
)
