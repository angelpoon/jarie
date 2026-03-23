// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "JarieCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "JarieCore", targets: ["JarieCore"]),
    ],
    targets: [
        .target(name: "JarieCore"),
    ]
)
