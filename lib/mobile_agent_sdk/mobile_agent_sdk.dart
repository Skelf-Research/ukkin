// Mobile Agent SDK - Main Library Export
//
// This SDK is planned for future development. Currently a placeholder.
// The full implementation will provide a standalone SDK for building
// mobile AI agent applications.
library mobile_agent_sdk;

/// Placeholder configuration for the Mobile Agent SDK
class AgentSDKConfig {
  final bool enablePerformanceOptimization;
  final bool enableVoice;
  final bool enableVision;
  final bool enableIntegrations;
  final bool enablePlugins;
  final VoiceConfig? voiceConfig;
  final VisionConfig? visionConfig;
  final IntegrationConfig? integrationConfig;
  final List<PluginConfig> plugins;

  const AgentSDKConfig({
    this.enablePerformanceOptimization = true,
    this.enableVoice = false,
    this.enableVision = false,
    this.enableIntegrations = false,
    this.enablePlugins = false,
    this.voiceConfig,
    this.visionConfig,
    this.integrationConfig,
    this.plugins = const [],
  });
}

/// Placeholder voice configuration
class VoiceConfig {
  const VoiceConfig();
}

/// Placeholder vision configuration
class VisionConfig {
  const VisionConfig();
}

/// Placeholder integration configuration
class IntegrationConfig {
  const IntegrationConfig();
}

/// Placeholder plugin configuration
class PluginConfig {
  final String name;
  const PluginConfig({required this.name});
}

/// Main entry point for the Mobile Agent SDK
///
/// Note: This is a placeholder implementation. Full SDK functionality
/// will be implemented in a future release.
class MobileAgentSDK {
  static bool _initialized = false;
  static AgentSDKConfig? _config;

  /// Initialize the Mobile Agent SDK with configuration
  static Future<void> initialize(AgentSDKConfig config) async {
    if (_initialized) {
      throw StateError('Mobile Agent SDK already initialized');
    }

    _config = config;
    _initialized = true;
  }

  /// Check if the SDK is initialized
  static bool get isInitialized => _initialized;

  /// Get current configuration
  static AgentSDKConfig get config {
    if (!_initialized || _config == null) {
      throw StateError('Mobile Agent SDK not initialized');
    }
    return _config!;
  }

  /// Shutdown the SDK and cleanup resources
  static Future<void> shutdown() async {
    if (!_initialized) return;
    _initialized = false;
    _config = null;
  }
}
