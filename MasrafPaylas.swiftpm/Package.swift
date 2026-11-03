// swift-tools-version: 5.9

// Swift Playgrounds (iPad / Mac) ve Xcode ile açılabilen uygulama paketi.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "MasrafPaylas",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "MasrafPaylas",
            targets: ["AppModule"],
            bundleIdentifier: "com.masraf.paylas",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .calculator),
            accentColor: .presetColor(.teal),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)
