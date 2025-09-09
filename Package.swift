// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "connectonion-swift",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "ConnectOnion", targets: ["ConnectOnion"]),
        .executable(name: "connectonion-cli", targets: ["ConnectOnionCLI"])        
    ],
    targets: [
        .target(
            name: "ConnectOnion",
            path: "Sources/ConnectOnion"
        ),
        .executableTarget(
            name: "ConnectOnionCLI",
            dependencies: ["ConnectOnion"],
            path: "Sources/ConnectOnionCLI"
        ),
        .testTarget(
            name: "ConnectOnionTests",
            dependencies: ["ConnectOnion"],
            path: "Tests/ConnectOnionTests"
        )
    ]
)

