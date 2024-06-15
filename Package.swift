// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "voxie",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .executable(
            name: "voxie",
            targets: ["voxie"]),
    ],
    dependencies: [
        .package(url: "https://github.com/LebJe/TOMLKit.git", from: "0.5.0"),
        .package(url: "https://github.com/STREGAsGate/Raylib.git", branch: "master"),
        .package(url: "https://github.com/MacPaw/OpenAI.git", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(            
            name: "voxie", 
            dependencies: ["Raylib", "OpenAI", "TOMLKit"],
            resources: [
                .process("Config.toml"),
                .process("dune.wav"),
            ]
        ),
    ]
)
