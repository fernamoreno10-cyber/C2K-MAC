// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KeyboardCleaner",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "KeyboardCleanerLib",
            path: "Sources/KeyboardCleanerLib",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .executableTarget(
            name: "KeyboardCleaner",
            dependencies: ["KeyboardCleanerLib"],
            path: "Sources/KeyboardCleaner"
        ),
        .testTarget(
            name: "KeyboardCleanerTests",
            dependencies: [
                "KeyboardCleanerLib"
            ],
            path: "Tests/KeyboardCleanerTests"
        )
    ]
)
