// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "API",
  platforms: [
    .iOS(.v13),
    .watchOS(.v6),
    .macOS(.v10_15)
  ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "API",
            targets: ["API"]),
    ],
    dependencies: [
      .package(url: "https://github.com/tomlokhorst/Statham.git", from: "2.1.0"),
      .package(url: "https://github.com/tomlokhorst/Promissum", from: "5.0.0"),
      .package(name: "CancellationToken", url: "https://github.com/tomlokhorst/swift-cancellationtoken", from: "3.2.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "API",
            dependencies: ["Statham", "Promissum", "CancellationToken"]),
        .testTarget(
            name: "APITests",
            dependencies: ["API"]),
    ]
)
