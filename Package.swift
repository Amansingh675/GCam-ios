// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GCam-iOS",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "GCamLib",
            targets: ["GCamLib"]
        ),
    ],
    targets: [
        .target(
            name: "GCamLib",
            path: "Sources",
            resources: [
                .process("Shaders")
            ]
        )
    ]
)
