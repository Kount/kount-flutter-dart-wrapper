import 'package:uuid/uuid.dart';
import '../models/kount_config.dart';
import '../models/kount_result.dart';
import 'kount_service.dart';

/// Manager for Kount SDK sessions with session ID generation and management
class KountSessionManager {
  final KountService _service;

  /// Exposes the underlying [KountService] for direct access.
  KountService get service => _service;
  String? _currentSessionId;

  /// Creates a new KountSessionManager
  ///
  /// Parameters:
  ///   - [service]: Optional. Custom KountService instance. Creates default if not provided
  KountSessionManager({KountService? service})
      : _service = service ?? KountService();

  /// Initializes the manager with the provided configuration
  ///
  /// Must be called before using other methods
  ///
  /// Example:
  /// ```dart
  /// final config = KountConfig(
  ///   merchantId: '999999',
  ///   environment: 'TEST',
  /// );
  /// manager.initialize(config);
  /// ```
  void initialize(KountConfig config) {
    // config stored for reference; native SDK is configured on collect
  }

  /// Generates a new session ID using UUID v4 without hyphens
  ///
  /// Returns the generated session ID and stores it internally
  ///
  /// Example:
  /// ```dart
  /// final sessionId = manager.generateSessionId();
  /// print(sessionId); // UUID format without hyphens: 550e8400e29b41d4a716446655440000
  /// ```
  String generateSessionId() {
    _currentSessionId = const Uuid().v4().replaceAll('-', '');
    return _currentSessionId!;
  }

  /// Gets the current session ID
  ///
  /// Returns null if no session has been generated yet
  ///
  /// Example:
  /// ```dart
  /// final sessionId = manager.currentSessionId;
  /// if (sessionId != null) {
  ///   print('Current session: $sessionId');
  /// }
  /// ```
  String? get currentSessionId => _currentSessionId;

  /// Configures the SDK and collects data in a single call
  ///
  /// This is a convenience method that:
  /// 1. Initializes with the provided config
  /// 2. Configures the SDK
  /// 3. Generates a new session ID
  /// 4. Collects data
  /// 5. Returns the result
  ///
  /// Example:
  /// ```dart
  /// final config = KountConfig(
  ///   merchantId: '999999',
  ///   environment: 'TEST',
  /// );
  /// final result = await manager.configureAndCollect(config);
  /// if (result.success) {
  ///   print('Session: ${result.sessionId}');
  /// }
  /// ```
  Future<KountResult> configureAndCollect(KountConfig config) async {
    initialize(config);

    try {
      final sessionId = generateSessionId();
      // Use the single-call native method for efficiency
      return _service.configureAndCollect(config, sessionId);
    } catch (e) {
      return KountResult(
        success: false,
        error: 'Configuration and collection failed: $e',
      );
    }
  }

  /// Resets the current session ID to null
  ///
  /// Use this when you want to start a new session
  ///
  /// Example:
  /// ```dart
  /// manager.resetSession();
  /// final newSessionId = manager.generateSessionId();
  /// ```
  void resetSession() {
    _currentSessionId = null;
  }
}
