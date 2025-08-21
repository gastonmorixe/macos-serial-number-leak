// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "serial-number",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "SerialNumberCore", targets: ["SerialNumberCore"]),
        .executable(name: "serial-number", targets: ["serial-number"]) 
    ],
    targets: [
        .target(
            name: "SerialNumberCore",
            linkerSettings: [
                .linkedFramework("IOKit")
            ]
        ),
        .executableTarget(
            name: "serial-number",
            dependencies: ["SerialNumberCore"]
        ),
        .testTarget(
            name: "SerialNumberCoreTests",
            dependencies: ["SerialNumberCore"]
        )
    ]
)
