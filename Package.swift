// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StereoCheck",
    platforms: [.macOS("26.0")],
    targets: [
        .executableTarget(
            name: "StereoCheck",
            path: "Sources/StereoCheck"
        ),
        .testTarget(
            name: "StereoCheckTests",
            dependencies: ["StereoCheck"]
        ),
    ]
)
