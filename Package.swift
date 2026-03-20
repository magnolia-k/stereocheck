// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StreoCheck",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "StreoCheck",
            path: "Sources/StreoCheck"
        )
    ]
)
