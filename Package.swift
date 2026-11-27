// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoltGuardiOS",
    platforms: [
        .iOS(.v16),
        .macOS(.v14)
    ],
    products: [
        .library(name: "VoltGuardDomain", targets: ["VoltGuardDomain"]),
        .library(name: "VoltGuardiOSCore", targets: ["VoltGuardiOSCore"])
    ],
    targets: [
        .target(
            name: "VoltGuardDomain",
            dependencies: [],
            path: "Sources/VoltGuardDomain"
        ),
        .target(
            name: "VoltGuardiOSCore",
            dependencies: ["VoltGuardDomain"],
            path: "Sources/VoltGuardiOS",
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("UserNotifications"),
                .linkedFramework("UIKit", .when(platforms: [.iOS])),
                .linkedFramework("PhotosUI", .when(platforms: [.iOS]))
            ]
        ),
        .testTarget(
            name: "VoltGuardiOSTests",
            dependencies: ["VoltGuardDomain", "VoltGuardiOSCore"],
            path: "Tests/VoltGuardiOSTests",
            swiftSettings: [
                .define("TESTING")
            ]
        )
    ]
)
