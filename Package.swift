// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "quiver-demo-vapor",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.89.0"),
        .package(url: "https://github.com/waynewbishop/quiver.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Quiver", package: "quiver"),
                .product(name: "Vapor", package: "vapor")
            ],
            path: "Sources/App"
        )
    ]
)
