import 'package:flutter/foundation.dart';

/// Logger for Kount SDK operations with different log levels
class KountLogger {
  static const String _prefix = '[Kount]';

  /// Logs an informational message (debug mode only)
  void info(String message) {
    if (kDebugMode) print('$_prefix ℹ️ $message');
  }

  /// Logs a warning message (debug mode only)
  void warning(String message) {
    if (kDebugMode) print('$_prefix ⚠️ $message');
  }

  /// Logs an error message (debug mode only)
  void error(String message) {
    if (kDebugMode) print('$_prefix ❌ $message');
  }

  /// Logs a debug message (debug mode only)
  void debug(String message) {
    if (kDebugMode) print('$_prefix 🔍 $message');
  }
}

