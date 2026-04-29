// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeyboardCleaner",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.10.0")
    ],
    targets: [
        .target(
            name: "KeyboardCleanerLib",
            path: "Sources/KeyboardCleanerLib",
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=minimal"])
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
                "KeyboardCleanerLib",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Tests/KeyboardCleanerTests"
        )
    ]
)
