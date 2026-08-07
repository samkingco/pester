// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "pester",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "PesterProtocol",
            path: "Sources/PesterProtocol"
        ),
        .executableTarget(
            name: "Pester",
            dependencies: ["PesterProtocol"],
            path: "Sources/Pester"
        ),
        .executableTarget(
            name: "pester-cli",
            dependencies: ["PesterProtocol"],
            path: "Sources/pester-cli"
        ),
    ]
)
