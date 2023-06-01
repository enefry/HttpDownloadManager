// swift-tools-version:5.6

import PackageDescription

let package = Package(
  name: "HttpDownloadManager",
  platforms: [
    .iOS(.v14),
    .macCatalyst(.v15)
  ],
  products: [
    .library(name: "HttpDownloadManager", targets: ["HttpDownloadManager"]),
  ],
  dependencies: [
    .package(url: "https://github.com/enefry/Tiercel.git", branch: "master"),
    .package(url: "https://github.com/enefry/LoggerProxy.git", from: "1.0.0"),
  ],
  targets: [
    .target(
        name: "HttpDownloadManager",
        dependencies: [
            .productItem(name: "Tiercel",package: "Tiercel"),
            .productItem(name: "LoggerProxy",package: "LoggerProxy"),
        ],
        path: "HttpDownloadManager",
        resources: [
            .process("resources")
        ],
        linkerSettings: [
            .linkedFramework("Foundation"),
            .linkedFramework("UIKit"),
        ]
    )
  ]
)
