import CoreLocation
import Flutter
import KountSDK
import UIKit

/// Flutter plugin bridging the Kount Data Collector iOS SDK.
///
/// Mirrors the Android `KountPlugin` exactly: same `DataCollector`
/// MethodChannel name and method names, so consumers get one contract across
/// both platforms (see MDAMOBILE-3775 / MDAMOBILE-3770).
///
/// Unlike the Android reference, a failed collection is surfaced to Dart as
/// a `FlutterError` instead of always resolving `result.success` (see
/// MDAMOBILE-3775 comment — Android side to be fixed to match).
public final class KountPlugin: NSObject, FlutterPlugin {

    private static let channelName = "DataCollector"

    private var currentSessionID: String?
    private var locationPermissionCompletion: ((Bool) -> Void)?
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = KountPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setMerchantId":
            collector.merchantID = (call.arguments as? [String: Any])?["merchantId"] as? String ?? ""
            result(nil)
        case "setEnvironment":
            setEnvironment(call.arguments, result: result)
        case "setCollectAnalytics":
            // No-op on iOS: kept only so the shared Dart KountService.configure()
            // call doesn't fail. Behavioral analytics (KountAnalyticsTracker) is
            // built on UIKit view/touch hierarchy observation, which Flutter apps
            // don't expose (Flutter renders its own widget tree on a single
            // canvas) - see collect() below.
            result(nil)
        case "setSessionId":
            currentSessionID = (call.arguments as? [String: Any])?["sessionId"] as? String
            result(nil)
        case "collectForSession":
            applyInlineOverrides(call.arguments)
            collect(result: result)
        case "configureAndCollect":
            configureAndCollect(call.arguments, result: result)
        case "getSessionID":
            if let sessionID = currentSessionID {
                result(sessionID)
            } else {
                result(FlutterError(code: "SESSION_ID_ERROR", message: "Session ID is null", details: nil))
            }
        case "requestLocationPermission":
            requestLocationPermission(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Configuration

    private var collector: KDataCollector { KDataCollector.shared() }

    private func setEnvironment(_ arguments: Any?, result: @escaping FlutterResult) {
        guard let environmentStr = (arguments as? [String: Any])?["environment"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "environment is required", details: nil))
            return
        }

        guard applyEnvironment(environmentStr) else {
            result(Self.unsupportedEnvironmentError(environmentStr))
            return
        }
        result(nil)
    }

    /// QA is only reachable through the SDK's internal API
    /// (`setInternalEnvironment:` / `KInternalEnvironmentQA`).
    @discardableResult
    private func applyEnvironment(_ environment: String) -> Bool {
        switch environment {
        case "TEST":
            collector.environment = .test
        case "PROD":
            collector.environment = .production
        case "QA":
            collector.setInternalEnvironment(.QA)
        default:
            return false
        }
        return true
    }

    private static func unsupportedEnvironmentError(_ environment: String) -> FlutterError {
        FlutterError(
            code: "UNSUPPORTED_ENVIRONMENT",
            message: "'\(environment)' is not a supported environment on iOS. Use TEST, QA or PROD.",
            details: nil
        )
    }

    private func applyInlineOverrides(_ arguments: Any?) {
        guard let args = arguments as? [String: Any] else { return }
        if let merchantId = args["merchantId"] as? String { collector.merchantID = merchantId }
        if let sessionId = args["sessionId"] as? String { currentSessionID = sessionId }
        if let environmentStr = args["environment"] as? String {
            applyEnvironment(environmentStr)
        }
    }

    private func configureAndCollect(_ arguments: Any?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
              let merchantId = args["merchantId"] as? String,
              let sessionId = args["sessionId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "merchantId and sessionId are required", details: nil))
            return
        }

        let environmentStr = args["environment"] as? String ?? "TEST"
        guard applyEnvironment(environmentStr) else {
            result(Self.unsupportedEnvironmentError(environmentStr))
            return
        }

        collector.merchantID = merchantId
        currentSessionID = sessionId
        // `collectAnalytics` arg intentionally ignored - see collect() below.

        collect(result: result)
    }

    // MARK: - Collection

    private func collect(result: @escaping FlutterResult) {
        guard let sessionID = currentSessionID, !sessionID.isEmpty else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "sessionId is required", details: nil))
            return
        }
        // Behavioral analytics (KountAnalyticsViewController) is intentionally
        // not used: it relies on UIKit view/touch hierarchy observation, which
        // Flutter apps don't expose. Only device data collection runs here.
        collector.collect(forSession: sessionID) { sessionID, success, error in
            DispatchQueue.main.async {
                self.currentSessionID = sessionID
                if success {
                    result(sessionID)
                } else {
                    // Real failure surfaced, unlike the current Android reference.
                    result(FlutterError(
                        code: "COLLECTION_ERROR",
                        message: error?.localizedDescription ?? "Data collection failed",
                        details: sessionID
                    ))
                }
            }
        }
    }

    // MARK: - Location Permission

    private func requestLocationPermission(result: @escaping FlutterResult) {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            result(true)
        case .denied, .restricted:
            result(false)
        case .notDetermined:
            locationPermissionCompletion = { granted in result(granted) }
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            result(false)
        }
    }
}

extension KountPlugin: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let completion = locationPermissionCompletion else { return }
        locationPermissionCompletion = nil
        let granted = manager.authorizationStatus == .authorizedAlways
            || manager.authorizationStatus == .authorizedWhenInUse
        completion(granted)
    }
}
