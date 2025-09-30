import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NetworkOptimizer {
  static const MethodChannel _channel = MethodChannel('network_optimizer');
  static NetworkOptimizer? _instance;

  NetworkOptimizer._();

  static NetworkOptimizer get instance {
    _instance ??= NetworkOptimizer._();
    return _instance!;
  }

  // Network optimization settings
  bool _compressionEnabled = true;
  bool _cachingEnabled = true;
  bool _prefetchingEnabled = true;
  bool _batteryAwareNetworking = true;
  Duration _requestTimeout = const Duration(seconds: 30);
  int _maxConcurrentRequests = 6;
  int _retryAttempts = 3;

  // Network state tracking
  NetworkConnectionType _connectionType = NetworkConnectionType.unknown;
  NetworkSpeed _networkSpeed = NetworkSpeed.unknown;
  bool _isMeteredConnection = false;

  final StreamController<NetworkState> _networkStateController =
      StreamController<NetworkState>.broadcast();

  Stream<NetworkState> get networkStateStream => _networkStateController.stream;

  Future<void> initialize() async {
    await _loadSettings();
    await _setupNetworkMonitoring();
    await _configureNetworkOptimizations();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _compressionEnabled = prefs.getBool('compression_enabled') ?? true;
    _cachingEnabled = prefs.getBool('caching_enabled') ?? true;
    _prefetchingEnabled = prefs.getBool('prefetching_enabled') ?? true;
    _batteryAwareNetworking = prefs.getBool('battery_aware_networking') ?? true;
    _maxConcurrentRequests = prefs.getInt('max_concurrent_requests') ?? 6;
    _retryAttempts = prefs.getInt('retry_attempts') ?? 3;

    final timeoutSeconds = prefs.getInt('request_timeout_seconds') ?? 30;
    _requestTimeout = Duration(seconds: timeoutSeconds);
  }

  Future<void> _setupNetworkMonitoring() async {
    try {
      // Start monitoring network changes
      await _channel.invokeMethod('startNetworkMonitoring');

      // Listen for network state changes
      _channel.setMethodCallHandler(_handleNetworkStateChange);

      // Get initial network state
      await _updateNetworkState();
    } catch (e) {
      debugPrint('Network monitoring setup failed: $e');
    }
  }

  Future<void> _handleNetworkStateChange(MethodCall call) async {
    switch (call.method) {
      case 'onNetworkStateChanged':
        final data = Map<String, dynamic>.from(call.arguments);
        await _processNetworkStateChange(data);
        break;
      case 'onConnectionTypeChanged':
        final connectionType = call.arguments['connectionType'] as String;
        _connectionType = _parseConnectionType(connectionType);
        await _adaptToConnectionType();
        break;
      case 'onNetworkSpeedChanged':
        final speed = call.arguments['speed'] as String;
        _networkSpeed = _parseNetworkSpeed(speed);
        await _adaptToNetworkSpeed();
        break;
    }
  }

  Future<void> _processNetworkStateChange(Map<String, dynamic> data) async {
    final isConnected = data['isConnected'] as bool? ?? false;
    final connectionType = _parseConnectionType(data['connectionType'] as String? ?? 'unknown');
    final isMetered = data['isMetered'] as bool? ?? false;
    final speed = _parseNetworkSpeed(data['speed'] as String? ?? 'unknown');

    _connectionType = connectionType;
    _isMeteredConnection = isMetered;
    _networkSpeed = speed;

    final networkState = NetworkState(
      isConnected: isConnected,
      connectionType: connectionType,
      isMetered: isMetered,
      speed: speed,
    );

    _networkStateController.add(networkState);

    // Adapt optimizations based on new state
    await _adaptOptimizations();
  }

  Future<void> _configureNetworkOptimizations() async {
    try {
      await _channel.invokeMethod('configureNetworkOptimizations', {
        'compressionEnabled': _compressionEnabled,
        'cachingEnabled': _cachingEnabled,
        'maxConcurrentRequests': _maxConcurrentRequests,
        'requestTimeoutMs': _requestTimeout.inMilliseconds,
        'retryAttempts': _retryAttempts,
      });
    } catch (e) {
      debugPrint('Network optimization configuration failed: $e');
    }
  }

  Future<void> _updateNetworkState() async {
    try {
      final result = await _channel.invokeMethod('getNetworkState');
      final data = Map<String, dynamic>.from(result);
      await _processNetworkStateChange(data);
    } catch (e) {
      debugPrint('Network state update failed: $e');
    }
  }

  Future<void> _adaptOptimizations() async {
    // Adapt to connection type
    await _adaptToConnectionType();

    // Adapt to network speed
    await _adaptToNetworkSpeed();

    // Adapt to metered connection
    await _adaptToMeteredConnection();
  }

  Future<void> _adaptToConnectionType() async {
    switch (_connectionType) {
      case NetworkConnectionType.wifi:
        await _enableFullOptimizations();
        break;
      case NetworkConnectionType.cellular:
        await _enableDataSavingOptimizations();
        break;
      case NetworkConnectionType.ethernet:
        await _enableFullOptimizations();
        break;
      case NetworkConnectionType.none:
        await _enableOfflineMode();
        break;
      case NetworkConnectionType.unknown:
        await _enableConservativeOptimizations();
        break;
    }
  }

  Future<void> _adaptToNetworkSpeed() async {
    switch (_networkSpeed) {
      case NetworkSpeed.slow:
        await _enableSlowNetworkOptimizations();
        break;
      case NetworkSpeed.moderate:
        await _enableModerateNetworkOptimizations();
        break;
      case NetworkSpeed.fast:
        await _enableFastNetworkOptimizations();
        break;
      case NetworkSpeed.unknown:
        await _enableConservativeOptimizations();
        break;
    }
  }

  Future<void> _adaptToMeteredConnection() async {
    if (_isMeteredConnection && _batteryAwareNetworking) {
      await _enableDataSavingOptimizations();
    }
  }

  Future<void> _enableFullOptimizations() async {
    try {
      await _channel.invokeMethod('setNetworkOptimizationLevel', {
        'level': 'full',
        'maxConcurrentRequests': _maxConcurrentRequests,
        'prefetchingEnabled': _prefetchingEnabled,
        'compressionEnabled': _compressionEnabled,
      });
    } catch (e) {
      debugPrint('Full optimization setup failed: $e');
    }
  }

  Future<void> _enableDataSavingOptimizations() async {
    try {
      await _channel.invokeMethod('setNetworkOptimizationLevel', {
        'level': 'data_saving',
        'maxConcurrentRequests': 3,
        'prefetchingEnabled': false,
        'compressionEnabled': true,
        'imageQuality': 'low',
      });
    } catch (e) {
      debugPrint('Data saving optimization setup failed: $e');
    }
  }

  Future<void> _enableConservativeOptimizations() async {
    try {
      await _channel.invokeMethod('setNetworkOptimizationLevel', {
        'level': 'conservative',
        'maxConcurrentRequests': 4,
        'prefetchingEnabled': false,
        'compressionEnabled': _compressionEnabled,
      });
    } catch (e) {
      debugPrint('Conservative optimization setup failed: $e');
    }
  }

  Future<void> _enableSlowNetworkOptimizations() async {
    try {
      await _channel.invokeMethod('setNetworkOptimizationLevel', {
        'level': 'slow_network',
        'maxConcurrentRequests': 2,
        'prefetchingEnabled': false,
        'compressionEnabled': true,
        'timeoutMultiplier': 2.0,
        'retryAttempts': _retryAttempts + 1,
      });
    } catch (e) {
      debugPrint('Slow network optimization setup failed: $e');
    }
  }

  Future<void> _enableModerateNetworkOptimizations() async {
    try {
      await _channel.invokeMethod('setNetworkOptimizationLevel', {
        'level': 'moderate_network',
        'maxConcurrentRequests': 4,
        'prefetchingEnabled': _prefetchingEnabled,
        'compressionEnabled': _compressionEnabled,
      });
    } catch (e) {
      debugPrint('Moderate network optimization setup failed: $e');
    }
  }

  Future<void> _enableFastNetworkOptimizations() async {
    try {
      await _channel.invokeMethod('setNetworkOptimizationLevel', {
        'level': 'fast_network',
        'maxConcurrentRequests': _maxConcurrentRequests,
        'prefetchingEnabled': _prefetchingEnabled,
        'compressionEnabled': false, // Less needed on fast connections
      });
    } catch (e) {
      debugPrint('Fast network optimization setup failed: $e');
    }
  }

  Future<void> _enableOfflineMode() async {
    try {
      await _channel.invokeMethod('setNetworkOptimizationLevel', {
        'level': 'offline',
        'cachingEnabled': true,
        'offlineModeEnabled': true,
      });
    } catch (e) {
      debugPrint('Offline mode setup failed: $e');
    }
  }

  // Public API for manual optimization control
  Future<void> setCompressionEnabled(bool enabled) async {
    _compressionEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('compression_enabled', enabled);
    await _configureNetworkOptimizations();
  }

  Future<void> setCachingEnabled(bool enabled) async {
    _cachingEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('caching_enabled', enabled);
    await _configureNetworkOptimizations();
  }

  Future<void> setPrefetchingEnabled(bool enabled) async {
    _prefetchingEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prefetching_enabled', enabled);
    await _configureNetworkOptimizations();
  }

  Future<void> setBatteryAwareNetworking(bool enabled) async {
    _batteryAwareNetworking = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('battery_aware_networking', enabled);
  }

  Future<void> setMaxConcurrentRequests(int count) async {
    _maxConcurrentRequests = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('max_concurrent_requests', count);
    await _configureNetworkOptimizations();
  }

  Future<void> setRequestTimeout(Duration timeout) async {
    _requestTimeout = timeout;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('request_timeout_seconds', timeout.inSeconds);
    await _configureNetworkOptimizations();
  }

  Future<void> setRetryAttempts(int attempts) async {
    _retryAttempts = attempts;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('retry_attempts', attempts);
    await _configureNetworkOptimizations();
  }

  // Network testing and diagnostics
  Future<NetworkDiagnostics> runNetworkDiagnostics() async {
    try {
      final result = await _channel.invokeMethod('runNetworkDiagnostics');
      return NetworkDiagnostics.fromMap(Map<String, dynamic>.from(result));
    } catch (e) {
      debugPrint('Network diagnostics failed: $e');
      return NetworkDiagnostics.empty();
    }
  }

  Future<double> measureLatency(String host) async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.head(Uri.parse('https://$host')).timeout(_requestTimeout);
      stopwatch.stop();

      if (response.statusCode == 200) {
        return stopwatch.elapsedMilliseconds.toDouble();
      }
    } catch (e) {
      debugPrint('Latency measurement failed: $e');
    }
    return -1.0;
  }

  Future<double> measureBandwidth() async {
    try {
      final result = await _channel.invokeMethod('measureBandwidth');
      return (result as num).toDouble();
    } catch (e) {
      debugPrint('Bandwidth measurement failed: $e');
      return -1.0;
    }
  }

  // Helper methods
  NetworkConnectionType _parseConnectionType(String type) {
    switch (type.toLowerCase()) {
      case 'wifi':
        return NetworkConnectionType.wifi;
      case 'cellular':
        return NetworkConnectionType.cellular;
      case 'ethernet':
        return NetworkConnectionType.ethernet;
      case 'none':
        return NetworkConnectionType.none;
      default:
        return NetworkConnectionType.unknown;
    }
  }

  NetworkSpeed _parseNetworkSpeed(String speed) {
    switch (speed.toLowerCase()) {
      case 'slow':
        return NetworkSpeed.slow;
      case 'moderate':
        return NetworkSpeed.moderate;
      case 'fast':
        return NetworkSpeed.fast;
      default:
        return NetworkSpeed.unknown;
    }
  }

  // Getters
  NetworkConnectionType get connectionType => _connectionType;
  NetworkSpeed get networkSpeed => _networkSpeed;
  bool get isMeteredConnection => _isMeteredConnection;
  bool get compressionEnabled => _compressionEnabled;
  bool get cachingEnabled => _cachingEnabled;
  bool get prefetchingEnabled => _prefetchingEnabled;
  bool get batteryAwareNetworking => _batteryAwareNetworking;
  Duration get requestTimeout => _requestTimeout;
  int get maxConcurrentRequests => _maxConcurrentRequests;
  int get retryAttempts => _retryAttempts;

  void dispose() {
    _networkStateController.close();
  }
}

enum NetworkConnectionType {
  wifi,
  cellular,
  ethernet,
  none,
  unknown,
}

enum NetworkSpeed {
  slow,
  moderate,
  fast,
  unknown,
}

class NetworkState {
  final bool isConnected;
  final NetworkConnectionType connectionType;
  final bool isMetered;
  final NetworkSpeed speed;

  NetworkState({
    required this.isConnected,
    required this.connectionType,
    required this.isMetered,
    required this.speed,
  });
}

class NetworkDiagnostics {
  final double latency;
  final double bandwidth;
  final double packetLoss;
  final String connectionQuality;
  final Map<String, dynamic> additionalMetrics;

  NetworkDiagnostics({
    required this.latency,
    required this.bandwidth,
    required this.packetLoss,
    required this.connectionQuality,
    required this.additionalMetrics,
  });

  factory NetworkDiagnostics.fromMap(Map<String, dynamic> map) {
    return NetworkDiagnostics(
      latency: (map['latency'] as num?)?.toDouble() ?? -1.0,
      bandwidth: (map['bandwidth'] as num?)?.toDouble() ?? -1.0,
      packetLoss: (map['packetLoss'] as num?)?.toDouble() ?? 0.0,
      connectionQuality: map['connectionQuality'] as String? ?? 'unknown',
      additionalMetrics: Map<String, dynamic>.from(map['additionalMetrics'] ?? {}),
    );
  }

  factory NetworkDiagnostics.empty() {
    return NetworkDiagnostics(
      latency: -1.0,
      bandwidth: -1.0,
      packetLoss: 0.0,
      connectionQuality: 'unknown',
      additionalMetrics: {},
    );
  }
}