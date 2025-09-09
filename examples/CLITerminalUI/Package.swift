// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CLITerminalUI",
    platforms: [ .macOS(.v13) ],
    products: [ .executable(name: "cli-tui", targets: ["CLITerminalUI"]) ],
    dependencies: [ .package(path: "../..") ],
    targets: [
        .executableTarget(
            name: "CLITerminalUI",
            dependencies: [ .product(name: "ConnectOnion", package: "connectonion-swift") ],
            path: "Sources"
        )
    ]
)

