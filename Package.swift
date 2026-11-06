// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "allume-web-export",
  platforms: [
    // Allume's minimums: it's a Mac Catalyst app on macOS 14.
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
    .target(name: "AllumeWebBundleReader", dependencies: ["AllumeWebModels"]),
    .target(name: "AllumeWebRendering", dependencies: ["AllumeWebModels"]),
    .target(
      name: "AllumeWeb",
      dependencies: ["AllumeWebModels", "AllumeWebRendering"],
      resources: [.copy("Viewer")]
    ),
    .executableTarget(
      name: "AllumeWebCLI",
      dependencies: [
        "AllumeWeb", "AllumeWebBundleReader", "AllumeWebModels",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .testTarget(name: "AllumeWebModelsTests", dependencies: ["AllumeWebModels"]),
    .testTarget(name: "AllumeWebBundleReaderTests", dependencies: ["AllumeWebBundleReader"]),
    .testTarget(name: "AllumeWebRenderingTests", dependencies: ["AllumeWebRendering"]),
    .testTarget(name: "AllumeWebTests", dependencies: ["AllumeWeb", "AllumeWebModels"]),
    .testTarget(
      name: "AllumeWebIntegrationTests",
      dependencies: ["AllumeWeb", "AllumeWebBundleReader", "AllumeWebRendering"],
      exclude: ["Expected"]
    ),
  ]
)
