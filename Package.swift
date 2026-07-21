// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TripleClickMiddleClick",
    platforms: [.macOS(.v12)],
    targets: [
        .systemLibrary(name: "CMultitouchSupport"),
        .executableTarget(
            name: "TripleClickMiddleClick",
            dependencies: ["CMultitouchSupport"],
            linkerSettings: [
                .unsafeFlags([
                    "-F/System/Library/PrivateFrameworks",
                    "-framework", "MultitouchSupport",
                ])
            ]
        ),
    ]
)
