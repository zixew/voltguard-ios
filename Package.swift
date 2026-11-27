// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoltGuardiOS",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "VoltGuardDomain", targets: ["VoltGuardDomain"]),
        .library(name: "VoltGuardNetwork", targets: ["VoltGuardNetwork"]),
        .library(name: "VoltGuardiOSCore", targets: ["VoltGuardiOSCore"])
    ],
    targets: [
        .target(
            name: "VoltGuardDomain",
            dependencies: [],
            path: "Sources/VoltGuardDomain"
        ),
        .target(
            name: "VoltGuardNetwork",
            dependencies: ["VoltGuardDomain"],
            path: "Sources/VoltGuardNetwork"
        ),
        .target(
            name: "VoltGuardiOSCore",
            dependencies: ["VoltGuardDomain", "VoltGuardNetwork"],
            path: "Sources/VoltGuardiOS"
        ),
        .testTarget(
            name: "VoltGuardiOSTests",
            dependencies: ["VoltGuardDomain", "VoltGuardNetwork", "VoltGuardiOSCore"],
            path: "Tests/VoltGuardiOSTests",
            swiftSettings: [
                .define("TESTING")
            ]
        )
    ]
)
