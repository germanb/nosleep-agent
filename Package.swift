// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoSleepAgent",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "NoSleepAgentLib", targets: ["NoSleepAgentLib"]),
        .executable(name: "NoSleepAgent", targets: ["NoSleepAgent"])
    ],
    targets: [
        .target(
            name: "NoSleepAgentLib",
            path: "NoSleepAgent",
            exclude: ["NoSleepAgentApp.swift", "Info.plist"]
        ),
        .executableTarget(
            name: "NoSleepAgent",
            dependencies: ["NoSleepAgentLib"],
            path: "NoSleepAgent",
            sources: ["NoSleepAgentApp.swift"]
        ),
        .testTarget(
            name: "NoSleepAgentTests",
            dependencies: ["NoSleepAgentLib"],
            path: "Tests"
        )
    ]
)
