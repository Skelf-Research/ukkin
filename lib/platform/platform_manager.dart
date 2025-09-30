import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'performance_optimizer.dart';
import 'network_optimizer.dart';

class PlatformManager {
  static PlatformManager? _instance;

  PlatformManager._();

  static PlatformManager get instance {
    _instance ??= PlatformManager._();
    return _instance!;
  }

  late final PerformanceOptimizer _performanceOptimizer;
  late final NetworkOptimizer _networkOptimizer;
  late final PerformanceMonitor _performanceMonitor;

  bool _isInitialized = false;
  PlatformConfiguration _configuration = PlatformConfiguration.defaultConfig();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize optimizers
      _performanceOptimizer = PerformanceOptimizer.instance;
      _networkOptimizer = NetworkOptimizer.instance;
      _performanceMonitor = PerformanceMonitor.instance;

      // Load platform-specific configuration
      await _loadPlatformConfiguration();

      // Initialize optimizers with configuration
      await _performanceOptimizer.initialize();
      await _networkOptimizer.initialize();

      // Apply platform-specific optimizations
      await _applyPlatformOptimizations();

      // Start monitoring
      _performanceMonitor.startMonitoring();

      // Listen to network state changes
      _networkOptimizer.networkStateStream.listen(_handleNetworkStateChange);

      _isInitialized = true;
      debugPrint('Platform manager initialized successfully');
    } catch (e) {
      debugPrint('Platform manager initialization failed: $e');
    }
  }

  Future<void> _loadPlatformConfiguration() async {
    if (Platform.isAndroid) {
      _configuration = await _loadAndroidConfiguration();
    } else if (Platform.isIOS) {
      _configuration = await _loadIOSConfiguration();
    }
  }

  Future<PlatformConfiguration> _loadAndroidConfiguration() async {
    return PlatformConfiguration(
      // Android-specific optimizations
      enableHardwareAcceleration: true,
      aggressiveMemoryManagement: true,
      networkCompressionEnabled: true,
      backgroundProcessingLimited: true,
      batteryOptimizationEnabled: true,

      // Android performance settings
      maxConcurrentNetworkRequests: 6,
      networkRequestTimeout: Duration(seconds: 30),
      memoryTrimLevel: 'moderate',
      cacheMaxSize: 100 * 1024 * 1024, // 100MB

      // Android-specific features
      supportsPictureInPicture: await _checkPictureInPictureSupport(),
      supportsAdaptiveIcon: true,
      supportsShortcuts: true,
      supportsWidgets: true,
    );
  }

  Future<PlatformConfiguration> _loadIOSConfiguration() async {
    return PlatformConfiguration(
      // iOS-specific optimizations
      enableHardwareAcceleration: true,
      aggressiveMemoryManagement: false, // iOS handles this better
      networkCompressionEnabled: true,
      backgroundProcessingLimited: true,
      batteryOptimizationEnabled: true,

      // iOS performance settings
      maxConcurrentNetworkRequests: 4,
      networkRequestTimeout: Duration(seconds: 25),
      memoryTrimLevel: 'conservative',
      cacheMaxSize: 50 * 1024 * 1024, // 50MB (iOS is more memory-constrained)

      // iOS-specific features
      supportsPictureInPicture: false,
      supportsAdaptiveIcon: false,
      supportsShortcuts: await _checkShortcutSupport(),
      supportsWidgets: await _checkWidgetSupport(),
    );
  }

  Future<void> _applyPlatformOptimizations() async {
    // Apply performance optimizations
    await _performanceOptimizer.setLowMemoryMode(
      _configuration.aggressiveMemoryManagement
    );
    await _performanceOptimizer.setBatteryOptimization(
      _configuration.batteryOptimizationEnabled
    );
    await _performanceOptimizer.setBackgroundProcessing(
      !_configuration.backgroundProcessingLimited
    );

    // Apply network optimizations
    await _networkOptimizer.setCompressionEnabled(
      _configuration.networkCompressionEnabled
    );
    await _networkOptimizer.setMaxConcurrentRequests(
      _configuration.maxConcurrentNetworkRequests
    );
    await _networkOptimizer.setRequestTimeout(
      _configuration.networkRequestTimeout
    );
    await _networkOptimizer.setBatteryAwareNetworking(
      _configuration.batteryOptimizationEnabled
    );
  }

  void _handleNetworkStateChange(NetworkState state) async {
    debugPrint('Network state changed: ${state.connectionType}, speed: ${state.speed}');

    // Adapt optimizations based on network state
    if (state.isMetered || state.speed == NetworkSpeed.slow) {
      await _enableDataSavingMode();
    } else if (state.speed == NetworkSpeed.fast && !state.isMetered) {
      await _enablePerformanceMode();
    }
  }

  Future<void> _enableDataSavingMode() async {
    debugPrint('Enabling data saving mode');

    await _networkOptimizer.setCompressionEnabled(true);
    await _networkOptimizer.setPrefetchingEnabled(false);
    await _networkOptimizer.setMaxConcurrentRequests(2);

    await _performanceOptimizer.setLowMemoryMode(true);
  }

  Future<void> _enablePerformanceMode() async {
    debugPrint('Enabling performance mode');

    await _networkOptimizer.setCompressionEnabled(false);
    await _networkOptimizer.setPrefetchingEnabled(true);
    await _networkOptimizer.setMaxConcurrentRequests(
      _configuration.maxConcurrentNetworkRequests
    );

    await _performanceOptimizer.setLowMemoryMode(false);
  }

  // Platform feature detection
  Future<bool> _checkPictureInPictureSupport() async {
    try {
      const channel = MethodChannel('platform_features');
      final result = await channel.invokeMethod('supportsPictureInPicture');
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkShortcutSupport() async {
    try {
      const channel = MethodChannel('platform_features');
      final result = await channel.invokeMethod('supportsShortcuts');
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkWidgetSupport() async {
    try {
      const channel = MethodChannel('platform_features');
      final result = await channel.invokeMethod('supportsWidgets');
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  // Public API for dynamic optimization control
  Future<void> setOptimizationLevel(OptimizationLevel level) async {
    switch (level) {
      case OptimizationLevel.battery:
        await _enableBatteryOptimizations();
        break;
      case OptimizationLevel.performance:
        await _enablePerformanceOptimizations();
        break;
      case OptimizationLevel.balanced:
        await _enableBalancedOptimizations();
        break;
      case OptimizationLevel.custom:
        // Custom optimizations are handled via individual setting methods
        break;
    }
  }

  Future<void> _enableBatteryOptimizations() async {
    await _performanceOptimizer.setBatteryOptimization(true);
    await _performanceOptimizer.setLowMemoryMode(true);
    await _performanceOptimizer.setBackgroundProcessing(false);

    await _networkOptimizer.setCompressionEnabled(true);
    await _networkOptimizer.setPrefetchingEnabled(false);
    await _networkOptimizer.setMaxConcurrentRequests(2);
    await _networkOptimizer.setBatteryAwareNetworking(true);
  }

  Future<void> _enablePerformanceOptimizations() async {
    await _performanceOptimizer.setBatteryOptimization(false);
    await _performanceOptimizer.setLowMemoryMode(false);
    await _performanceOptimizer.setBackgroundProcessing(true);

    await _networkOptimizer.setCompressionEnabled(false);
    await _networkOptimizer.setPrefetchingEnabled(true);
    await _networkOptimizer.setMaxConcurrentRequests(8);
    await _networkOptimizer.setBatteryAwareNetworking(false);
  }

  Future<void> _enableBalancedOptimizations() async {
    await _performanceOptimizer.setBatteryOptimization(true);
    await _performanceOptimizer.setLowMemoryMode(false);
    await _performanceOptimizer.setBackgroundProcessing(true);

    await _networkOptimizer.setCompressionEnabled(true);
    await _networkOptimizer.setPrefetchingEnabled(true);
    await _networkOptimizer.setMaxConcurrentRequests(4);
    await _networkOptimizer.setBatteryAwareNetworking(true);
  }

  // Platform-specific actions
  Future<void> enablePictureInPicture() async {
    if (!_configuration.supportsPictureInPicture) return;

    try {
      const channel = MethodChannel('platform_actions');
      await channel.invokeMethod('enterPictureInPicture');
    } catch (e) {
      debugPrint('Picture-in-picture failed: $e');
    }
  }

  Future<void> addShortcut(String id, String label, String intent) async {
    if (!_configuration.supportsShortcuts) return;

    try {
      const channel = MethodChannel('platform_actions');
      await channel.invokeMethod('addShortcut', {
        'id': id,
        'label': label,
        'intent': intent,
      });
    } catch (e) {
      debugPrint('Add shortcut failed: $e');
    }
  }

  Future<void> updateWidget(String widgetId, Map<String, dynamic> data) async {
    if (!_configuration.supportsWidgets) return;

    try {
      const channel = MethodChannel('platform_actions');
      await channel.invokeMethod('updateWidget', {
        'widgetId': widgetId,
        'data': data,
      });
    } catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }

  // Diagnostics and monitoring
  Future<PlatformDiagnostics> getDiagnostics() async {
    final performanceMetrics = await _performanceOptimizer.getPerformanceMetrics();
    final memoryUsage = await _performanceOptimizer.getMemoryUsage();
    final batteryLevel = await _performanceOptimizer.getBatteryLevel();
    final networkDiagnostics = await _networkOptimizer.runNetworkDiagnostics();

    return PlatformDiagnostics(
      platform: Platform.operatingSystem,
      version: Platform.operatingSystemVersion,
      performanceMetrics: performanceMetrics,
      memoryUsage: memoryUsage,
      batteryLevel: batteryLevel,
      networkDiagnostics: networkDiagnostics,
      configuration: _configuration,
    );
  }

  // Getters
  PlatformConfiguration get configuration => _configuration;
  PerformanceOptimizer get performanceOptimizer => _performanceOptimizer;
  NetworkOptimizer get networkOptimizer => _networkOptimizer;
  bool get isInitialized => _isInitialized;

  void dispose() {
    _performanceMonitor.stopMonitoring();
    _performanceOptimizer.dispose();
    _networkOptimizer.dispose();
  }
}

class PlatformConfiguration {
  final bool enableHardwareAcceleration;
  final bool aggressiveMemoryManagement;
  final bool networkCompressionEnabled;
  final bool backgroundProcessingLimited;
  final bool batteryOptimizationEnabled;
  final int maxConcurrentNetworkRequests;
  final Duration networkRequestTimeout;
  final String memoryTrimLevel;
  final int cacheMaxSize;
  final bool supportsPictureInPicture;
  final bool supportsAdaptiveIcon;
  final bool supportsShortcuts;
  final bool supportsWidgets;

  PlatformConfiguration({
    required this.enableHardwareAcceleration,
    required this.aggressiveMemoryManagement,
    required this.networkCompressionEnabled,
    required this.backgroundProcessingLimited,
    required this.batteryOptimizationEnabled,
    required this.maxConcurrentNetworkRequests,
    required this.networkRequestTimeout,
    required this.memoryTrimLevel,
    required this.cacheMaxSize,
    required this.supportsPictureInPicture,
    required this.supportsAdaptiveIcon,
    required this.supportsShortcuts,
    required this.supportsWidgets,
  });

  factory PlatformConfiguration.defaultConfig() {
    return PlatformConfiguration(
      enableHardwareAcceleration: true,
      aggressiveMemoryManagement: false,
      networkCompressionEnabled: true,
      backgroundProcessingLimited: false,
      batteryOptimizationEnabled: true,
      maxConcurrentNetworkRequests: 4,
      networkRequestTimeout: Duration(seconds: 30),
      memoryTrimLevel: 'moderate',
      cacheMaxSize: 50 * 1024 * 1024,
      supportsPictureInPicture: false,
      supportsAdaptiveIcon: false,
      supportsShortcuts: false,
      supportsWidgets: false,
    );
  }
}

enum OptimizationLevel {
  battery,
  performance,
  balanced,
  custom,
}

class PlatformDiagnostics {
  final String platform;
  final String version;
  final Map<String, dynamic> performanceMetrics;
  final Map<String, dynamic> memoryUsage;
  final double batteryLevel;
  final NetworkDiagnostics networkDiagnostics;
  final PlatformConfiguration configuration;

  PlatformDiagnostics({
    required this.platform,
    required this.version,
    required this.performanceMetrics,
    required this.memoryUsage,
    required this.batteryLevel,
    required this.networkDiagnostics,
    required this.configuration,
  });
}