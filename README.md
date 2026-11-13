# Kount Flutter SDK Wrapper

`kount_sdk_wrapper` is a Flutter plugin for collecting device data with Kount's native Android and iOS SDKs. The package provides one Dart API over the native implementations; it does not make fraud decisions or replace the backend Kount Risk Inquiry Service (RIS) integration.

| Component | Release |
|---|---|
| Flutter wrapper | 1.0.0 |
| Kount Android SDK | 5.0.3 |
| Kount iOS SDK | 6.0.0 |

## Release readiness

The versions above describe the intended 1.0.0 release. Before publishing or consuming a public release, verify these distribution prerequisites:

- The Android SDK is bundled at `android/libs/kount-data-collector-5.0.3.jar`; confirm its version and distribution terms against the approved Kount release.
- The repository's `LICENSE` file is intentionally empty, so this repository does not grant an open-source license. Confirm the applicable usage and distribution terms for both the wrapper and Kount SDK binaries before use.
- The iOS Swift package references a local Flutter engine package. Its helper copies the debug engine from the active Flutter SDK, so this setup does not establish a working release integration. Validate a clean-checkout build and debug, profile, and release configurations before publishing.
- The Android bridge enables native SDK debugging during collection. Review this behavior before production use; the Dart logger does not control native SDK logging.

## Requirements

- Flutter with Dart compatible with the package constraint `^3.5.1`.
- Android: application `minSdk` 21 or later, Android SDK API 36, and a compatible Android Gradle Plugin, Gradle, Kotlin, and JDK toolchain. The plugin targets Java 11 bytecode; AGP 8.x requires JDK 17 or later.
- iOS: macOS, Xcode, Swift Package Manager, and an application deployment target of iOS 15.6 or later.
- A Kount merchant ID and the corresponding backend RIS integration.

Only Android and iOS are supported; web and desktop implementations are not included.

## Install

The package is distributed from this Git repository. Pin a reviewed release tag or commit in the consuming application's `pubspec.yaml`:

```yaml
dependencies:
  kount_sdk_wrapper:
    git:
      url: https://github.com/Kount/kount-flutter-dart-wrapper.git
      ref: <release-tag-or-commit>
```

Replace the placeholder with the approved ref, then run `flutter pub get`. Do not put credentials or access tokens in the dependency URL or source files.

For local development, use a path dependency instead:

```yaml
dependencies:
  kount_sdk_wrapper:
    path: ../kount-flutter-dart-wrapper
```

## Platform setup

### Android

The consuming app should declare the permissions required by the Kount collector in `android/app/src/main/AndroidManifest.xml`, directly under `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

The plugin requests foreground location permission before collection. Make the request from a foreground app with an attached Android activity, and handle denial. The example app declares additional permissions; do not copy background-location or all-files permissions unless your application independently needs them.

### iOS

The plugin uses Swift Package Manager (SPM), not CocoaPods. Enable Flutter's SPM support if needed:

```sh
flutter config --enable-swift-package-manager
```

Set the application's iOS deployment target to 15.6 or later, including relevant test targets. Add a purpose-specific location description to the consuming app's `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Explain why your application needs foreground location access.</string>
```

The current package also refers to `ios/FlutterFramework`, whose `Flutter.xcframework` is generated locally from the active Flutter SDK. From the repository root, the helper can prepare that local debug dependency:

```sh
flutter precache --ios
./ios/FlutterFramework/update_flutter_framework.sh
```

The generated Flutter framework is intentionally not committed because it is tied to the local Flutter SDK. This helper is not a release-engine integration; validate SPM resolution and release linkage in the consuming app before distribution.

## Collect device data

Call the plugin after Flutter is initialized. Request location permission from the app and handle a denied permission before collecting:

```dart
import 'package:kount_sdk_wrapper/kount_sdk_wrapper.dart';

Future<KountResult> collectDeviceData(String merchantId) async {
  final service = KountService();
  final manager = KountSessionManager(service: service);
  final config = KountConfig(
    merchantId: merchantId,
    environment: 'TEST', // Use PROD for the production integration.
  );

  if (!config.isValid) {
    throw ArgumentError('Provide a merchant ID and supported environment.');
  }

  final permissionGranted = await service.requestLocationPermission();
  if (!permissionGranted) {
    return KountResult(
      success: false,
      error: 'Location permission was not granted.',
    );
  }

  return manager.configureAndCollect(config);
}
```

Handle configuration exceptions and inspect the returned `KountResult`. On success, send `result.sessionId` to your backend and use the same value in the RIS request's `SESS` field. Collection success is not a fraud decision; the backend RIS integration is still required.

`KountSessionManager.configureAndCollect()` creates a new 32-character UUID v4 session ID for each call. The native collection call has a 30-second Dart timeout; a timeout does not cancel native work, so avoid immediate overlapping retries.

## Environments and API

Supported environment names are `TEST`, `QA`, and `PROD`. `QA` uses an internal Kount environment and is for authorized testing only. Use `PROD` for production traffic.

- `KountConfig` holds the merchant ID and environment; `isValid` checks that the ID is nonempty and the environment is supported, not that the merchant account is valid.
- `KountService.configure()` configures the native SDK. `KountService.collect()` collects for a session ID and returns a `KountResult`.
- `KountSessionManager.configureAndCollect()` combines configuration and collection. Validate configuration and handle errors from both the method and the returned result.
- `KountService.requestLocationPermission()` requests foreground location permission.
- Behavioral analytics are not supported by this Flutter wrapper. `collectAnalytics` is retained for API compatibility and has no effect.

See [`lib/kount_sdk_wrapper.dart`](lib/kount_sdk_wrapper.dart) for the public API and [`example/lib/main.dart`](example/lib/main.dart) for the sample app.

## Development

Run package tests and analysis from the repository root:

```sh
flutter pub get
flutter test
flutter analyze
```

Run the example on a supported device from its directory:

```sh
cd example
flutter pub get
flutter run
```

The example is for development and demonstration, not a production app template. Configure your own application identifiers, signing, permissions, privacy disclosures, and merchant settings before distributing an app.

## Support

For Kount account and integration questions, visit [Kount Community](https://support.kount.com/hc/en-us/community/topics) or email [support@kount.com](mailto:support@kount.com). GitHub issues and pull requests in this repository are not monitored for customer support. See [CHANGELOG.md](CHANGELOG.md) for release history.
