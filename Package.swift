// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "oaichat",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "oaichat", targets: ["oaichat"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.5.0")),
    ],
    targets: [
        .executableTarget(
            name: "oaichat",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
