// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "BuildTools",
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.46.3"),
        .package(url: "https://github.com/mac-cain13/R.swift", from: "5.2.2"),
        .package(url: "https://github.com/realm/SwiftLint", from: "0.40.3"),
    ],
    targets: [.target(name: "BuildTools", path: "")]
)
