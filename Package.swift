// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StereoCheck",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "StereoCheck",
            path: "Sources/StereoCheck"
        )
    ]
)
