// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Fyper",
    platforms: [.macOS(.v10_15), .iOS(.v15), .tvOS(.v15), .watchOS(.v8), .macCatalyst(.v15)],
    products: [
        .library(
            name: "Resolver",
            targets: ["Resolver"]
        ),
        .library(
            name: "Macros",
            targets: ["Macros"]
        ),
        .plugin(
            name: "BuildPlugin",
            targets: ["BuildPlugin"]
        ),
    ], dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0-swift-5.9-DEVELOPMENT-SNAPSHOT-2023-04-25-b"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2"),
    ],
    targets: [
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "MacrosImplementation",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(name: "Resolver"),
        .testTarget(
            name: "Tests",
            dependencies: [
                .target(name: "MacrosImplementation"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
        .plugin(
            name: "BuildPlugin",
            capability: .buildTool(),
            dependencies: ["Analyser"],
            path: "Sources/Plugins"
        ),
        .executableTarget(
            name: "Analyser", dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "Macros", dependencies: ["MacrosImplementation"]),
    ]
)
