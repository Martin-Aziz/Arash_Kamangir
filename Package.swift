// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ArashKam",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ArashKam", targets: ["ArashKam"]),
        .library(name: "ArashCore", targets: ["ArashCore"])
    ],
    targets: [
        .target(name: "ArashCore"),
        .executableTarget(name: "ArashKam", dependencies: ["ArashCore"]),
        .testTarget(name: "ArashCoreTests", dependencies: ["ArashCore"])
    ]
)
