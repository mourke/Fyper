// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Fyper",
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        .library(
            name: "Shared",
            targets: ["Shared"]
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
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.2"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        // Macro implementation that performs the source transformation of a macro.
		.target(name: "Shared", dependencies: [
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        ]),
        .macro(
            name: "MacrosImplementation",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
				.target(name: "Shared")
            ]
        ),
        .testTarget(
            name: "Tests",
            dependencies: [
                .target(name: "MacrosImplementation"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                .target(name: "Shared")
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
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.target(name: "Shared")
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "Macros", dependencies: [
            .target(name: "MacrosImplementation"),
            .target(name: "Shared")
        ]),
    ]
)
