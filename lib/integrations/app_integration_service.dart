import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppIntegrationService {
  static const MethodChannel _channel = MethodChannel('app_integration');
  static AppIntegrationService? _instance;

  AppIntegrationService._();

  static AppIntegrationService get instance {
    _instance ??= AppIntegrationService._();
    return _instance!;
  }

  final Map<String, AppIntegration> _registeredIntegrations = {};
  final Map<String, AppConnection> _activeConnections = {};

  Future<void> initialize() async {
    await _setupDefaultIntegrations();
    await _loadSavedIntegrations();
    await _discoverAvailableApps();
  }

  Future<void> _setupDefaultIntegrations() async {
    // Popular app integrations
    _registerIntegration(WhatsAppIntegration());
    _registerIntegration(TelegramIntegration());
    _registerIntegration(EmailIntegration());
    _registerIntegration(CalendarIntegration());
    _registerIntegration(ContactsIntegration());
    _registerIntegration(MapsIntegration());
    _registerIntegration(MusicIntegration());
    _registerIntegration(CameraIntegration());
    _registerIntegration(FilesIntegration());
    _registerIntegration(BrowserIntegration());
    _registerIntegration(NotesIntegration());
    _registerIntegration(WeatherIntegration());
    _registerIntegration(PhotosIntegration());
    _registerIntegration(SocialMediaIntegration());
    _registerIntegration(ShoppingIntegration());
  }

  void _registerIntegration(AppIntegration integration) {
    _registeredIntegrations[integration.appId] = integration;
  }

  Future<void> _loadSavedIntegrations() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIntegrations = prefs.getStringList('app_integrations') ?? [];

    for (final integrationData in savedIntegrations) {
      try {
        final data = jsonDecode(integrationData) as Map<String, dynamic>;
        await _activateIntegration(data['appId'] as String, data['config'] as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Failed to load integration: $e');
      }
    }
  }

  Future<void> _discoverAvailableApps() async {
    try {
      final installedApps = await _channel.invokeListMethod<String>('getInstalledApps') ?? [];

      for (final appId in installedApps) {
        if (_registeredIntegrations.containsKey(appId)) {
          final integration = _registeredIntegrations[appId]!;
          integration.isInstalled = true;

          // Check if app supports our integration
          final isSupported = await _checkIntegrationSupport(appId);
          integration.isSupported = isSupported;
        }
      }
    } catch (e) {
      debugPrint('App discovery failed: $e');
    }
  }

  Future<bool> _checkIntegrationSupport(String appId) async {
    try {
      final result = await _channel.invokeMethod('checkIntegrationSupport', {'appId': appId});
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('Integration support check failed for $appId: $e');
      return false;
    }
  }

  // Public API for app integration
  Future<bool> activateIntegration(String appId, {Map<String, dynamic>? config}) async {
    if (!_registeredIntegrations.containsKey(appId)) {
      debugPrint('Integration not found: $appId');
      return false;
    }

    final integration = _registeredIntegrations[appId]!;
    if (!integration.isInstalled) {
      debugPrint('App not installed: $appId');
      return false;
    }

    return await _activateIntegration(appId, config ?? {});
  }

  Future<bool> _activateIntegration(String appId, Map<String, dynamic> config) async {
    try {
      final integration = _registeredIntegrations[appId]!;
      await integration.configure(config);

      final connection = await integration.connect();
      if (connection != null) {
        _activeConnections[appId] = connection;
        await _saveIntegrationConfig(appId, config);
        debugPrint('Integration activated: $appId');
        return true;
      }
    } catch (e) {
      debugPrint('Integration activation failed for $appId: $e');
    }
    return false;
  }

  Future<void> deactivateIntegration(String appId) async {
    if (_activeConnections.containsKey(appId)) {
      await _activeConnections[appId]!.disconnect();
      _activeConnections.remove(appId);
      await _removeIntegrationConfig(appId);
      debugPrint('Integration deactivated: $appId');
    }
  }

  Future<void> _saveIntegrationConfig(String appId, Map<String, dynamic> config) async {
    final prefs = await SharedPreferences.getInstance();
    final savedIntegrations = prefs.getStringList('app_integrations') ?? [];

    final integrationData = jsonEncode({
      'appId': appId,
      'config': config,
      'activatedAt': DateTime.now().toIso8601String(),
    });

    savedIntegrations.removeWhere((data) {
      try {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        return decoded['appId'] == appId;
      } catch (e) {
        return false;
      }
    });

    savedIntegrations.add(integrationData);
    await prefs.setStringList('app_integrations', savedIntegrations);
  }

  Future<void> _removeIntegrationConfig(String appId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedIntegrations = prefs.getStringList('app_integrations') ?? [];

    savedIntegrations.removeWhere((data) {
      try {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        return decoded['appId'] == appId;
      } catch (e) {
        return false;
      }
    });

    await prefs.setStringList('app_integrations', savedIntegrations);
  }

  // Integration actions
  Future<IntegrationResult> executeAction(String appId, String action, Map<String, dynamic> parameters) async {
    if (!_activeConnections.containsKey(appId)) {
      return IntegrationResult.error('Integration not active: $appId');
    }

    try {
      final connection = _activeConnections[appId]!;
      return await connection.executeAction(action, parameters);
    } catch (e) {
      debugPrint('Action execution failed for $appId.$action: $e');
      return IntegrationResult.error('Action execution failed: $e');
    }
  }

  // Specific integration methods
  Future<IntegrationResult> sendMessage(String appId, String recipient, String message, {String? messageType}) async {
    return await executeAction(appId, 'sendMessage', {
      'recipient': recipient,
      'message': message,
      'messageType': messageType ?? 'text',
    });
  }

  Future<IntegrationResult> makeCall(String phoneNumber) async {
    return await executeAction('phone', 'makeCall', {
      'phoneNumber': phoneNumber,
    });
  }

  Future<IntegrationResult> sendEmail(String to, String subject, String body, {List<String>? attachments}) async {
    return await executeAction('email', 'sendEmail', {
      'to': to,
      'subject': subject,
      'body': body,
      'attachments': attachments ?? [],
    });
  }

  Future<IntegrationResult> createCalendarEvent(String title, DateTime startTime, DateTime endTime, {String? description, String? location}) async {
    return await executeAction('calendar', 'createEvent', {
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'description': description,
      'location': location,
    });
  }

  Future<IntegrationResult> addContact(String name, String phoneNumber, {String? email}) async {
    return await executeAction('contacts', 'addContact', {
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
    });
  }

  Future<IntegrationResult> navigateTo(String destination, {String? travelMode}) async {
    return await executeAction('maps', 'navigate', {
      'destination': destination,
      'travelMode': travelMode ?? 'driving',
    });
  }

  Future<IntegrationResult> playMusic(String query, {String? service}) async {
    return await executeAction('music', 'play', {
      'query': query,
      'service': service,
    });
  }

  Future<IntegrationResult> takePicture({String? mode}) async {
    return await executeAction('camera', 'takePicture', {
      'mode': mode ?? 'photo',
    });
  }

  Future<IntegrationResult> openUrl(String url, {String? browserApp}) async {
    return await executeAction('browser', 'openUrl', {
      'url': url,
      'browserApp': browserApp,
    });
  }

  Future<IntegrationResult> createNote(String title, String content, {String? category}) async {
    return await executeAction('notes', 'createNote', {
      'title': title,
      'content': content,
      'category': category,
    });
  }

  Future<IntegrationResult> getWeather(String location) async {
    return await executeAction('weather', 'getWeather', {
      'location': location,
    });
  }

  Future<IntegrationResult> shareContent(String content, {String? appId, String? contentType}) async {
    return await executeAction('share', 'shareContent', {
      'content': content,
      'appId': appId,
      'contentType': contentType ?? 'text',
    });
  }

  // Cross-app workflows
  Future<IntegrationResult> executeWorkflow(AppWorkflow workflow) async {
    final results = <String, IntegrationResult>{};

    for (final step in workflow.steps) {
      try {
        final result = await executeAction(step.appId, step.action, step.parameters);
        results[step.id] = result;

        if (!result.success) {
          debugPrint('Workflow step failed: ${step.id}');
          if (step.required) {
            return IntegrationResult.error('Required workflow step failed: ${step.id}');
          }
        }

        // Use result data in subsequent steps
        if (result.success && result.data != null) {
          workflow.setStepResult(step.id, result.data!);
        }
      } catch (e) {
        debugPrint('Workflow step error: ${step.id}: $e');
        if (step.required) {
          return IntegrationResult.error('Workflow step error: ${step.id}');
        }
      }
    }

    return IntegrationResult.success(results);
  }

  // Smart integration suggestions
  Future<List<AppSuggestion>> getSmartSuggestions(String userInput, {String? context}) async {
    final suggestions = <AppSuggestion>[];

    for (final integration in _activeConnections.values) {
      try {
        final appSuggestions = await integration.getSuggestions(userInput, context);
        suggestions.addAll(appSuggestions);
      } catch (e) {
        debugPrint('Suggestion generation failed for ${integration.appId}: $e');
      }
    }

    // Sort by relevance
    suggestions.sort((a, b) => b.relevance.compareTo(a.relevance));

    return suggestions.take(10).toList();
  }

  // Getters
  List<AppIntegration> get availableIntegrations => _registeredIntegrations.values.toList();
  List<AppIntegration> get installedIntegrations => _registeredIntegrations.values.where((i) => i.isInstalled).toList();
  List<AppIntegration> get activeIntegrations => _registeredIntegrations.values.where((i) => _activeConnections.containsKey(i.appId)).toList();

  bool isIntegrationActive(String appId) => _activeConnections.containsKey(appId);

  void dispose() {
    for (final connection in _activeConnections.values) {
      connection.disconnect();
    }
    _activeConnections.clear();
  }
}

// Base classes and interfaces
abstract class AppIntegration {
  String get appId;
  String get displayName;
  String get description;
  List<String> get supportedActions;
  bool isInstalled = false;
  bool isSupported = false;

  Future<void> configure(Map<String, dynamic> config) async {}
  Future<AppConnection?> connect();
}

abstract class AppConnection {
  String get appId;
  Future<IntegrationResult> executeAction(String action, Map<String, dynamic> parameters);
  Future<List<AppSuggestion>> getSuggestions(String userInput, String? context);
  Future<void> disconnect();
}

class IntegrationResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
  final String? error;

  IntegrationResult.success(this.data, {this.message}) : success = true, error = null;
  IntegrationResult.error(this.error, {this.message}) : success = false, data = null;
}

class AppWorkflow {
  final String id;
  final String name;
  final List<WorkflowStep> steps;
  final Map<String, dynamic> _stepResults = {};

  AppWorkflow({
    required this.id,
    required this.name,
    required this.steps,
  });

  void setStepResult(String stepId, Map<String, dynamic> result) {
    _stepResults[stepId] = result;
  }

  Map<String, dynamic>? getStepResult(String stepId) {
    return _stepResults[stepId];
  }
}

class WorkflowStep {
  final String id;
  final String appId;
  final String action;
  final Map<String, dynamic> parameters;
  final bool required;

  WorkflowStep({
    required this.id,
    required this.appId,
    required this.action,
    required this.parameters,
    this.required = true,
  });
}

class AppSuggestion {
  final String appId;
  final String title;
  final String description;
  final String action;
  final Map<String, dynamic> parameters;
  final double relevance;
  final String? icon;

  AppSuggestion({
    required this.appId,
    required this.title,
    required this.description,
    required this.action,
    required this.parameters,
    required this.relevance,
    this.icon,
  });
}

// Specific app integrations (examples)
class WhatsAppIntegration extends AppIntegration {
  @override
  String get appId => 'com.whatsapp';

  @override
  String get displayName => 'WhatsApp';

  @override
  String get description => 'Send messages via WhatsApp';

  @override
  List<String> get supportedActions => ['sendMessage', 'sendImage', 'sendDocument'];

  @override
  Future<AppConnection?> connect() async {
    return WhatsAppConnection();
  }
}

class WhatsAppConnection extends AppConnection {
  @override
  String get appId => 'com.whatsapp';

  @override
  Future<IntegrationResult> executeAction(String action, Map<String, dynamic> parameters) async {
    switch (action) {
      case 'sendMessage':
        return await _sendMessage(parameters['recipient'], parameters['message']);
      default:
        return IntegrationResult.error('Unsupported action: $action');
    }
  }

  Future<IntegrationResult> _sendMessage(String recipient, String message) async {
    try {
      const channel = MethodChannel('app_integration');
      await channel.invokeMethod('whatsapp_sendMessage', {
        'recipient': recipient,
        'message': message,
      });
      return IntegrationResult.success({}, message: 'Message sent to $recipient');
    } catch (e) {
      return IntegrationResult.error(e.toString());
    }
  }

  @override
  Future<List<AppSuggestion>> getSuggestions(String userInput, String? context) async {
    if (userInput.toLowerCase().contains('whatsapp') || userInput.toLowerCase().contains('message')) {
      return [
        AppSuggestion(
          appId: appId,
          title: 'Send WhatsApp Message',
          description: 'Send a message via WhatsApp',
          action: 'sendMessage',
          parameters: {'message': userInput},
          relevance: 0.8,
        ),
      ];
    }
    return [];
  }

  @override
  Future<void> disconnect() async {}
}

// Additional integration implementations would follow similar patterns...
class TelegramIntegration extends AppIntegration {
  @override
  String get appId => 'org.telegram.messenger';
  @override
  String get displayName => 'Telegram';
  @override
  String get description => 'Send messages via Telegram';
  @override
  List<String> get supportedActions => ['sendMessage', 'sendFile'];
  @override
  Future<AppConnection?> connect() async => TelegramConnection();
}

class TelegramConnection extends AppConnection {
  @override
  String get appId => 'org.telegram.messenger';
  @override
  Future<IntegrationResult> executeAction(String action, Map<String, dynamic> parameters) async {
    // Implementation similar to WhatsApp
    return IntegrationResult.success({});
  }
  @override
  Future<List<AppSuggestion>> getSuggestions(String userInput, String? context) async => [];
  @override
  Future<void> disconnect() async {}
}

class EmailIntegration extends AppIntegration {
  @override
  String get appId => 'email';
  @override
  String get displayName => 'Email';
  @override
  String get description => 'Send emails';
  @override
  List<String> get supportedActions => ['sendEmail', 'createDraft'];
  @override
  Future<AppConnection?> connect() async => EmailConnection();
}

class EmailConnection extends AppConnection {
  @override
  String get appId => 'email';
  @override
  Future<IntegrationResult> executeAction(String action, Map<String, dynamic> parameters) async {
    // Email implementation
    return IntegrationResult.success({});
  }
  @override
  Future<List<AppSuggestion>> getSuggestions(String userInput, String? context) async => [];
  @override
  Future<void> disconnect() async {}
}

class CalendarIntegration extends AppIntegration {
  @override
  String get appId => 'calendar';
  @override
  String get displayName => 'Calendar';
  @override
  String get description => 'Manage calendar events';
  @override
  List<String> get supportedActions => ['createEvent', 'getEvents'];
  @override
  Future<AppConnection?> connect() async => CalendarConnection();
}

class CalendarConnection extends AppConnection {
  @override
  String get appId => 'calendar';
  @override
  Future<IntegrationResult> executeAction(String action, Map<String, dynamic> parameters) async {
    // Calendar implementation
    return IntegrationResult.success({});
  }
  @override
  Future<List<AppSuggestion>> getSuggestions(String userInput, String? context) async => [];
  @override
  Future<void> disconnect() async {}
}

class ContactsIntegration extends AppIntegration {
  @override
  String get appId => 'contacts';
  @override
  String get displayName => 'Contacts';
  @override
  String get description => 'Manage contacts';
  @override
  List<String> get supportedActions => ['addContact', 'findContact'];
  @override
  Future<AppConnection?> connect() async => ContactsConnection();
}

class ContactsConnection extends AppConnection {
  @override
  String get appId => 'contacts';
  @override
  Future<IntegrationResult> executeAction(String action, Map<String, dynamic> parameters) async {
    return IntegrationResult.success({});
  }
  @override
  Future<List<AppSuggestion>> getSuggestions(String userInput, String? context) async => [];
  @override
  Future<void> disconnect() async {}
}

class MapsIntegration extends AppIntegration {
  @override
  String get appId => 'maps';
  @override
  String get displayName => 'Maps';
  @override
  String get description => 'Navigation and maps';
  @override
  List<String> get supportedActions => ['navigate', 'findPlace'];
  @override
  Future<AppConnection?> connect() async => MapsConnection();
}

class MapsConnection extends AppConnection {
  @override
  String get appId => 'maps';
  @override
  Future<IntegrationResult> executeAction(String action, Map<String, dynamic> parameters) async {
    return IntegrationResult.success({});
  }
  @override
  Future<List<AppSuggestion>> getSuggestions(String userInput, String? context) async => [];
  @override
  Future<void> disconnect() async {}
}

class MusicIntegration extends AppIntegration {
  @override
  String get appId => 'music';
  @override
  String get displayName => 'Music';
  @override
  String get description => 'Play music';
  @override
  List<String> get supportedActions => ['play', 'pause', 'skip'];
  @override
  Future<AppConnection?> connect() async => MusicConnection();
}

class MusicConnection extends AppConnection {
  @override
  String get appId => 'music';
  @override
  Future<IntegrationResult> executeAction(String action, Map<String, dynamic> parameters) async {
    return IntegrationResult.success({});
  }
  @override
  Future<List<AppSuggestion>> getSuggestions(String userInput, String? context) async => [];
  @override
  Future<void> disconnect() async {}
}

class CameraIntegration extends AppIntegration {
  @override
  String get appId => 'camera';
  @override
  String get displayName => 'Camera';
  @override
  String get description => 'Take photos and videos';
  @override
  List<String> get supportedActions => ['takePicture', 'recordVideo'];
  @override
  Future<AppConnection?> connect() async => CameraConnection();
}

class CameraConnection extends AppConnection {
  @override
  String get appId => 'camera';
  @override
  Future<IntegrationResult> executeAction(String action, Map<String, dynamic> parameters) async {
    return IntegrationResult.success({});
  }
  @override
  Future<List<AppSuggestion>> getSuggestions(String userInput, String? context) async => [];
  @override
  Future<void> disconnect() async {}
}

class FilesIntegration extends AppIntegration {
  @override
  String get appId => 'files';
  @override
  String get displayName => 'Files';
  @override
  String get description => 'File management';
  @override
  List<String> get supportedActions => ['openFile', 'shareFile'];
  @override
  Future<AppConnection?> connect() async => FilesConnection();
}

class FilesConnection extends AppConnection {
  @override
  String get appId => 'files';
  @override
  Future<IntegrationResult> executeAction(String action, Map<String, dynamic> parameters) async {
    return IntegrationResult.success({});
  }
  @override
  Future<List<AppSuggestion>> getSuggestions(String userInput, String? context) async => [];
  @override
  Future<void> disconnect() async {}
}

class BrowserIntegration extends AppIntegration {
  @override
  String get appId => 'browser';
  @override
  String get displayName => 'Browser';
  @override
  String get description => 'Web browsing';
  @override
  List<String> get supportedActions => ['openUrl', 'search'];
  @override
  Future<AppConnection?> connect() async => BrowserConnection();
}

class BrowserConnection extends AppConnection {
  @override
  String get appId => 'browser';
  @override
  Future<IntegrationResult> executeAction(String action, Map<String, dynamic> parameters) async {
    return IntegrationResult.success({});
  }
  @override
  Future<List<AppSuggestion>> getSuggestions(String userInput, String? context) async => [];
  @override
  Future<void> disconnect() async {}
}

class NotesIntegration extends AppIntegration {
  @override
  String get appId => 'notes';
  @override
  String get displayName => 'Notes';
  @override
  String get description => 'Create and manage notes';
  @override
  List<String> get supportedActions => ['createNote', 'searchNotes'];
  @override
  Future<AppConnection?> connect() async => NotesConnection();
}

class NotesConnection extends AppConnection {
  @override
  String get appId => 'notes';
  @override
  Future<IntegrationResult> executeAction(String action, Map<String, dynamic> parameters) async {
    return IntegrationResult.success({});
  }
  @override
  Future<List<AppSuggestion>> getSuggestions(String userInput, String? context) async => [];
  @override
  Future<void> disconnect() async {}
}

class WeatherIntegration extends AppIntegration {
  @override
  String get appId => 'weather';
  @override
  String get displayName => 'Weather';
  @override
  String get description => 'Weather information';
  @override
  List<String> get supportedActions => ['getWeather', 'getForecast'];
  @override
  Future<AppConnection?> connect() async => WeatherConnection();
}

class WeatherConnection extends AppConnection {
  @override
  String get appId => 'weather';
  @override
  Future<IntegrationResult> executeAction(String action, Map<String, dynamic> parameters) async {
    return IntegrationResult.success({});
  }
  @override
  Future<List<AppSuggestion>> getSuggestions(String userInput, String? context) async => [];
  @override
  Future<void> disconnect() async {}
}

class PhotosIntegration extends AppIntegration {
  @override
  String get appId => 'photos';
  @override
  String get displayName => 'Photos';
  @override
  String get description => 'Photo gallery management';
  @override
  List<String> get supportedActions => ['viewPhotos', 'sharePhoto'];
  @override
  Future<AppConnection?> connect() async => PhotosConnection();
}

class PhotosConnection extends AppConnection {
  @override
  String get appId => 'photos';
  @override
  Future<IntegrationResult> executeAction(String action, Map<String, dynamic> parameters) async {
    return IntegrationResult.success({});
  }
  @override
  Future<List<AppSuggestion>> getSuggestions(String userInput, String? context) async => [];
  @override
  Future<void> disconnect() async {}
}

class SocialMediaIntegration extends AppIntegration {
  @override
  String get appId => 'social_media';
  @override
  String get displayName => 'Social Media';
  @override
  String get description => 'Social media posting';
  @override
  List<String> get supportedActions => ['post', 'share'];
  @override
  Future<AppConnection?> connect() async => SocialMediaConnection();
}

class SocialMediaConnection extends AppConnection {
  @override
  String get appId => 'social_media';
  @override
  Future<IntegrationResult> executeAction(String action, Map<String, dynamic> parameters) async {
    return IntegrationResult.success({});
  }
  @override
  Future<List<AppSuggestion>> getSuggestions(String userInput, String? context) async => [];
  @override
  Future<void> disconnect() async {}
}

class ShoppingIntegration extends AppIntegration {
  @override
  String get appId => 'shopping';
  @override
  String get displayName => 'Shopping';
  @override
  String get description => 'Shopping and e-commerce';
  @override
  List<String> get supportedActions => ['search', 'addToCart'];
  @override
  Future<AppConnection?> connect() async => ShoppingConnection();
}

class ShoppingConnection extends AppConnection {
  @override
  String get appId => 'shopping';
  @override
  Future<IntegrationResult> executeAction(String action, Map<String, dynamic> parameters) async {
    return IntegrationResult.success({});
  }
  @override
  Future<List<AppSuggestion>> getSuggestions(String userInput, String? context) async => [];
  @override
  Future<void> disconnect() async {}
}