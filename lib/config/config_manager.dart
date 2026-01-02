import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'app_config.dart';

/// Runtime configuration manager with persistence
class ConfigManager extends ChangeNotifier {
  static const String _configKey = 'ukkin_app_config';
  static const String _exportFileName = 'ukkin_config_export.json';

  static ConfigManager? _instance;
  static ConfigManager get instance => _instance ??= ConfigManager._();

  ConfigManager._();

  AppConfig _config = const AppConfig();
  bool _isInitialized = false;

  /// Current configuration
  AppConfig get config => _config;

  /// Whether the manager has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize and load configuration from storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);

      if (configJson != null) {
        final json = jsonDecode(configJson) as Map<String, dynamic>;
        _config = AppConfig.fromJson(json);
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load config: $e');
      _config = const AppConfig();
      _isInitialized = true;
    }
  }

  /// Update configuration and persist
  Future<void> updateConfig(AppConfig newConfig) async {
    _config = newConfig;
    await _saveConfig();
    notifyListeners();
  }

  /// Update a specific section of the configuration
  Future<void> updateModel(ModelConfig model) async {
    await updateConfig(_config.copyWith(model: model));
  }

  Future<void> updateAutomation(AutomationConfig automation) async {
    await updateConfig(_config.copyWith(automation: automation));
  }

  Future<void> updatePrivacy(PrivacyConfig privacy) async {
    await updateConfig(_config.copyWith(privacy: privacy));
  }

  Future<void> updateNotifications(NotificationConfig notifications) async {
    await updateConfig(_config.copyWith(notifications: notifications));
  }

  Future<void> updateAgents(AgentConfig agents) async {
    await updateConfig(_config.copyWith(agents: agents));
  }

  Future<void> updateUI(UIConfig ui) async {
    await updateConfig(_config.copyWith(ui: ui));
  }

  /// Save current configuration to persistent storage
  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_configKey, jsonEncode(_config.toJson()));
    } catch (e) {
      debugPrint('Failed to save config: $e');
    }
  }

  /// Reset configuration to defaults
  Future<void> resetToDefaults() async {
    _config = const AppConfig();
    await _saveConfig();
    notifyListeners();
  }

  /// Export configuration to a file
  Future<ExportResult> exportConfig() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_exportFileName');
      final exportString = _config.toExportString();
      await file.writeAsString(exportString);

      return ExportResult(
        success: true,
        filePath: file.path,
        message: 'Configuration exported successfully',
      );
    } catch (e) {
      return ExportResult(
        success: false,
        message: 'Failed to export: $e',
      );
    }
  }

  /// Export configuration as shareable string
  String exportAsString() {
    return _config.toExportString();
  }

  /// Import configuration from a file path
  Future<ImportResult> importFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return const ImportResult(
          success: false,
          message: 'File not found',
        );
      }

      final content = await file.readAsString();
      return await importFromString(content);
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Failed to import: $e',
      );
    }
  }

  /// Import configuration from a JSON string
  Future<ImportResult> importFromString(String jsonString) async {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate version compatibility
      final version = json['version'] as String?;
      if (version == null) {
        return const ImportResult(
          success: false,
          message: 'Invalid configuration format: missing version',
        );
      }

      final newConfig = AppConfig.fromJson(json);
      await updateConfig(newConfig);

      return ImportResult(
        success: true,
        message: 'Configuration imported successfully',
        importedVersion: version,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Failed to parse configuration: $e',
      );
    }
  }

  /// Validate current configuration
  ConfigValidation validate() {
    final errors = <String>[];
    final warnings = <String>[];

    // Model validation
    if (_config.model.contextLength < 512) {
      errors.add('Context length must be at least 512');
    }
    if (_config.model.temperature < 0 || _config.model.temperature > 2) {
      errors.add('Temperature must be between 0 and 2');
    }
    if (_config.model.threads < 1 || _config.model.threads > 16) {
      warnings.add('Thread count should be between 1 and 16');
    }

    // Automation validation
    if (_config.automation.maxConcurrentAgents < 1) {
      errors.add('Must allow at least 1 concurrent agent');
    }
    if (_config.automation.minBatteryPercent < 5) {
      warnings.add('Very low battery threshold may cause issues');
    }

    // Privacy validation
    if (_config.privacy.dataRetentionDays < 1) {
      errors.add('Data retention must be at least 1 day');
    }

    // Notification validation
    if (_config.notifications.quietHoursStart < 0 ||
        _config.notifications.quietHoursStart > 23) {
      errors.add('Quiet hours start must be 0-23');
    }

    // UI validation
    if (_config.ui.textScale < 0.5 || _config.ui.textScale > 2.0) {
      errors.add('Text scale must be between 0.5 and 2.0');
    }

    return ConfigValidation(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Get configuration diff between current and provided config
  Map<String, dynamic> getDiff(AppConfig other) {
    final currentJson = _config.toJson();
    final otherJson = other.toJson();

    return _deepDiff(currentJson, otherJson);
  }

  Map<String, dynamic> _deepDiff(Map<String, dynamic> a, Map<String, dynamic> b) {
    final diff = <String, dynamic>{};

    for (final key in {...a.keys, ...b.keys}) {
      final aVal = a[key];
      final bVal = b[key];

      if (aVal != bVal) {
        if (aVal is Map<String, dynamic> && bVal is Map<String, dynamic>) {
          final nested = _deepDiff(aVal, bVal);
          if (nested.isNotEmpty) {
            diff[key] = nested;
          }
        } else {
          diff[key] = {'from': aVal, 'to': bVal};
        }
      }
    }

    return diff;
  }
}

/// Result of export operation
class ExportResult {
  final bool success;
  final String? filePath;
  final String message;

  const ExportResult({
    required this.success,
    this.filePath,
    required this.message,
  });
}

/// Result of import operation
class ImportResult {
  final bool success;
  final String message;
  final String? importedVersion;

  const ImportResult({
    required this.success,
    required this.message,
    this.importedVersion,
  });
}

/// Configuration validation result
class ConfigValidation {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ConfigValidation({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
}
