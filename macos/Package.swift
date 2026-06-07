// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ClaudeSignalLight",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ClaudeSignalLight",
            targets: ["ClaudeSignalLight"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ClaudeSignalLight",
            path: "Sources/ClaudeSignalLight"
        )
    ]
)
