// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "LazyCollection",
  platforms: [.iOS(.v13)],
  products: [
    .library(name: "LazyCollection", targets: ["LazyCollection"])
  ],
  dependencies: [
    .package(url: "https://github.com/ra1028/DifferenceKit", from: "1.2.0")
  ],
  targets: [
    .target(name: "LazyCollection", dependencies: ["DifferenceKit"])
  ]
)
