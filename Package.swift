// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MarkdownViewer",
    platforms: [
        .macOS("26.0")
    ],
    dependencies: [
        .package(url: "https://github.com/AnYuan/MarkdownKit.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "MarkdownViewer",
            dependencies: [
                .product(name: "MarkdownKit", package: "MarkdownKit")
            ]
        )
    ]
)
