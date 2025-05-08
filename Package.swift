// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftWestonSimpleEGL",
    dependencies: [
        .package(url: "https://github.com/CmST0us/SwiftGLEW", branch: "main"),
        .package(url: "https://github.com/CmST0us/SwiftCEGL", branch: "main"),
        .package(url: "https://github.com/CmST0us/SwiftCWaylandClient", branch: "main"),
        .package(url: "https://github.com/CmST0us/SwiftCWaylandEGL", branch: "main"),
        .package(url: "https://github.com/CmST0us/XDGShellProtocol", branch: "main"),
        .package(url: "https://github.com/CmST0us/SwiftImGui", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "WestonSimpleEGL",
            dependencies: [
                .product(name: "XDGShellProtocol", package: "XDGShellProtocol"),
                .product(name: "CEGL", package: "SwiftCEGL"),
                .product(name: "CWaylandClient", package: "SwiftCWaylandClient"),
                .product(name: "CWaylandEGL", package: "SwiftCWaylandEGL"),
                .product(name: "GLEW", package: "SwiftGLEW"),
            ],
            linkerSettings: [
                .linkedLibrary("GL"),
            ]),
        .executableTarget(
            name: "WestonSimpleImGui",
            dependencies: [
                .product(name: "XDGShellProtocol", package: "XDGShellProtocol"),
                .product(name: "CEGL", package: "SwiftCEGL"),
                .product(name: "CWaylandClient", package: "SwiftCWaylandClient"),
                .product(name: "CWaylandEGL", package: "SwiftCWaylandEGL"),
                .product(name: "GLEW", package: "SwiftGLEW"),
                .product(name: "ImGui", package: "SwiftImGui"),
                .product(name: "ImGuiBackend", package: "SwiftImGui")
            ],
            linkerSettings: [
                .linkedLibrary("GL"),
            ])
    ]
)
