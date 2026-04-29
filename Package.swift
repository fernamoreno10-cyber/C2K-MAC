// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeyboardCleaner",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "KeyboardCleanerLib",
            path: "Sources/KeyboardCleanerLib"
        ),
        .executableTarget(
            name: "KeyboardCleaner",
            dependencies: ["KeyboardCleanerLib"],
            path: "Sources/KeyboardCleaner"
        ),
        .testTarget(
            name: "KeyboardCleanerTests",
            dependencies: ["KeyboardCleanerLib"],
            path: "Tests/KeyboardCleanerTests"
        )
    ]
)
