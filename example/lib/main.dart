import 'package:flutter/material.dart';
import 'package:kount_sdk_wrapper/kount_sdk_wrapper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kount SDK wrapper example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const KountHelperDemo(),
    );
  }
}

class KountHelperDemo extends StatefulWidget {
  const KountHelperDemo({Key? key}) : super(key: key);

  @override
  State<KountHelperDemo> createState() => _KountHelperDemoState();
}

class _KountHelperDemoState extends State<KountHelperDemo> {
  late KountSessionManager _manager;
  late KountLogger _logger;
  final _sessionIdController = TextEditingController();

  String _merchantId = '';
  String _environment = 'TEST';
  String? _sessionId = '';
  String _status = 'Ready';
  @override
  void initState() {
    super.initState();
    _logger = KountLogger();
    _manager = KountSessionManager();
  }

  @override
  void dispose() {
    _sessionIdController.dispose();
    super.dispose();
  }

   /// Detects if an error message corresponds to a configuration problem
   /// (empty Merchant ID, invalid environment, etc.) instead of a network
   /// or native SDK error.
   bool _isConfigurationError(String message) {
    final lower = message.toLowerCase();
    return (lower.contains('invalid') &&
            (lower.contains('config') ||
                lower.contains('merchant') ||
                lower.contains('environment'))) ||
        lower.contains('argumenterror') ||
        lower.contains('merchantid') ||
        lower.contains('invalid kount configuration');
  }

  Future<void> _configureAndCollect() async {
    setState(() {
      _status = 'Processing...';
    });

    final config = KountConfig(
      merchantId: _merchantId,
      environment: _environment,
      // collectAnalytics is not supported in Flutter wrappers
    );

     // Pre-validation on the client side before calling the native SDK.
     if (!config.isValid) {
       setState(() {
         _status = '⚠️ Incorrect configuration. Verify the Merchant ID and Environment.';
        _logger.error('Invalid configuration before collect: $config');
      });
      return;
    }

    try {
      final result = await _manager.configureAndCollect(config);

      setState(() {
        if (result.success) {
          _status = '✅ Success!';
          _sessionId = result.sessionId;
          _sessionIdController.text = _sessionId!;
          _logger.info('Collection succeeded: ${result.sessionId}');
         } else if (_isConfigurationError(result.error ?? '')) {
           _status = '⚠️ Incorrect configuration. Verify the Merchant ID and Environment.';
          _logger.error('Configuration error: ${result.error}');
        } else {
          _status = '❌ Failed: ${result.error}';
          _logger.error('Collection failed: ${result.error}');
        }
      });
     } on ArgumentError catch (e) {
       // Configuration errors thrown directly (e.g., invalid config
       // detected by KountService before calling the native channel).
       setState(() {
         _status = '⚠️ Incorrect configuration. Verify the Merchant ID and Environment.';
        _logger.error('Configuration ArgumentError: $e');
      });
    } catch (e) {
      final message = e.toString();
       setState(() {
         if (_isConfigurationError(message)) {
           _status = '⚠️ Incorrect configuration. Verify the Merchant ID and Environment.';
        } else {
          _status = '❌ Failed: $message';
        }
        _logger.error('Unexpected error during collect: $message');
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    final granted = await _manager.service.requestLocationPermission();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? '✅ Location permission already granted'
              : '⚙️ Settings opened — enable Location permission manually',
        ),
        backgroundColor: granted ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _generateNewSessionId() {
    final newSessionId = _manager.generateSessionId();
    _sessionIdController.text = newSessionId;
    setState(() {
      _sessionId = newSessionId;
      _logger.info('Generated new session ID: $newSessionId');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generated: $newSessionId'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetAll() {
    _manager.resetSession();
    _sessionIdController.clear();
    setState(() {
      _merchantId = '';
      _environment = 'TEST';
      _sessionId = '';
      _status = 'Ready';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset complete'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kount SDK Wrapper Example'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              elevation: 4,
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      key: const Key('collectionStatus'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Configuration Section
            const Text(
              'Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Merchant ID
            TextField(
              key: const Key('merchantIdField'),
              decoration: InputDecoration(
                labelText: 'Merchant ID',
                hintText: 'Enter merchant ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
               // Solution: Use fromValue to keep cursor at the end
               controller: TextEditingController.fromValue(
                TextEditingValue(
                  text: _merchantId,
                  selection: TextSelection.collapsed(offset: _merchantId.length),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _merchantId = value;
                });
              },
            ),
            const SizedBox(height: 16),

            TextField(
              key: const Key('sessionIdField'),
              decoration: InputDecoration(
                labelText: 'Session ID',
                hintText: 'Enter Session ID or leave blank to generate',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Clear session ID',
                  onPressed: () {
                    _sessionIdController.clear();
                    setState(() => _sessionId = '');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              controller: _sessionIdController,
              onChanged: (value) {
                setState(() {
                  _sessionId = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Environment Dropdown
            DropdownButtonFormField<String>(
              key: const Key('environmentDropdown'),
              value: _environment,
              decoration: InputDecoration(
                labelText: 'Environment',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: ['TEST', 'QA', 'PROD']
                  .map((env) => DropdownMenuItem(
                        value: env,
                        child: Text(env),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _environment = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Action Buttons
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Request location permission button
            OutlinedButton.icon(
              label: const Text('Request/Check Location Permission'),
              onPressed: _requestLocationPermission,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Generate Session Button
            OutlinedButton.icon(
              label: const Text('Generate New Session ID'),
              onPressed: _generateNewSessionId,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Reset All Button
            OutlinedButton.icon(
              key: const Key('resetAllButton'),
              icon: const Icon(Icons.restart_alt, color: Colors.red),
              label: const Text('Reset All', style: TextStyle(color: Colors.red)),
              onPressed: _resetAll,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Configure and Collect Button
            FilledButton.icon(
              label: const Text('Collect'),
              onPressed: _configureAndCollect,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
            ),
            const SizedBox(height: 24),

            // Info Section
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How to Use',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 12),
                     const Text(
                       '1. Enter your Merchant ID\n'
                       '2. Enter your session ID or leave blank to generate a new one\n'
                       '3. Select the Environment (TEST/QA/PROD)\n'
                       '4. Click "Collect" to start\n'
                       '\n'
                       'The helper will configure the SDK and collect device data in one call.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
