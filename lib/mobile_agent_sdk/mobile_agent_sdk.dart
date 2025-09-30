// Mobile Agent SDK - Main Library Export
library mobile_agent_sdk;

// Core Agent System
export 'src/core/agent.dart';
export 'src/core/agent_coordinator.dart';
export 'src/core/agent_registry.dart';
export 'src/core/message_system.dart';
export 'src/core/session_manager.dart';

// Platform Integration
export 'src/platform/platform_manager.dart';
export 'src/platform/performance_optimizer.dart';
export 'src/platform/network_optimizer.dart';
export 'src/platform/permission_manager.dart';

// Voice Processing
export 'src/voice/voice_processor.dart';
export 'src/voice/speech_recognizer.dart';
export 'src/voice/voice_synthesizer.dart';

// Computer Vision
export 'src/vision/vision_processor.dart';
export 'src/vision/screen_analyzer.dart';
export 'src/vision/image_analyzer.dart';

// Integration Framework
export 'src/integrations/integration_manager.dart';
export 'src/integrations/app_connector.dart';
export 'src/integrations/workflow_engine.dart';

// UI Components
export 'src/ui/agent_chat_interface.dart';
export 'src/ui/voice_input_widget.dart';
export 'src/ui/agent_status_widget.dart';
export 'src/ui/customization/agent_theme.dart';
export 'src/ui/customization/agent_features.dart';

// Configuration and Setup
export 'src/config/agent_sdk_config.dart';
export 'src/config/agent_capabilities.dart';

// Plugin System
export 'src/plugins/plugin_interface.dart';
export 'src/plugins/plugin_manager.dart';

// Data Models
export 'src/models/agent_message.dart';
export 'src/models/task_request.dart';
export 'src/models/agent_response.dart';
export 'src/models/session_data.dart';

// Utilities
export 'src/utils/logger.dart';
export 'src/utils/error_handler.dart';
export 'src/utils/performance_monitor.dart';

/// Main entry point for the Mobile Agent SDK
class MobileAgentSDK {
  static bool _initialized = false;
  static AgentSDKConfig? _config;

  /// Initialize the Mobile Agent SDK with configuration
  static Future<void> initialize(AgentSDKConfig config) async {
    if (_initialized) {
      throw StateError('Mobile Agent SDK already initialized');
    }

    _config = config;

    // Initialize core systems
    await _initializeCore();
    await _initializePlatform();
    await _initializeOptionalFeatures();

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

    await AgentRegistry.instance.shutdown();
    await PlatformManager.instance.shutdown();
    await IntegrationManager.instance.shutdown();

    _initialized = false;
    _config = null;
  }

  static Future<void> _initializeCore() async {
    // Initialize agent registry
    await AgentRegistry.instance.initialize();

    // Initialize session manager
    await SessionManager.instance.initialize();

    // Initialize message system
    MessageSystem.instance.initialize();
  }

  static Future<void> _initializePlatform() async {
    // Initialize platform manager
    await PlatformManager.instance.initialize();

    // Initialize performance optimization
    if (_config!.enablePerformanceOptimization) {
      await PerformanceOptimizer.instance.initialize();
    }

    // Initialize permission manager
    await PermissionManager.instance.initialize();
  }

  static Future<void> _initializeOptionalFeatures() async {
    // Initialize voice processing
    if (_config!.enableVoice) {
      await VoiceProcessor.instance.initialize(_config!.voiceConfig);
    }

    // Initialize computer vision
    if (_config!.enableVision) {
      await VisionProcessor.instance.initialize(_config!.visionConfig);
    }

    // Initialize integrations
    if (_config!.enableIntegrations) {
      await IntegrationManager.instance.initialize(_config!.integrationConfig);
    }

    // Initialize plugins
    if (_config!.enablePlugins) {
      await PluginManager.instance.initialize();
      await _loadConfiguredPlugins();
    }
  }

  static Future<void> _loadConfiguredPlugins() async {
    for (final pluginConfig in _config!.plugins) {
      try {
        await PluginManager.instance.loadPlugin(pluginConfig);
      } catch (e) {
        Logger.warning('Failed to load plugin: ${pluginConfig.name}', error: e);
      }
    }
  }
}