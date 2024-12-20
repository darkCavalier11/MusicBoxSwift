// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MusicBox",
    platforms: [
      .iOS(.v14),
      .macOS(.v11),
      .watchOS(.v7),
      .driverKit(.v19),
      .macCatalyst(.v14),
      .tvOS(.v14),
      .visionOS(.v1),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MusicBox",
            targets: ["MusicBox"]),
    ],
    dependencies: [
      .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
      .package(url: "https://github.com/alexeichhorn/YouTubeKit.git", from: "0.2.3")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
          name: "MusicBox", dependencies: ["SwiftSoup", "YouTubeKit"]),
        
        .testTarget(
            name: "MusicBoxTests",
            dependencies: ["MusicBox"]
        ),
    ]
)
