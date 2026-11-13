# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-11-06

Initial base release of the Kount SDK Wrapper for Flutter.

### Added
- Dart/Flutter wrapper over the native Kount Data Collector SDKs (Android `kount-data-collector-5.0.3.jar`, iOS `KountSDK.xcframework` 6.0.0), exposed through the shared `DataCollector` MethodChannel with the same method contract on both platforms.
- `KountService` for configuration (`setMerchantId`, `setEnvironment`, `setCollectAnalytics`) and device data collection, with a 30-second Dart timeout.
- `KountSessionManager` for session ID generation/management and `configureAndCollect()` orchestration.
- `KountConfig` model (merchant ID + environment) with `isValid` validation.
- `KountResult` model for structured success/error results.
- `KountLogger` utility for structured logging.
- Foreground location permission request flow (`requestLocationPermission`) on Android and iOS.
- Environment support for `TEST`, `QA` and `PROD`:
  - Android maps `QA` to the SDK's non-public QA value (`999999`, `mbl.kaptcha.com`).
  - iOS sets `QA` through the SDK's internal `KDataCollector.setInternalEnvironment(.QA)` API.
  - `QA` is intended for internal testing only.
- iOS plugin distributed as a Swift Package (SPM) wrapping `KountSDK.xcframework` as a binary target; CocoaPods is not supported.
- Example Flutter application with merchant ID, session ID and environment (`TEST`/`QA`/`PROD`) selection.
- Unit tests for Dart models, utilities and session management, plus an end-to-end integration test for the example app.

### Notes
- Collection failures are surfaced to Dart as `FlutterError("COLLECTION_ERROR", ...)` on both platforms instead of reporting success.
- Behavioral analytics is not supported: `setCollectAnalytics()` and the `collectAnalytics` argument are accepted for API compatibility but are no-ops, because Kount's analytics tracker relies on native view/touch hierarchy observation that Flutter's canvas rendering (Skia/Impeller) does not expose. Re-enablement is tentatively planned for Q4 2026 / Q1 2027.
- The Android bridge enables native SDK debugging during collection; review before a production release.

## Future Versions

### Planned
- Support for additional Kount SDK features
- Extended Android/iOS platform-specific configurations
- CI/CD pipeline integration for automated testing and publishing
- Performance optimizations for large-scale data collection
