import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../tools/tool.dart';
import '../models/task.dart';

class PrivacyManager extends Tool with ToolValidation {
  static const MethodChannel _platform = MethodChannel('ukkin.security/privacy');

  final Map<String, dynamic> _privacySettings = {};
  final Set<String> _sensitiveDataPatterns = {};
  final List<String> _dataAccessLog = [];

  PrivacyManager() {
    _initializeDefaultSettings();
  }

  @override
  String get name => 'privacy_manager';

  @override
  String get description => 'Manage privacy settings, data encryption, and secure automation';

  @override
  Map<String, String> get parameters => {
        'action': 'Action: set_privacy_level, encrypt_data, secure_delete, audit_access, block_tracking',
        'privacy_level': 'Privacy level: minimal, standard, strict, paranoid',
        'data_type': 'Type of data to protect: contacts, messages, photos, location, etc.',
        'data': 'Data to encrypt/protect',
        'audit_type': 'Audit type: access_log, permission_usage, data_collection',
      };

  @override
  bool canHandle(Task task) {
    return task.type == 'privacy' || task.type.startsWith('security_');
  }

  @override
  Future<bool> validate(Map<String, dynamic> parameters) async {
    return validateRequired(parameters, ['action']);
  }

  @override
  Future<dynamic> execute(Map<String, dynamic> parameters) async {
    if (!await validate(parameters)) {
      throw Exception('Invalid parameters for privacy manager');
    }

    final action = parameters['action'] as String;

    try {
      switch (action) {
        case 'set_privacy_level':
          return await _setPrivacyLevel(parameters['privacy_level']);
        case 'encrypt_data':
          return await _encryptData(parameters['data'], parameters['data_type']);
        case 'decrypt_data':
          return await _decryptData(parameters['encrypted_data'], parameters['data_type']);
        case 'secure_delete':
          return await _secureDelete(parameters['file_path']);
        case 'audit_access':
          return await _auditDataAccess(parameters['audit_type']);
        case 'block_tracking':
          return await _blockTracking(parameters['app_package']);
        case 'anonymize_data':
          return await _anonymizeData(parameters['data']);
        case 'check_permissions':
          return await _checkAppPermissions(parameters['app_package']);
        case 'revoke_permission':
          return await _revokePermission(parameters['app_package'], parameters['permission']);
        case 'enable_incognito':
          return await _enableIncognitoMode();
        case 'disable_incognito':
          return await _disableIncognitoMode();
        default:
          throw Exception('Unknown privacy action: $action');
      }
    } catch (e) {
      return ToolExecutionResult.failure('Privacy action failed: $e');
    }
  }

  void _initializeDefaultSettings() {
    _privacySettings.addAll({
      'privacy_level': 'standard',
      'auto_encrypt_sensitive': true,
      'block_trackers': true,
      'anonymize_logs': true,
      'secure_delete_files': true,
      'audit_data_access': true,
      'incognito_mode': false,
      'allowed_data_types': ['contacts', 'messages', 'calendar'],
      'blocked_apps': <String>[],
      'encryption_enabled': true,
    });

    _sensitiveDataPatterns.addAll([
      r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b', // Credit card
      r'\b\d{3}-\d{2}-\d{4}\b', // SSN
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', // Email
      r'\b\d{3}-\d{3}-\d{4}\b', // Phone number
      r'\b(?:password|pass|pwd|pin)\s*[:=]\s*\S+', // Passwords
    ]);
  }

  Future<ToolExecutionResult> _setPrivacyLevel(String? level) async {
    if (level == null) {
      return ToolExecutionResult.failure('Privacy level is required');
    }

    try {
      switch (level.toLowerCase()) {
        case 'minimal':
          _privacySettings['auto_encrypt_sensitive'] = false;
          _privacySettings['block_trackers'] = false;
          _privacySettings['anonymize_logs'] = false;
          break;
        case 'standard':
          _privacySettings['auto_encrypt_sensitive'] = true;
          _privacySettings['block_trackers'] = true;
          _privacySettings['anonymize_logs'] = true;
          break;
        case 'strict':
          _privacySettings['auto_encrypt_sensitive'] = true;
          _privacySettings['block_trackers'] = true;
          _privacySettings['anonymize_logs'] = true;
          _privacySettings['secure_delete_files'] = true;
          _privacySettings['audit_data_access'] = true;
          break;
        case 'paranoid':
          _privacySettings['auto_encrypt_sensitive'] = true;
          _privacySettings['block_trackers'] = true;
          _privacySettings['anonymize_logs'] = true;
          _privacySettings['secure_delete_files'] = true;
          _privacySettings['audit_data_access'] = true;
          _privacySettings['incognito_mode'] = true;
          break;
        default:
          return ToolExecutionResult.failure('Invalid privacy level: $level');
      }

      _privacySettings['privacy_level'] = level;

      return ToolExecutionResult.success({
        'action': 'set_privacy_level',
        'level': level,
        'settings': Map.from(_privacySettings),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Set privacy level failed: $e');
    }
  }

  Future<ToolExecutionResult> _encryptData(dynamic data, String? dataType) async {
    if (data == null) {
      return ToolExecutionResult.failure('Data to encrypt is required');
    }

    try {
      final dataString = data is String ? data : jsonEncode(data);

      // Check if data contains sensitive information
      final isSensitive = _containsSensitiveData(dataString);

      if (!_privacySettings['encryption_enabled'] && !isSensitive) {
        return ToolExecutionResult.success({
          'action': 'encrypt_data',
          'encrypted': false,
          'reason': 'Encryption disabled and data not sensitive',
          'data': data,
        });
      }

      // Simple encryption (in production, use proper encryption)
      final encryptedData = _simpleEncrypt(dataString);

      _logDataAccess('encrypt', dataType ?? 'unknown', encryptedData.length);

      return ToolExecutionResult.success({
        'action': 'encrypt_data',
        'encrypted': true,
        'data_type': dataType,
        'encrypted_data': encryptedData,
        'is_sensitive': isSensitive,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Encrypt data failed: $e');
    }
  }

  Future<ToolExecutionResult> _decryptData(String? encryptedData, String? dataType) async {
    if (encryptedData == null) {
      return ToolExecutionResult.failure('Encrypted data is required');
    }

    try {
      final decryptedData = _simpleDecrypt(encryptedData);

      _logDataAccess('decrypt', dataType ?? 'unknown', decryptedData.length);

      return ToolExecutionResult.success({
        'action': 'decrypt_data',
        'data_type': dataType,
        'decrypted_data': decryptedData,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Decrypt data failed: $e');
    }
  }

  Future<ToolExecutionResult> _secureDelete(String? filePath) async {
    if (filePath == null) {
      return ToolExecutionResult.failure('File path is required');
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ToolExecutionResult.failure('File does not exist: $filePath');
      }

      if (_privacySettings['secure_delete_files']) {
        // Overwrite file with random data multiple times
        await _overwriteFile(file);
      }

      // Delete the file
      await file.delete();

      _logDataAccess('secure_delete', 'file', filePath.length);

      return ToolExecutionResult.success({
        'action': 'secure_delete',
        'file_path': filePath,
        'secure_overwrite': _privacySettings['secure_delete_files'],
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Secure delete failed: $e');
    }
  }

  Future<ToolExecutionResult> _auditDataAccess(String? auditType) async {
    try {
      final auditData = <String, dynamic>{};

      switch (auditType) {
        case 'access_log':
          auditData['access_log'] = List.from(_dataAccessLog);
          break;
        case 'permission_usage':
          auditData['permission_usage'] = await _getPermissionUsageStats();
          break;
        case 'data_collection':
          auditData['data_collection'] = await _getDataCollectionStats();
          break;
        default:
          auditData['access_log'] = List.from(_dataAccessLog);
          auditData['permission_usage'] = await _getPermissionUsageStats();
          auditData['data_collection'] = await _getDataCollectionStats();
      }

      return ToolExecutionResult.success({
        'action': 'audit_access',
        'audit_type': auditType,
        'audit_data': auditData,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Audit data access failed: $e');
    }
  }

  Future<ToolExecutionResult> _blockTracking(String? appPackage) async {
    try {
      final result = await _platform.invokeMethod('blockTracking', {
        'appPackage': appPackage,
        'blockAll': appPackage == null,
      });

      if (appPackage != null) {
        final blockedApps = _privacySettings['blocked_apps'] as List<String>;
        if (!blockedApps.contains(appPackage)) {
          blockedApps.add(appPackage);
        }
      }

      return ToolExecutionResult.success({
        'action': 'block_tracking',
        'app_package': appPackage,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Block tracking failed: $e');
    }
  }

  Future<ToolExecutionResult> _anonymizeData(dynamic data) async {
    if (data == null) {
      return ToolExecutionResult.failure('Data to anonymize is required');
    }

    try {
      final dataString = data is String ? data : jsonEncode(data);
      final anonymizedData = _anonymizeString(dataString);

      return ToolExecutionResult.success({
        'action': 'anonymize_data',
        'original_length': dataString.length,
        'anonymized_data': anonymizedData,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Anonymize data failed: $e');
    }
  }

  Future<ToolExecutionResult> _checkAppPermissions(String? appPackage) async {
    if (appPackage == null) {
      return ToolExecutionResult.failure('App package is required');
    }

    try {
      final result = await _platform.invokeMethod('checkAppPermissions', {
        'appPackage': appPackage,
      });

      final permissions = result['permissions'] as Map<String, dynamic>?;

      return ToolExecutionResult.success({
        'action': 'check_permissions',
        'app_package': appPackage,
        'permissions': permissions ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Check app permissions failed: $e');
    }
  }

  Future<ToolExecutionResult> _revokePermission(String? appPackage, String? permission) async {
    if (appPackage == null || permission == null) {
      return ToolExecutionResult.failure('App package and permission are required');
    }

    try {
      final result = await _platform.invokeMethod('revokePermission', {
        'appPackage': appPackage,
        'permission': permission,
      });

      return ToolExecutionResult.success({
        'action': 'revoke_permission',
        'app_package': appPackage,
        'permission': permission,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Revoke permission failed: $e');
    }
  }

  Future<ToolExecutionResult> _enableIncognitoMode() async {
    try {
      _privacySettings['incognito_mode'] = true;

      final result = await _platform.invokeMethod('enableIncognitoMode');

      return ToolExecutionResult.success({
        'action': 'enable_incognito',
        'incognito_mode': true,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Enable incognito mode failed: $e');
    }
  }

  Future<ToolExecutionResult> _disableIncognitoMode() async {
    try {
      _privacySettings['incognito_mode'] = false;

      final result = await _platform.invokeMethod('disableIncognitoMode');

      return ToolExecutionResult.success({
        'action': 'disable_incognito',
        'incognito_mode': false,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Disable incognito mode failed: $e');
    }
  }

  bool _containsSensitiveData(String data) {
    for (final pattern in _sensitiveDataPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(data)) {
        return true;
      }
    }
    return false;
  }

  String _simpleEncrypt(String data) {
    // Simple encryption using base64 encoding with XOR (NOT for production use)
    final key = 'ukkin_privacy_key';
    final encrypted = <int>[];

    for (int i = 0; i < data.length; i++) {
      encrypted.add(data.codeUnitAt(i) ^ key.codeUnitAt(i % key.length));
    }

    return base64Encode(encrypted);
  }

  String _simpleDecrypt(String encryptedData) {
    // Simple decryption (NOT for production use)
    final key = 'ukkin_privacy_key';
    final encrypted = base64Decode(encryptedData);
    final decrypted = <int>[];

    for (int i = 0; i < encrypted.length; i++) {
      decrypted.add(encrypted[i] ^ key.codeUnitAt(i % key.length));
    }

    return String.fromCharCodes(decrypted);
  }

  String _anonymizeString(String data) {
    String anonymized = data;

    // Replace sensitive patterns with placeholders
    for (final pattern in _sensitiveDataPatterns) {
      anonymized = anonymized.replaceAllMapped(
        RegExp(pattern, caseSensitive: false),
        (match) => '[REDACTED]',
      );
    }

    return anonymized;
  }

  Future<void> _overwriteFile(File file) async {
    final fileSize = await file.length();
    final random = List.generate(fileSize, (index) => 0);

    // Overwrite with zeros, then random data, then zeros again
    await file.writeAsBytes(random);
    await file.writeAsBytes(List.generate(fileSize, (index) => (DateTime.now().millisecondsSinceEpoch + index) % 256));
    await file.writeAsBytes(random);
  }

  void _logDataAccess(String operation, String dataType, int dataSize) {
    if (_privacySettings['audit_data_access']) {
      final logEntry = '${DateTime.now().toIso8601String()}: $operation($dataType, ${dataSize}bytes)';
      _dataAccessLog.add(logEntry);

      // Keep log size manageable
      if (_dataAccessLog.length > 1000) {
        _dataAccessLog.removeRange(0, 100);
      }
    }
  }

  Future<Map<String, dynamic>> _getPermissionUsageStats() async {
    try {
      final result = await _platform.invokeMethod('getPermissionUsageStats');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'error': 'Failed to get permission usage stats: $e'};
    }
  }

  Future<Map<String, dynamic>> _getDataCollectionStats() async {
    return {
      'total_access_events': _dataAccessLog.length,
      'encryption_events': _dataAccessLog.where((log) => log.contains('encrypt')).length,
      'decryption_events': _dataAccessLog.where((log) => log.contains('decrypt')).length,
      'delete_events': _dataAccessLog.where((log) => log.contains('delete')).length,
      'privacy_level': _privacySettings['privacy_level'],
      'incognito_mode': _privacySettings['incognito_mode'],
    };
  }

  Map<String, dynamic> getPrivacySettings() {
    return Map.from(_privacySettings);
  }

  List<String> getDataAccessLog() {
    return List.from(_dataAccessLog);
  }

  Future<ToolExecutionResult> performPrivacyAudit() async {
    try {
      final auditResults = <String, dynamic>{};

      // Check current privacy settings
      auditResults['privacy_settings'] = getPrivacySettings();

      // Audit data access
      auditResults['data_access_summary'] = await _getDataCollectionStats();

      // Check app permissions
      auditResults['permission_audit'] = await _getPermissionUsageStats();

      // Check for potential privacy violations
      final violations = <String>[];
      if (!_privacySettings['encryption_enabled']) {
        violations.add('Encryption is disabled');
      }
      if (!_privacySettings['block_trackers']) {
        violations.add('Tracker blocking is disabled');
      }
      if (!_privacySettings['audit_data_access']) {
        violations.add('Data access auditing is disabled');
      }

      auditResults['privacy_violations'] = violations;
      auditResults['privacy_score'] = _calculatePrivacyScore();

      return ToolExecutionResult.success({
        'action': 'privacy_audit',
        'audit_results': auditResults,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Privacy audit failed: $e');
    }
  }

  double _calculatePrivacyScore() {
    double score = 100.0;

    // Deduct points for disabled privacy features
    if (!_privacySettings['encryption_enabled']) score -= 20;
    if (!_privacySettings['block_trackers']) score -= 15;
    if (!_privacySettings['audit_data_access']) score -= 10;
    if (!_privacySettings['anonymize_logs']) score -= 10;
    if (!_privacySettings['secure_delete_files']) score -= 5;

    // Adjust based on privacy level
    switch (_privacySettings['privacy_level']) {
      case 'minimal':
        score -= 20;
        break;
      case 'standard':
        score -= 0;
        break;
      case 'strict':
        score += 10;
        break;
      case 'paranoid':
        score += 20;
        break;
    }

    return score.clamp(0.0, 100.0);
  }
}