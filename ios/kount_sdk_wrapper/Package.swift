// swift-tools-version:5.9
import PackageDescription

// Flutter iOS plugin package (Swift Package Manager).
// CocoaPods is intentionally NOT supported here — see the "iOS Integration"
// section of the customer-facing PDF guide for why (Flutter is sunsetting
// CocoaPods plugin support).
//
// This wraps the Kount SDK as a local XCFramework binary target. That single
// mechanism covers both the "XCFramework" and "SPM" delivery formats, since
// an SPM binaryTarget IS how an XCFramework is distributed through SPM.
//
// Universal Library (.a + headers) is NOT distributable through SPM's binary
// target model (SPM binary targets only accept .xcframework). Apps that must
// use the Universal Library format integrate it directly in Xcode instead of
// through this package — see the PDF guide for the manual linking steps.
let package = Package(
    name: "kount_sdk_wrapper",
    platforms: [.iOS("15.6")],
    products: [
        .library(name: "kount-sdk-wrapper", targets: ["kount_sdk_wrapper"])
    ],
    dependencies: [
        // Required by Flutter's SPM plugin integration so `import Flutter`
        // resolves without relying on ambient framework search paths.
        // See: https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-plugin-authors
        // IMPORTANT: THE PATH IS REQUIRED IF YOU'RE USING THIS CODE IN XCODE IDE, ANOTHER JUST COMMENT IT
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .binaryTarget(
            name: "KountSDK",
            // Drop the real Kount.xcframework here before building/distributing.
            path: "Frameworks/KountSDK.xcframework"
        ),
        .target(
            name: "kount_sdk_wrapper",
            dependencies: [
                "KountSDK",
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: []
        )
    ]
)
