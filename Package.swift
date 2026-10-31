// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "allume-web-export",
  platforms: [
    // Allume's own minimums (a Mac Catalyst app on macOS 14), so the app can embed the library.
    .macOS(.v14),
    .iOS(.v17),
  ],
  products: [
    .library(name: "AllumeWeb", targets: ["AllumeWeb", "AllumeWebModels"]),
    .executable(name: "allume-web-export", targets: ["AllumeWebCLI"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.0")
  ],
  targets: [
    .target(name: "AllumeWebModels"),
    .target(name: "AllumeWeb"),
    .executableTarget(
      name: "AllumeWebCLI",
      dependencies: [
        "AllumeWeb",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .testTarget(name: "AllumeWebModelsTests", dependencies: ["AllumeWebModels"]),
  ]
)
