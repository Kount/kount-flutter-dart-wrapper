# kount-flutter-dart-wrapper

Kount's Flutter plugin makes it easy to bring Kount's fraud fighting solution into your Flutter app. It wraps the native Kount SDK for Android and iOS behind a single Dart API.

## Requirements

- [Kount integration](http://www.kount.com/fraud-detection-software) (a Kount merchant ID)
- Flutter 3.24.0+ and Dart 3.5.1+
- Android: minSdk 21+, compileSdk 36, Java 11
- iOS: iOS 15.6+ deployment target, Xcode with Swift Package Manager support

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  kount_sdk_wrapper:
    <git or private registry source>
```

Then run:

```sh
flutter pub get
```

### iOS

The plugin is distributed through Swift Package Manager only (no CocoaPods). Enable SPM support in your Flutter project if it is not already enabled:

```sh
flutter config --enable-swift-package-manager
```

Add the location usage description to your app's `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Your reason for requesting location access.</string>
```

### Android

No additional setup is required. The Kount SDK is bundled with the plugin.

## Usage

```dart
import 'package:kount_sdk_wrapper/kount_sdk_wrapper.dart';

final manager = KountSessionManager();

final config = KountConfig(
  merchantId: '<YOUR_MERCHANT_ID>',
  environment: 'TEST', // 'TEST' or 'PROD'
);

final result = await manager.configureAndCollect(config);

if (result.success) {
  print('Session ID: ${result.sessionId}');
} else {
  print('Collection failed: ${result.error}');
}
```

Send the returned `sessionId` to your backend and include it in your Kount Risk Inquiry Service (RIS) request.

### Step-by-step

```dart
final service = KountService();
final manager = KountSessionManager(service: service);

await service.configure(config);
final sessionId = manager.generateSessionId();
final result = await service.collect(sessionId);
```

### Location permission

```dart
final granted = await service.requestLocationPermission();
```

## API overview

| Class | Purpose |
|---|---|
| `KountConfig` | Merchant ID, environment and analytics flag. `isValid` checks the values. |
| `KountSessionManager` | Generates UUID v4 session IDs and runs configure + collect in one call. |
| `KountService` | Lower-level access to configure, collect and request location permission. |
| `KountResult` | `success`, `sessionId`, `error` and `timestamp` for each collection. |
| `KountLogger` | Optional logging for debugging. |

Collection times out after 30 seconds and returns a failed `KountResult`.

## Platform notes

- `collectAnalytics` is honored on Android. It has no effect on iOS, because behavioral analytics depends on the native UIKit view hierarchy, which Flutter does not expose.
- Supported environments are `TEST` and `PROD`.

## Documentation

Head over to the developer.kount.com site for step-by-step setup instructions: <Integration Guide URL>

## Support

This SDK is actively maintained, but not through GitHub issues or pull requests on this repository — we don't monitor those here. If you run into a problem or have a question, our customer support team is the right place to go: post in [Kount Community (Topics – Kount)](https://support.kount.com/hc/en-us/community/topics) or email [support@kount.com](mailto:support@kount.com), and we'll take it from there.
