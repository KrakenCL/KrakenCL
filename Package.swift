// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KrakenCL",
    products: [
        .library(name: "KrakenContracts", type: .static, targets: ["KrakenContracts"]),
        .library(name: "KrakenHTTPService", type: .static, targets: ["KrakenHTTPService"]),
        .library(name: "KrakenORMService", type: .static, targets: ["KrakenORMService"]),
        .executable(name: "KrakenCL", targets: ["KrakenCL"])
        ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.12.0"),
        .package(url: "https://github.com/IBM-Swift/Swift-Kuery-ORM.git", from: "0.4.0"),
        .package(url: "https://github.com/IBM-Swift/Swift-Kuery-SQLite.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.3.0"),
    ],
    targets: [
        .target(name: "KrakenContracts", dependencies: []),
        .target(name: "KrakenHTTPService", dependencies: ["NIO", "NIOHTTP1", "NIOConcurrencyHelpers", "NIOTLS", "NIOWebSocket", "KrakenContracts"]),
        .target(name: "KrakenORMService", dependencies: ["SwiftKueryORM", "SwiftKuerySQLite", "KrakenContracts"]),
        .target(name: "KrakenCL", dependencies: ["KrakenORMService", "KrakenHTTPService", "KrakenContracts", "Utility"]),
        .testTarget(name: "KrakenCLTests", dependencies: ["KrakenCL"])
    ]
)
