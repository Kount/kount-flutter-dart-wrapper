// swift-tools-version:5.9
import PackageDescription

// Local wrapper package around Flutter's prebuilt engine binary
// (Flutter.xcframework).
//
// WHY THIS EXISTS:
// `kount_sdk_wrapper/Package.swift` declares a dependency on a package named
// "FlutterFramework" so that `import Flutter` resolves when this plugin is
// opened/built directly in Xcode through Swift Package Manager (e.g. for
// local development, previews, or `swift build`), independent of Flutter's
// own build pipeline (which normally wires up Flutter.framework for you via
// `flutter build`/`flutter run`).
//
// If you only ever build through the Flutter tool (flutter run / flutter
// build ios), you don't need this package at all — in that case you can
// comment out the "FlutterFramework" dependency line in
// `../kount_sdk_wrapper/Package.swift`, as noted in that file.
//
// HOW TO (RE)GENERATE Frameworks/Flutter.xcframework:
// Run `./update_flutter_framework.sh` from this directory. It locates your
// active Flutter SDK (via `flutter` on PATH) and copies the iOS engine
// artifact (Frameworks/Flutter.xcframework) used by `flutter build`'s Debug
// configuration. Re-run it after switching Flutter versions/channels.
let package = Package(
    name: "FlutterFramework",
    platforms: [.iOS("12.0")],
    products: [
        .library(name: "FlutterFramework", targets: ["Flutter"])
    ],
    targets: [
        .binaryTarget(
            name: "Flutter",
            path: "Frameworks/Flutter.xcframework"
        )
    ]
)

