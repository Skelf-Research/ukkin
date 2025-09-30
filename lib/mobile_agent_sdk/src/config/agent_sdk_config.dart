import '../plugins/plugin_interface.dart';

/// Configuration class for the Mobile Agent SDK
class AgentSDKConfig {
  /// Whether to enable voice processing capabilities
  final bool enableVoice;

  /// Whether to enable computer vision capabilities
  final bool enableVision;

  /// Whether to enable app integration capabilities
  final bool enableIntegrations;

  /// Whether to enable performance optimization
  final bool enablePerformanceOptimization;

  /// Whether to enable plugin system
  final bool enablePlugins;

  /// Whether to enable analytics and telemetry
  final bool enableAnalytics;

  /// Whether to enable debug logging
  final bool enableDebugLogging;

  /// Voice processing configuration
  final VoiceConfig voiceConfig;

  /// Computer vision configuration
  final VisionConfig visionConfig;

  /// Integration configuration
  final IntegrationConfig integrationConfig;

  /// Performance configuration
  final PerformanceConfig performanceConfig;

  /// List of plugins to load
  final List<PluginConfig> plugins;

  /// Analytics configuration
  final AnalyticsConfig analyticsConfig;

  const AgentSDKConfig({
    this.enableVoice = true,
    this.enableVision = true,
    this.enableIntegrations = true,
    this.enablePerformanceOptimization = true,
    this.enablePlugins = false,
    this.enableAnalytics = false,
    this.enableDebugLogging = false,
    this.voiceConfig = const VoiceConfig(),
    this.visionConfig = const VisionConfig(),
    this.integrationConfig = const IntegrationConfig(),
    this.performanceConfig = const PerformanceConfig(),
    this.plugins = const [],
    this.analyticsConfig = const AnalyticsConfig(),
  });

  /// Create a configuration for development
  factory AgentSDKConfig.development() {
    return AgentSDKConfig(
      enableDebugLogging: true,
      enableAnalytics: false,
      voiceConfig: VoiceConfig.development(),
      visionConfig: VisionConfig.development(),
      integrationConfig: IntegrationConfig.development(),
      performanceConfig: PerformanceConfig.development(),
    );
  }

  /// Create a configuration for production
  factory AgentSDKConfig.production() {
    return AgentSDKConfig(
      enableDebugLogging: false,
      enableAnalytics: true,
      enablePerformanceOptimization: true,
      voiceConfig: VoiceConfig.production(),
      visionConfig: VisionConfig.production(),
      integrationConfig: IntegrationConfig.production(),
      performanceConfig: PerformanceConfig.production(),
    );
  }

  /// Create a minimal configuration with only basic features
  factory AgentSDKConfig.minimal() {
    return AgentSDKConfig(
      enableVoice: false,
      enableVision: false,
      enableIntegrations: false,
      enablePerformanceOptimization: false,
      enablePlugins: false,
      enableAnalytics: false,
    );
  }
}

/// Voice processing configuration
class VoiceConfig {
  /// Default language for speech recognition
  final String defaultLanguage;

  /// Supported languages
  final List<String> supportedLanguages;

  /// Enable continuous listening
  final bool enableContinuousListening;

  /// Enable voice activity detection
  final bool enableVAD;

  /// Enable noise cancellation
  final bool enableNoiseCancellation;

  /// Voice recognition timeout in milliseconds
  final int recognitionTimeout;

  /// Voice synthesis configuration
  final VoiceSynthesisConfig synthesisConfig;

  const VoiceConfig({
    this.defaultLanguage = 'en-US',
    this.supportedLanguages = const ['en-US', 'es-ES', 'fr-FR', 'de-DE'],
    this.enableContinuousListening = false,
    this.enableVAD = true,
    this.enableNoiseCancellation = true,
    this.recognitionTimeout = 30000,
    this.synthesisConfig = const VoiceSynthesisConfig(),
  });

  factory VoiceConfig.development() {
    return VoiceConfig(
      enableContinuousListening: true,
      recognitionTimeout: 60000,
    );
  }

  factory VoiceConfig.production() {
    return VoiceConfig(
      enableNoiseCancellation: true,
      enableVAD: true,
    );
  }
}

/// Voice synthesis configuration
class VoiceSynthesisConfig {
  /// Enable text-to-speech
  final bool enableTTS;

  /// Default voice for synthesis
  final String defaultVoice;

  /// Speech rate (0.5 to 2.0)
  final double speechRate;

  /// Speech pitch (0.5 to 2.0)
  final double speechPitch;

  const VoiceSynthesisConfig({
    this.enableTTS = true,
    this.defaultVoice = 'default',
    this.speechRate = 1.0,
    this.speechPitch = 1.0,
  });
}

/// Computer vision configuration
class VisionConfig {
  /// Enable screen understanding
  final bool enableScreenUnderstanding;

  /// Enable image analysis
  final bool enableImageAnalysis;

  /// Enable object detection
  final bool enableObjectDetection;

  /// Enable text extraction (OCR)
  final bool enableTextExtraction;

  /// Vision model configuration
  final VisionModelConfig modelConfig;

  /// Performance settings
  final VisionPerformanceConfig performanceConfig;

  const VisionConfig({
    this.enableScreenUnderstanding = true,
    this.enableImageAnalysis = true,
    this.enableObjectDetection = true,
    this.enableTextExtraction = true,
    this.modelConfig = const VisionModelConfig(),
    this.performanceConfig = const VisionPerformanceConfig(),
  });

  factory VisionConfig.development() {
    return VisionConfig(
      performanceConfig: VisionPerformanceConfig.development(),
    );
  }

  factory VisionConfig.production() {
    return VisionConfig(
      performanceConfig: VisionPerformanceConfig.production(),
    );
  }
}

/// Vision model configuration
class VisionModelConfig {
  /// Model quality level
  final VisionQuality quality;

  /// Enable GPU acceleration
  final bool enableGPUAcceleration;

  /// Model cache size in MB
  final int modelCacheSize;

  const VisionModelConfig({
    this.quality = VisionQuality.balanced,
    this.enableGPUAcceleration = true,
    this.modelCacheSize = 100,
  });
}

/// Vision quality levels
enum VisionQuality {
  low,
  balanced,
  high,
  maximum,
}

/// Vision performance configuration
class VisionPerformanceConfig {
  /// Maximum concurrent vision tasks
  final int maxConcurrentTasks;

  /// Image processing timeout in milliseconds
  final int processingTimeout;

  /// Maximum image resolution for processing
  final ImageResolution maxResolution;

  const VisionPerformanceConfig({
    this.maxConcurrentTasks = 2,
    this.processingTimeout = 10000,
    this.maxResolution = ImageResolution.hd,
  });

  factory VisionPerformanceConfig.development() {
    return VisionPerformanceConfig(
      maxConcurrentTasks = 1,
      processingTimeout = 30000,
    );
  }

  factory VisionPerformanceConfig.production() {
    return VisionPerformanceConfig(
      maxConcurrentTasks = 3,
      processingTimeout = 5000,
    );
  }
}

/// Image resolution options
enum ImageResolution {
  low,    // 480p
  sd,     // 720p
  hd,     // 1080p
  uhd,    // 4K
}

/// Integration configuration
class IntegrationConfig {
  /// Enable automatic app discovery
  final bool enableAppDiscovery;

  /// List of allowed app packages
  final List<String> allowedApps;

  /// List of blocked app packages
  final List<String> blockedApps;

  /// Security configuration
  final IntegrationSecurityConfig securityConfig;

  /// Workflow configuration
  final WorkflowConfig workflowConfig;

  const IntegrationConfig({
    this.enableAppDiscovery = true,
    this.allowedApps = const [],
    this.blockedApps = const [],
    this.securityConfig = const IntegrationSecurityConfig(),
    this.workflowConfig = const WorkflowConfig(),
  });

  factory IntegrationConfig.development() {
    return IntegrationConfig(
      securityConfig: IntegrationSecurityConfig.development(),
    );
  }

  factory IntegrationConfig.production() {
    return IntegrationConfig(
      securityConfig: IntegrationSecurityConfig.production(),
    );
  }
}

/// Integration security configuration
class IntegrationSecurityConfig {
  /// Enable sandbox mode for integrations
  final bool enableSandbox;

  /// Require user confirmation for actions
  final bool requireUserConfirmation;

  /// Enable permission validation
  final bool enablePermissionValidation;

  /// Action timeout in milliseconds
  final int actionTimeout;

  const IntegrationSecurityConfig({
    this.enableSandbox = true,
    this.requireUserConfirmation = true,
    this.enablePermissionValidation = true,
    this.actionTimeout = 30000,
  });

  factory IntegrationSecurityConfig.development() {
    return IntegrationSecurityConfig(
      requireUserConfirmation: false,
      actionTimeout: 60000,
    );
  }

  factory IntegrationSecurityConfig.production() {
    return IntegrationSecurityConfig(
      enableSandbox: true,
      requireUserConfirmation: true,
      enablePermissionValidation: true,
    );
  }
}

/// Workflow configuration
class WorkflowConfig {
  /// Enable workflow templates
  final bool enableTemplates;

  /// Enable custom workflow creation
  final bool enableCustomWorkflows;

  /// Maximum workflow steps
  final int maxWorkflowSteps;

  /// Workflow execution timeout in milliseconds
  final int executionTimeout;

  const WorkflowConfig({
    this.enableTemplates = true,
    this.enableCustomWorkflows = true,
    this.maxWorkflowSteps = 20,
    this.executionTimeout = 300000, // 5 minutes
  });
}

/// Performance configuration
class PerformanceConfig {
  /// Battery optimization level
  final OptimizationLevel batteryOptimization;

  /// Memory optimization level
  final OptimizationLevel memoryOptimization;

  /// Network optimization level
  final OptimizationLevel networkOptimization;

  /// Enable performance monitoring
  final bool enableMonitoring;

  /// Performance reporting interval in milliseconds
  final int reportingInterval;

  const PerformanceConfig({
    this.batteryOptimization = OptimizationLevel.balanced,
    this.memoryOptimization = OptimizationLevel.balanced,
    this.networkOptimization = OptimizationLevel.balanced,
    this.enableMonitoring = true,
    this.reportingInterval = 60000, // 1 minute
  });

  factory PerformanceConfig.development() {
    return PerformanceConfig(
      batteryOptimization: OptimizationLevel.performance,
      memoryOptimization: OptimizationLevel.performance,
      networkOptimization: OptimizationLevel.performance,
      reportingInterval: 10000, // 10 seconds
    );
  }

  factory PerformanceConfig.production() {
    return PerformanceConfig(
      batteryOptimization: OptimizationLevel.battery,
      memoryOptimization: OptimizationLevel.balanced,
      networkOptimization: OptimizationLevel.balanced,
    );
  }
}

/// Optimization levels
enum OptimizationLevel {
  battery,
  balanced,
  performance,
}

/// Analytics configuration
class AnalyticsConfig {
  /// Enable usage analytics
  final bool enableUsageAnalytics;

  /// Enable performance analytics
  final bool enablePerformanceAnalytics;

  /// Enable error reporting
  final bool enableErrorReporting;

  /// Enable crash reporting
  final bool enableCrashReporting;

  /// Analytics provider configuration
  final AnalyticsProvider provider;

  /// User consent status
  final bool userConsent;

  const AnalyticsConfig({
    this.enableUsageAnalytics = false,
    this.enablePerformanceAnalytics = false,
    this.enableErrorReporting = false,
    this.enableCrashReporting = false,
    this.provider = AnalyticsProvider.none,
    this.userConsent = false,
  });
}

/// Analytics providers
enum AnalyticsProvider {
  none,
  firebase,
  custom,
}