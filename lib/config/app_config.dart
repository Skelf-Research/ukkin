import 'dart:convert';

/// Main application configuration schema
class AppConfig {
  final ModelConfig model;
  final AutomationConfig automation;
  final PrivacyConfig privacy;
  final NotificationConfig notifications;
  final AgentConfig agents;
  final UIConfig ui;

  const AppConfig({
    this.model = const ModelConfig(),
    this.automation = const AutomationConfig(),
    this.privacy = const PrivacyConfig(),
    this.notifications = const NotificationConfig(),
    this.agents = const AgentConfig(),
    this.ui = const UIConfig(),
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      model: json['model'] != null
          ? ModelConfig.fromJson(json['model'])
          : const ModelConfig(),
      automation: json['automation'] != null
          ? AutomationConfig.fromJson(json['automation'])
          : const AutomationConfig(),
      privacy: json['privacy'] != null
          ? PrivacyConfig.fromJson(json['privacy'])
          : const PrivacyConfig(),
      notifications: json['notifications'] != null
          ? NotificationConfig.fromJson(json['notifications'])
          : const NotificationConfig(),
      agents: json['agents'] != null
          ? AgentConfig.fromJson(json['agents'])
          : const AgentConfig(),
      ui: json['ui'] != null
          ? UIConfig.fromJson(json['ui'])
          : const UIConfig(),
    );
  }

  Map<String, dynamic> toJson() => {
        'model': model.toJson(),
        'automation': automation.toJson(),
        'privacy': privacy.toJson(),
        'notifications': notifications.toJson(),
        'agents': agents.toJson(),
        'ui': ui.toJson(),
        'version': '1.0.0',
        'exportedAt': DateTime.now().toIso8601String(),
      };

  AppConfig copyWith({
    ModelConfig? model,
    AutomationConfig? automation,
    PrivacyConfig? privacy,
    NotificationConfig? notifications,
    AgentConfig? agents,
    UIConfig? ui,
  }) {
    return AppConfig(
      model: model ?? this.model,
      automation: automation ?? this.automation,
      privacy: privacy ?? this.privacy,
      notifications: notifications ?? this.notifications,
      agents: agents ?? this.agents,
      ui: ui ?? this.ui,
    );
  }

  String toExportString() => const JsonEncoder.withIndent('  ').convert(toJson());
}

/// Model/LLM configuration
class ModelConfig {
  final String modelPath;
  final String modelName;
  final int contextLength;
  final int maxTokens;
  final double temperature;
  final bool useGPU;
  final int threads;

  const ModelConfig({
    this.modelPath = '',
    this.modelName = 'stablelm-2-zephyr-1_6b',
    this.contextLength = 2048,
    this.maxTokens = 512,
    this.temperature = 0.7,
    this.useGPU = true,
    this.threads = 4,
  });

  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      modelPath: json['modelPath'] ?? '',
      modelName: json['modelName'] ?? 'stablelm-2-zephyr-1_6b',
      contextLength: json['contextLength'] ?? 2048,
      maxTokens: json['maxTokens'] ?? 512,
      temperature: (json['temperature'] ?? 0.7).toDouble(),
      useGPU: json['useGPU'] ?? true,
      threads: json['threads'] ?? 4,
    );
  }

  Map<String, dynamic> toJson() => {
        'modelPath': modelPath,
        'modelName': modelName,
        'contextLength': contextLength,
        'maxTokens': maxTokens,
        'temperature': temperature,
        'useGPU': useGPU,
        'threads': threads,
      };

  ModelConfig copyWith({
    String? modelPath,
    String? modelName,
    int? contextLength,
    int? maxTokens,
    double? temperature,
    bool? useGPU,
    int? threads,
  }) {
    return ModelConfig(
      modelPath: modelPath ?? this.modelPath,
      modelName: modelName ?? this.modelName,
      contextLength: contextLength ?? this.contextLength,
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      useGPU: useGPU ?? this.useGPU,
      threads: threads ?? this.threads,
    );
  }
}

/// Automation behavior configuration
class AutomationConfig {
  final bool requireConfirmation;
  final int confirmationTimeoutSeconds;
  final bool allowBackgroundExecution;
  final int maxConcurrentAgents;
  final bool respectBatteryOptimization;
  final int minBatteryPercent;
  final bool wifiOnlyForHeavyTasks;

  const AutomationConfig({
    this.requireConfirmation = true,
    this.confirmationTimeoutSeconds = 30,
    this.allowBackgroundExecution = true,
    this.maxConcurrentAgents = 3,
    this.respectBatteryOptimization = true,
    this.minBatteryPercent = 20,
    this.wifiOnlyForHeavyTasks = true,
  });

  factory AutomationConfig.fromJson(Map<String, dynamic> json) {
    return AutomationConfig(
      requireConfirmation: json['requireConfirmation'] ?? true,
      confirmationTimeoutSeconds: json['confirmationTimeoutSeconds'] ?? 30,
      allowBackgroundExecution: json['allowBackgroundExecution'] ?? true,
      maxConcurrentAgents: json['maxConcurrentAgents'] ?? 3,
      respectBatteryOptimization: json['respectBatteryOptimization'] ?? true,
      minBatteryPercent: json['minBatteryPercent'] ?? 20,
      wifiOnlyForHeavyTasks: json['wifiOnlyForHeavyTasks'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'requireConfirmation': requireConfirmation,
        'confirmationTimeoutSeconds': confirmationTimeoutSeconds,
        'allowBackgroundExecution': allowBackgroundExecution,
        'maxConcurrentAgents': maxConcurrentAgents,
        'respectBatteryOptimization': respectBatteryOptimization,
        'minBatteryPercent': minBatteryPercent,
        'wifiOnlyForHeavyTasks': wifiOnlyForHeavyTasks,
      };
}

/// Privacy and data handling configuration
class PrivacyConfig {
  final bool localProcessingOnly;
  final bool encryptLocalData;
  final bool anonymizeAnalytics;
  final int dataRetentionDays;
  final bool allowScreenCapture;
  final List<String> sensitiveAppPackages;

  const PrivacyConfig({
    this.localProcessingOnly = true,
    this.encryptLocalData = true,
    this.anonymizeAnalytics = true,
    this.dataRetentionDays = 30,
    this.allowScreenCapture = true,
    this.sensitiveAppPackages = const ['com.google.android.apps.authenticator2'],
  });

  factory PrivacyConfig.fromJson(Map<String, dynamic> json) {
    return PrivacyConfig(
      localProcessingOnly: json['localProcessingOnly'] ?? true,
      encryptLocalData: json['encryptLocalData'] ?? true,
      anonymizeAnalytics: json['anonymizeAnalytics'] ?? true,
      dataRetentionDays: json['dataRetentionDays'] ?? 30,
      allowScreenCapture: json['allowScreenCapture'] ?? true,
      sensitiveAppPackages: List<String>.from(json['sensitiveAppPackages'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'localProcessingOnly': localProcessingOnly,
        'encryptLocalData': encryptLocalData,
        'anonymizeAnalytics': anonymizeAnalytics,
        'dataRetentionDays': dataRetentionDays,
        'allowScreenCapture': allowScreenCapture,
        'sensitiveAppPackages': sensitiveAppPackages,
      };
}

/// Notification configuration
class NotificationConfig {
  final bool enableNotifications;
  final bool showAgentProgress;
  final bool showTaskCompletion;
  final bool showErrors;
  final bool quietHoursEnabled;
  final int quietHoursStart; // Hour (0-23)
  final int quietHoursEnd;
  final bool vibrateOnComplete;

  const NotificationConfig({
    this.enableNotifications = true,
    this.showAgentProgress = true,
    this.showTaskCompletion = true,
    this.showErrors = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 7,
    this.vibrateOnComplete = true,
  });

  factory NotificationConfig.fromJson(Map<String, dynamic> json) {
    return NotificationConfig(
      enableNotifications: json['enableNotifications'] ?? true,
      showAgentProgress: json['showAgentProgress'] ?? true,
      showTaskCompletion: json['showTaskCompletion'] ?? true,
      showErrors: json['showErrors'] ?? true,
      quietHoursEnabled: json['quietHoursEnabled'] ?? false,
      quietHoursStart: json['quietHoursStart'] ?? 22,
      quietHoursEnd: json['quietHoursEnd'] ?? 7,
      vibrateOnComplete: json['vibrateOnComplete'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'enableNotifications': enableNotifications,
        'showAgentProgress': showAgentProgress,
        'showTaskCompletion': showTaskCompletion,
        'showErrors': showErrors,
        'quietHoursEnabled': quietHoursEnabled,
        'quietHoursStart': quietHoursStart,
        'quietHoursEnd': quietHoursEnd,
        'vibrateOnComplete': vibrateOnComplete,
      };
}

/// Agent behavior configuration
class AgentConfig {
  final bool autoStartOnBoot;
  final bool learnFromFeedback;
  final int memoryRetentionDays;
  final bool shareMemoryAcrossAgents;
  final Map<String, bool> enabledAgentTypes;

  const AgentConfig({
    this.autoStartOnBoot = false,
    this.learnFromFeedback = true,
    this.memoryRetentionDays = 90,
    this.shareMemoryAcrossAgents = true,
    this.enabledAgentTypes = const {
      'socialMedia': true,
      'communication': true,
      'shopping': true,
      'browser': true,
    },
  });

  factory AgentConfig.fromJson(Map<String, dynamic> json) {
    return AgentConfig(
      autoStartOnBoot: json['autoStartOnBoot'] ?? false,
      learnFromFeedback: json['learnFromFeedback'] ?? true,
      memoryRetentionDays: json['memoryRetentionDays'] ?? 90,
      shareMemoryAcrossAgents: json['shareMemoryAcrossAgents'] ?? true,
      enabledAgentTypes: Map<String, bool>.from(json['enabledAgentTypes'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'autoStartOnBoot': autoStartOnBoot,
        'learnFromFeedback': learnFromFeedback,
        'memoryRetentionDays': memoryRetentionDays,
        'shareMemoryAcrossAgents': shareMemoryAcrossAgents,
        'enabledAgentTypes': enabledAgentTypes,
      };
}

/// UI/UX configuration
class UIConfig {
  final String themeMode; // 'light', 'dark', 'system'
  final bool compactMode;
  final bool showAdvancedOptions;
  final bool hapticFeedback;
  final double textScale;
  final String accentColor;

  const UIConfig({
    this.themeMode = 'system',
    this.compactMode = false,
    this.showAdvancedOptions = false,
    this.hapticFeedback = true,
    this.textScale = 1.0,
    this.accentColor = '#6366F1',
  });

  factory UIConfig.fromJson(Map<String, dynamic> json) {
    return UIConfig(
      themeMode: json['themeMode'] ?? 'system',
      compactMode: json['compactMode'] ?? false,
      showAdvancedOptions: json['showAdvancedOptions'] ?? false,
      hapticFeedback: json['hapticFeedback'] ?? true,
      textScale: (json['textScale'] ?? 1.0).toDouble(),
      accentColor: json['accentColor'] ?? '#6366F1',
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'compactMode': compactMode,
        'showAdvancedOptions': showAdvancedOptions,
        'hapticFeedback': hapticFeedback,
        'textScale': textScale,
        'accentColor': accentColor,
      };
}
