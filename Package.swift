// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoSleepAgent",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "NoSleepAgent",
            path: "NoSleepAgent"
        )
    ]
)
