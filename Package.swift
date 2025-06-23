// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "Scoop",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "Scoop",
            targets: ["Scoop"]
        ),
    ],
    dependencies: [
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Scoop",
            dependencies: []
        ),
        .testTarget(
            name: "ScoopTests",
            dependencies: ["Scoop"]
        ),
    ]
)
