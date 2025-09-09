// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DesktopAssistantApp",
    platforms: [ .macOS(.v13) ],
    products: [ .executable(name: "DesktopAssistantApp", targets: ["DesktopAssistantApp"]) ],
    dependencies: [
        .package(path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "DesktopAssistantApp",
            dependencies: [ .product(name: "ConnectOnion", package: "connectonion-swift") ],
            path: "Sources",
            resources: []
        )
    ]
)

