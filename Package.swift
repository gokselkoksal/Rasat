// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Rasat",
  platforms: [
    .macOS(.v10_12),
    .iOS(.v10),
    .tvOS(.v10),
    .watchOS(.v3)],
  products: [
    .library(name: "Rasat", targets: ["Rasat"])
  ],
  targets: [
    .target(name: "Rasat", path: "Rasat"),
    .testTarget(name: "RasatTests", dependencies: ["Rasat"], path: "RasatTests")
  ],
  swiftLanguageVersions: [.v5]
)
