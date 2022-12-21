// swift-tools-version:5.6

import PackageDescription

let package = Package(
  name: "HttpDownloadManager",
  platforms: [
    .iOS("15")
  ],
  products: [
    .library(name: "HttpDownloadManager", targets: ["HttpDownloadManager"]),
  ],
  dependencies: [
    .package(url: "https://github.com/Danie1s/Tiercel.git", from: "3.2.2"),
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
