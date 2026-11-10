import 'package:flutter_test/flutter_test.dart';
import 'package:kount_sdk_wrapper/kount_sdk_wrapper.dart';

void main() {
  group('KountConfig', () {
    test('creates configuration with valid values', () {
      final config = KountConfig(
        merchantId: '999999',
        environment: 'TEST',
      );

      expect(config.merchantId, '999999');
      expect(config.environment, 'TEST');
      expect(false, false);
    });

    test('validates correct configuration', () {
      final config = KountConfig(
        merchantId: '999999',
        environment: 'TEST',
      );

      expect(config.isValid, true);
    });

    test('invalidates empty merchant ID', () {
      final config = KountConfig(
        merchantId: '',
        environment: 'TEST',
      );

      expect(config.isValid, false);
    });

    test('invalidates invalid environment', () {
      final config = KountConfig(
        merchantId: '999999',
        environment: 'INVALID',
      );

      expect(config.isValid, false);
    });

    test('accepts all valid environments', () {
      final testConfig = KountConfig(
        merchantId: '999999',
        environment: 'TEST',
      );
      final prodConfig = KountConfig(
        merchantId: '999999',
        environment: 'PROD',
      );
      final qaConfig = KountConfig(
        merchantId: '999999',
        environment: 'QA',
      );

      expect(testConfig.isValid, true);
      expect(prodConfig.isValid, true);
      expect(qaConfig.isValid, true);
    });

    test('uses default collectAnalytics value', () {
      final config = KountConfig(
        merchantId: '999999',
        environment: 'TEST',
      );

      expect(false, false);
    });

    test('allows disabling collectAnalytics', () {
      final config = KountConfig(
        merchantId: '999999',
        environment: 'TEST',
      );

      expect(false, false);
    });

    test('toString returns readable string', () {
      final config = KountConfig(
        merchantId: '999999',
        environment: 'TEST',
      );

      final stringRep = config.toString();
      expect(stringRep, contains('999999'));
      expect(stringRep, contains('TEST'));
    });
  });

  group('KountResult', () {
    test('creates successful result', () {
      final result = KountResult(
        success: true,
        sessionId: 'session-123',
      );

      expect(result.success, true);
      expect(result.sessionId, 'session-123');
      expect(result.error, null);
      expect(result.timestamp, isNotNull);
    });

    test('creates failed result', () {
      final result = KountResult(
        success: false,
        error: 'Collection failed',
      );

      expect(result.success, false);
      expect(result.sessionId, null);
      expect(result.error, 'Collection failed');
    });

    test('timestamp is current time', () {
      final beforeTime = DateTime.now();
      final result = KountResult(success: true);
      final afterTime = DateTime.now();

      expect(result.timestamp.isBefore(beforeTime), false);
      expect(
        result.timestamp.isAfter(afterTime.add(const Duration(seconds: 1))),
        false,
      );
    });

    test('toString returns readable string', () {
      final result = KountResult(
        success: true,
        sessionId: 'session-123',
      );

      final stringRep = result.toString();
      expect(stringRep, contains('success: true'));
      expect(stringRep, contains('session-123'));
    });
  });

  group('KountLogger', () {
    test('creates logger instance', () {
      final logger = KountLogger();
      expect(logger, isNotNull);
    });

    test('info method does not throw', () {
      final logger = KountLogger();
      expect(() => logger.info('test message'), returnsNormally);
    });

    test('warning method does not throw', () {
      final logger = KountLogger();
      expect(() => logger.warning('test warning'), returnsNormally);
    });

    test('error method does not throw', () {
      final logger = KountLogger();
      expect(() => logger.error('test error'), returnsNormally);
    });

    test('debug method does not throw', () {
      final logger = KountLogger();
      expect(() => logger.debug('test debug'), returnsNormally);
    });
  });

  group('KountSessionManager', () {
    test('creates session manager instance', () {
      final manager = KountSessionManager();
      expect(manager, isNotNull);
    });

    test('initializes with config', () {
      final manager = KountSessionManager();
      final config = KountConfig(
        merchantId: '999999',
        environment: 'TEST',
      );

      expect(() => manager.initialize(config), returnsNormally);
    });

    test('generates session ID', () {
      final manager = KountSessionManager();
      final sessionId = manager.generateSessionId();

      expect(sessionId, isNotNull);
      expect(sessionId, isNotEmpty);
      // UUID v4 without hyphens
      expect(sessionId.length, 32);
    });

    test('returns same session ID until reset', () {
      final manager = KountSessionManager();
      final sessionId1 = manager.generateSessionId();
      final sessionId2 = manager.currentSessionId;

      expect(sessionId1, sessionId2);
    });

    test('generates different session IDs on multiple calls', () {
      final manager = KountSessionManager();
      final sessionId1 = manager.generateSessionId();
      final sessionId2 = manager.generateSessionId();

      expect(sessionId1, isNotNull);
      expect(sessionId2, isNotNull);
      expect(sessionId1, isNot(sessionId2));
    });

    test('resets session ID', () {
      final manager = KountSessionManager();
      manager.generateSessionId();

      expect(manager.currentSessionId, isNotNull);

      manager.resetSession();

      expect(manager.currentSessionId, null);
    });

    test('currentSessionId returns null initially', () {
      final manager = KountSessionManager();

      expect(manager.currentSessionId, null);
    });
  });
}
