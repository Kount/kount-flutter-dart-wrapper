import 'package:flutter/services.dart';
import '../models/kount_config.dart';
import '../models/kount_result.dart';
import '../utils/kount_logger.dart';

/// Service for configuring and collecting data with the Kount SDK.
///
/// Communicates with the native [KountPlugin] via the `DataCollector`
/// MethodChannel, which in turn invokes the bundled Kount Data Collector JAR.
class KountService {
  final KountLogger _logger;

  static const String _methodChannelName = 'DataCollector';
  static const MethodChannel _platform = MethodChannel(_methodChannelName);

  /// Creates a new KountService.
  ///
  /// Parameters:
  ///   - [logger]: Optional. Custom logger instance. Creates default if not provided.
  KountService({KountLogger? logger}) : _logger = logger ?? KountLogger();

  /// Configures the Kount SDK with the provided [config].
  ///
  /// Calls individual native setters: `setMerchantId`, `setEnvironment`,
  /// `setCollectAnalytics`.
  ///
  /// Throws [ArgumentError] if the configuration is invalid.
  /// Throws [PlatformException] if a native call fails.
  Future<void> configure(KountConfig config) async {
    if (!config.isValid) {
      throw ArgumentError('Invalid Kount configuration: $config');
    }

    _logger.info(
      'Configuring Kount SDK – merchantId: ${config.merchantId}, '
      'environment: ${config.environment}, '
      'collectAnalytics: false',
    );

    try {
      await _platform.invokeMethod(
        'setMerchantId',
        {'merchantId': config.merchantId},
      );

      await _platform.invokeMethod(
        'setEnvironment',
        {'environment': config.environment},
      );

      await _platform.invokeMethod(
        'setCollectAnalytics',
        {'enabled': false},
      );

      _logger.info('Kount SDK configured successfully');
    } on PlatformException catch (e) {
      _logger.error('Failed to configure Kount SDK: ${e.message}');
      rethrow;
    } catch (e) {
      _logger.error('Unexpected error during configuration: $e');
      rethrow;
    }
  }

  /// Collects device data for the given [sessionId].
  ///
  /// Calls `setSessionId` then `collectForSession` on the native plugin.
  /// Returns a [KountResult] with success/error information.
  Future<KountResult> collect(String sessionId) async {
    _logger.info('Starting data collection for session: $sessionId');

    try {
      await _platform.invokeMethod('setSessionId', {'sessionId': sessionId});

      final dynamic rawResult = await _platform
          .invokeMethod<dynamic>('collectForSession', <String, dynamic>{})
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _logger.error('Collection timeout after 30 seconds');
          throw PlatformException(
            code: 'TIMEOUT',
            message: 'Data collection timeout after 30 seconds',
          );
        },
      );

      _logger.info('Collection succeeded – status: $rawResult');
      return KountResult(
        success: true,
        sessionId: sessionId,
      );
    } on PlatformException catch (e) {
      final msg = 'Collection failed: ${e.message}';
      _logger.error(msg);
      return KountResult(success: false, error: msg);
    } catch (e) {
      final msg = 'Unexpected error during collection: $e';
      _logger.error(msg);
      return KountResult(success: false, error: msg);
    }
  }

  /// Convenience method: configures the SDK AND collects in a single native call.
  ///
  /// Uses the `configureAndCollect` MethodChannel method for efficiency.
  Future<KountResult> configureAndCollect(
    KountConfig config,
    String sessionId,
  ) async {
    if (!config.isValid) {
      throw ArgumentError('Invalid Kount configuration: $config');
    }

    _logger.info(
      'configureAndCollect – merchantId: ${config.merchantId}, '
      'sessionId: $sessionId, environment: ${config.environment}',
    );

    try {
      final dynamic rawResult = await _platform.invokeMethod<dynamic>(
        'configureAndCollect',
        {
          'merchantId': config.merchantId,
          'environment': config.environment,
          'sessionId': sessionId,
          'collectAnalytics': false,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _logger.error('configureAndCollect timeout after 30 seconds');
          throw PlatformException(
            code: 'TIMEOUT',
            message: 'Data collection timeout after 30 seconds',
          );
        },
      );

      _logger.info('configureAndCollect succeeded – status: $rawResult');
      return KountResult(success: true, sessionId: sessionId);
    } on PlatformException catch (e) {
      final msg = 'configureAndCollect failed: ${e.message}';
      _logger.error(msg);
      return KountResult(success: false, error: msg);
    } catch (e) {
      final msg = 'Unexpected error in configureAndCollect: $e';
      _logger.error(msg);
      return KountResult(success: false, error: msg);
    }
  }

  /// Solicita el permiso de ubicación explícitamente.
  /// Retorna `true` si fue concedido, `false` si fue denegado.
  Future<bool> requestLocationPermission() async {
    try {
      final bool? granted =
          await _platform.invokeMethod<bool>('requestLocationPermission');
      return granted ?? false;
    } on PlatformException catch (e) {
      _logger.error('Permission request failed: ${e.message}');
      return false;
    }
  }
}
