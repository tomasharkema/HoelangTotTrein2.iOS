// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Core",
  platforms: [
    .iOS(.v13),
    .watchOS(.v6),
    .macOS(.v10_15)
  ],
    products: [
      .library(name: "Core", targets: ["Core"]),
    ],
    dependencies: [
      .package(path: "../API"),
      .package(url: "https://github.com/Q42/Bindable.git", from: "0.8.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Core",
            dependencies: [
              "API",
              "Bindable",
              .product(name: "BindableNSObject", package: "Bindable")]),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"]),
    ]
)
