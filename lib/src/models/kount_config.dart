/// Configuration class for Kount SDK initialization
class KountConfig {
  /// The merchant ID provided by Kount
  final String merchantId;

  /// Environment for SDK communication
  /// Valid values: 'TEST', 'QA', 'PROD'
  /// 'QA' is for internal testing only.
  final String environment;

  /// Supported environment identifiers.
  static const List<String> supportedEnvironments = ['TEST', 'QA', 'PROD'];

  /// Analytics data collection is NOT supported in Flutter wrappers.
  /// KountAnalyticsTracker depends on native view/touch hierarchy observation,
  /// which Flutter's canvas-based rendering (Skia/Impeller) does not expose.
  /// This value is always hardcoded to false and cannot be changed.
  /// See: README.md for integration details.
  /// Planned re-enablement: Q4 2026 / Q1 2027 when native analytics path is available.
  static const bool collectAnalytics = false;

  /// Creates a new Kount configuration
  ///
  /// Parameters:
  ///   - [merchantId]: Required. The merchant ID from Kount
  ///   - [environment]: Required. One of: 'TEST', 'QA', 'PROD'
  ///
  /// Note: [collectAnalytics] is always false (not supported in Flutter)
  KountConfig({
    required this.merchantId,
    required this.environment,
  });

  /// Validates that the configuration is correct
  ///
  /// Returns true if:
  ///   - merchantId is not empty
  ///   - environment is one of: TEST, QA, PROD
  bool get isValid =>
      merchantId.isNotEmpty &&
      supportedEnvironments.contains(environment);

  @override
  String toString() =>
      'KountConfig(merchantId: $merchantId, environment: $environment, collectAnalytics: $collectAnalytics, isValid: $isValid)';
}
