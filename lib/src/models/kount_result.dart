/// Result of a Kount SDK data collection operation
class KountResult {
  /// Whether the operation was successful
  final bool success;

  /// Session ID returned by the Kount SDK (null if failed)
  final String? sessionId;

  /// Error message if the operation failed (null if successful)
  final String? error;

  /// Timestamp when this result was created
  final DateTime timestamp;

  /// Creates a new Kount result
  ///
  /// Parameters:
  ///   - [success]: Required. Whether the operation succeeded
  ///   - [sessionId]: Optional. The session ID from Kount SDK
  ///   - [error]: Optional. Error message if operation failed
  ///
  /// The [timestamp] is automatically set to the current time
  KountResult({
    required this.success,
    this.sessionId,
    this.error,
  }) : timestamp = DateTime.now();

  /// Returns a human-readable string representation
  @override
  String toString() =>
      'KountResult(success: $success, sessionId: $sessionId, error: $error, timestamp: $timestamp)';
}
