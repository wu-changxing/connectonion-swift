// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CLIAssistant",
    platforms: [ .macOS(.v13) ],
    products: [ .executable(name: "cli-assistant", targets: ["CLIAssistant"]) ],
    dependencies: [
        .package(path: "../..") // depends on the root ConnectOnion package
    ],
    targets: [
        .executableTarget(
            name: "CLIAssistant",
            dependencies: [ .product(name: "ConnectOnion", package: "connectonion-swift") ],
            path: "Sources"
        )
    ]
)

