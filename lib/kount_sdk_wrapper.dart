/// Kount SDK Flutter Helper Library
///
/// A comprehensive helper library for integrating the Kount SDK in Flutter applications.
/// Provides high-level APIs for session management, configuration, and data collection.
///
/// Example usage:
/// ```dart
/// import 'package:kount_sdk_wrapper/kount_sdk_wrapper.dart';
///
/// final manager = KountSessionManager();
/// final config = KountConfig(
///   merchantId: '999999',
///   environment: 'TEST',
/// );
///
/// final result = await manager.configureAndCollect(config);
/// if (result.success) {
///   print('Session: ${result.sessionId}');
/// } else {
///   print('Error: ${result.error}');
/// }
/// ```
library kount_sdk_wrapper;

// Models
export 'src/models/kount_config.dart';
export 'src/models/kount_result.dart';

// Services
export 'src/services/kount_service.dart';
export 'src/services/kount_session_manager.dart';

// Utils
export 'src/utils/kount_logger.dart';
