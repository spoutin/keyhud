// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeyHUD",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "KeyHUD",
            targets: ["KeyHUD"]
        )
    ],
    targets: [
        .executableTarget(
            name: "KeyHUD",
            path: "Sources/KeyHUD"
        )
    ]
)
