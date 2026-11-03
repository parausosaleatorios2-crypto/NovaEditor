// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "NovaProjectKit",
    platforms: [ .iOS(.v15), .macOS(.v12), .macCatalyst(.v15) ],
    products: [
        .library(name: "NovaProjectKit", targets: ["NovaProjectKit"]),
    ],
    targets: [
        .target(
            name: "NovaProjectKit",
            dependencies: [],
            path: "Sources/NovaProjectKit"
        ),
        .testTarget(
            name: "NovaProjectKitTests",
            dependencies: ["NovaProjectKit"],
            path: "Tests/NovaProjectKitTests"
        ),
    ]
)
