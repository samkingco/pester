// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "pester",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Pester",
            path: "Sources/Pester"
        ),
        .executableTarget(
            name: "pester-cli",
            path: "Sources/pester-cli"
        ),
    ]
)
