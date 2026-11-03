// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "NovaRenderKit",
    platforms: [ .iOS(.v15), .macOS(.v12), .macCatalyst(.v15) ],
    products: [
        .library(name: "NovaRenderKit", targets: ["NovaRenderKit"]),
    ],
    dependencies: [
        .package(name: "NovaProjectKit", path: "../NovaProjectKit"),
    ],
    targets: [
        .target(
            name: "NovaRenderKit",
            dependencies: ["NovaProjectKit"],
            path: "Sources/NovaRenderKit",
            resources: [
                .process("Shaders"),
            ]
        ),
        .testTarget(
            name: "NovaRenderKitTests",
            dependencies: ["NovaRenderKit"],
            path: "Tests/NovaRenderKitTests"
        ),
    ]
)
