import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_integration_service.dart';

class WorkflowBuilder {
  static WorkflowBuilder? _instance;

  WorkflowBuilder._();

  static WorkflowBuilder get instance {
    _instance ??= WorkflowBuilder._();
    return _instance!;
  }

  final Map<String, WorkflowTemplate> _templates = {};
  final Map<String, AppWorkflow> _savedWorkflows = {};

  Future<void> initialize() async {
    await _createDefaultTemplates();
    await _loadSavedWorkflows();
  }

  Future<void> _createDefaultTemplates() async {
    // Morning routine workflow
    _templates['morning_routine'] = WorkflowTemplate(
      id: 'morning_routine',
      name: 'Morning Routine',
      description: 'Get weather, check calendar, and play morning music',
      category: 'Daily Routines',
      steps: [
        WorkflowStepTemplate(
          id: 'get_weather',
          appId: 'weather',
          action: 'getWeather',
          name: 'Get Weather',
          description: 'Check today\'s weather',
          parameters: {'location': '{user_location}'},
          required: true,
        ),
        WorkflowStepTemplate(
          id: 'check_calendar',
          appId: 'calendar',
          action: 'getEvents',
          name: 'Check Calendar',
          description: 'Get today\'s events',
          parameters: {'date': '{today}'},
          required: true,
        ),
        WorkflowStepTemplate(
          id: 'play_music',
          appId: 'music',
          action: 'play',
          name: 'Play Morning Music',
          description: 'Start morning playlist',
          parameters: {'query': 'morning playlist'},
          required: false,
        ),
      ],
    );

    // Send location workflow
    _templates['send_location'] = WorkflowTemplate(
      id: 'send_location',
      name: 'Send Location',
      description: 'Share your current location via message',
      category: 'Communication',
      steps: [
        WorkflowStepTemplate(
          id: 'get_location',
          appId: 'maps',
          action: 'getCurrentLocation',
          name: 'Get Current Location',
          description: 'Get your current coordinates',
          parameters: {},
          required: true,
        ),
        WorkflowStepTemplate(
          id: 'send_whatsapp',
          appId: 'com.whatsapp',
          action: 'sendMessage',
          name: 'Send via WhatsApp',
          description: 'Share location on WhatsApp',
          parameters: {
            'recipient': '{recipient}',
            'message': 'My location: {get_location.address}',
          },
          required: true,
        ),
      ],
    );

    // Backup photos workflow
    _templates['backup_photos'] = WorkflowTemplate(
      id: 'backup_photos',
      name: 'Backup Photos',
      description: 'Backup recent photos to cloud storage',
      category: 'Productivity',
      steps: [
        WorkflowStepTemplate(
          id: 'get_recent_photos',
          appId: 'photos',
          action: 'getRecentPhotos',
          name: 'Get Recent Photos',
          description: 'Get photos from last 7 days',
          parameters: {'days': 7},
          required: true,
        ),
        WorkflowStepTemplate(
          id: 'upload_to_cloud',
          appId: 'cloud_storage',
          action: 'uploadFiles',
          name: 'Upload to Cloud',
          description: 'Upload photos to cloud storage',
          parameters: {'files': '{get_recent_photos.photos}'},
          required: true,
        ),
        WorkflowStepTemplate(
          id: 'send_confirmation',
          appId: 'email',
          action: 'sendEmail',
          name: 'Send Confirmation',
          description: 'Email backup confirmation',
          parameters: {
            'to': '{user_email}',
            'subject': 'Photos Backup Complete',
            'body': 'Backed up {get_recent_photos.count} photos successfully.',
          },
          required: false,
        ),
      ],
    );

    // Meeting preparation workflow
    _templates['meeting_prep'] = WorkflowTemplate(
      id: 'meeting_prep',
      name: 'Meeting Preparation',
      description: 'Prepare for upcoming meeting',
      category: 'Productivity',
      steps: [
        WorkflowStepTemplate(
          id: 'get_next_meeting',
          appId: 'calendar',
          action: 'getNextEvent',
          name: 'Get Next Meeting',
          description: 'Find next calendar event',
          parameters: {},
          required: true,
        ),
        WorkflowStepTemplate(
          id: 'set_do_not_disturb',
          appId: 'system',
          action: 'setDoNotDisturb',
          name: 'Enable Do Not Disturb',
          description: 'Turn on DND mode',
          parameters: {'duration': 60},
          required: false,
        ),
        WorkflowStepTemplate(
          id: 'open_meeting_notes',
          appId: 'notes',
          action: 'createNote',
          name: 'Create Meeting Notes',
          description: 'Prepare note for meeting',
          parameters: {
            'title': 'Meeting: {get_next_meeting.title}',
            'content': 'Attendees: {get_next_meeting.attendees}\nAgenda:\n\nNotes:\n',
          },
          required: false,
        ),
      ],
    );

    // Evening wind-down workflow
    _templates['evening_routine'] = WorkflowTemplate(
      id: 'evening_routine',
      name: 'Evening Wind-down',
      description: 'End-of-day routine and preparation for tomorrow',
      category: 'Daily Routines',
      steps: [
        WorkflowStepTemplate(
          id: 'check_tomorrow_weather',
          appId: 'weather',
          action: 'getForecast',
          name: 'Tomorrow\'s Weather',
          description: 'Check weather for tomorrow',
          parameters: {'days': 1},
          required: false,
        ),
        WorkflowStepTemplate(
          id: 'check_tomorrow_calendar',
          appId: 'calendar',
          action: 'getEvents',
          name: 'Tomorrow\'s Schedule',
          description: 'Review tomorrow\'s events',
          parameters: {'date': '{tomorrow}'},
          required: false,
        ),
        WorkflowStepTemplate(
          id: 'set_alarm',
          appId: 'clock',
          action: 'setAlarm',
          name: 'Set Alarm',
          description: 'Set alarm for tomorrow',
          parameters: {'time': '{wake_up_time}'},
          required: false,
        ),
        WorkflowStepTemplate(
          id: 'enable_night_mode',
          appId: 'system',
          action: 'enableNightMode',
          name: 'Night Mode',
          description: 'Enable blue light filter',
          parameters: {},
          required: false,
        ),
      ],
    );

    // Travel planning workflow
    _templates['travel_planning'] = WorkflowTemplate(
      id: 'travel_planning',
      name: 'Travel Planning',
      description: 'Plan and organize travel details',
      category: 'Travel',
      steps: [
        WorkflowStepTemplate(
          id: 'get_destination_weather',
          appId: 'weather',
          action: 'getWeather',
          name: 'Destination Weather',
          description: 'Check weather at destination',
          parameters: {'location': '{destination}'},
          required: false,
        ),
        WorkflowStepTemplate(
          id: 'find_restaurants',
          appId: 'maps',
          action: 'findPlaces',
          name: 'Find Restaurants',
          description: 'Find restaurants near destination',
          parameters: {
            'location': '{destination}',
            'type': 'restaurant',
            'radius': 1000,
          },
          required: false,
        ),
        WorkflowStepTemplate(
          id: 'create_travel_note',
          appId: 'notes',
          action: 'createNote',
          name: 'Travel Itinerary',
          description: 'Create travel notes',
          parameters: {
            'title': 'Trip to {destination}',
            'content': 'Weather: {get_destination_weather.summary}\n\nRestaurants:\n{find_restaurants.list}\n\nItinerary:\n',
          },
          required: false,
        ),
      ],
    );
  }

  Future<void> _loadSavedWorkflows() async {
    final prefs = await SharedPreferences.getInstance();
    final savedWorkflows = prefs.getStringList('saved_workflows') ?? [];

    for (final workflowData in savedWorkflows) {
      try {
        final data = jsonDecode(workflowData) as Map<String, dynamic>;
        final workflow = AppWorkflow.fromJson(data);
        _savedWorkflows[workflow.id] = workflow;
      } catch (e) {
        debugPrint('Failed to load workflow: $e');
      }
    }
  }

  Future<void> saveWorkflow(AppWorkflow workflow) async {
    _savedWorkflows[workflow.id] = workflow;

    final prefs = await SharedPreferences.getInstance();
    final savedWorkflows = prefs.getStringList('saved_workflows') ?? [];

    // Remove existing workflow with same ID
    savedWorkflows.removeWhere((data) {
      try {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        return decoded['id'] == workflow.id;
      } catch (e) {
        return false;
      }
    });

    // Add updated workflow
    savedWorkflows.add(jsonEncode(workflow.toJson()));
    await prefs.setStringList('saved_workflows', savedWorkflows);
  }

  Future<void> deleteWorkflow(String workflowId) async {
    _savedWorkflows.remove(workflowId);

    final prefs = await SharedPreferences.getInstance();
    final savedWorkflows = prefs.getStringList('saved_workflows') ?? [];

    savedWorkflows.removeWhere((data) {
      try {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        return decoded['id'] == workflowId;
      } catch (e) {
        return false;
      }
    });

    await prefs.setStringList('saved_workflows', savedWorkflows);
  }

  // Workflow building methods
  WorkflowEditor createWorkflow(String name, {String? description}) {
    final workflow = AppWorkflow(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      steps: [],
    );

    return WorkflowEditor(workflow, this);
  }

  WorkflowEditor editWorkflow(String workflowId) {
    final workflow = _savedWorkflows[workflowId];
    if (workflow == null) {
      throw Exception('Workflow not found: $workflowId');
    }

    return WorkflowEditor(workflow, this);
  }

  WorkflowEditor createFromTemplate(String templateId, Map<String, dynamic> parameters) {
    final template = _templates[templateId];
    if (template == null) {
      throw Exception('Template not found: $templateId');
    }

    final workflow = template.instantiate(parameters);
    return WorkflowEditor(workflow, this);
  }

  // Smart workflow suggestions
  Future<List<WorkflowSuggestion>> getWorkflowSuggestions(String userInput, {String? context}) async {
    final suggestions = <WorkflowSuggestion>[];

    // Analyze user input for workflow opportunities
    final lowerInput = userInput.toLowerCase();

    if (lowerInput.contains('morning') || lowerInput.contains('routine')) {
      suggestions.add(WorkflowSuggestion(
        templateId: 'morning_routine',
        title: 'Morning Routine',
        description: 'Check weather, calendar, and play music',
        relevance: 0.9,
        estimatedTime: Duration(minutes: 2),
      ));
    }

    if (lowerInput.contains('location') || lowerInput.contains('where am i')) {
      suggestions.add(WorkflowSuggestion(
        templateId: 'send_location',
        title: 'Share Location',
        description: 'Send your current location',
        relevance: 0.8,
        estimatedTime: Duration(seconds: 30),
      ));
    }

    if (lowerInput.contains('backup') || lowerInput.contains('photos')) {
      suggestions.add(WorkflowSuggestion(
        templateId: 'backup_photos',
        title: 'Backup Photos',
        description: 'Backup recent photos to cloud',
        relevance: 0.7,
        estimatedTime: Duration(minutes: 5),
      ));
    }

    if (lowerInput.contains('meeting') || lowerInput.contains('presentation')) {
      suggestions.add(WorkflowSuggestion(
        templateId: 'meeting_prep',
        title: 'Meeting Preparation',
        description: 'Prepare for upcoming meeting',
        relevance: 0.8,
        estimatedTime: Duration(minutes: 1),
      ));
    }

    if (lowerInput.contains('evening') || lowerInput.contains('sleep') || lowerInput.contains('bedtime')) {
      suggestions.add(WorkflowSuggestion(
        templateId: 'evening_routine',
        title: 'Evening Wind-down',
        description: 'End-of-day routine',
        relevance: 0.8,
        estimatedTime: Duration(minutes: 3),
      ));
    }

    if (lowerInput.contains('travel') || lowerInput.contains('trip')) {
      suggestions.add(WorkflowSuggestion(
        templateId: 'travel_planning',
        title: 'Travel Planning',
        description: 'Plan your trip details',
        relevance: 0.7,
        estimatedTime: Duration(minutes: 5),
      ));
    }

    // Sort by relevance
    suggestions.sort((a, b) => b.relevance.compareTo(a.relevance));

    return suggestions;
  }

  // Execute workflow
  Future<IntegrationResult> executeWorkflow(String workflowId, {Map<String, dynamic>? parameters}) async {
    final workflow = _savedWorkflows[workflowId];
    if (workflow == null) {
      return IntegrationResult.error('Workflow not found: $workflowId');
    }

    // Substitute parameters
    if (parameters != null) {
      workflow.substituteParameters(parameters);
    }

    return await AppIntegrationService.instance.executeWorkflow(workflow);
  }

  // Getters
  List<WorkflowTemplate> get templates => _templates.values.toList();
  List<AppWorkflow> get savedWorkflows => _savedWorkflows.values.toList();

  WorkflowTemplate? getTemplate(String templateId) => _templates[templateId];
  AppWorkflow? getWorkflow(String workflowId) => _savedWorkflows[workflowId];
}

class WorkflowEditor {
  final AppWorkflow workflow;
  final WorkflowBuilder _builder;

  WorkflowEditor(this.workflow, this._builder);

  WorkflowEditor addStep(String appId, String action, Map<String, dynamic> parameters, {bool required = true}) {
    final step = WorkflowStep(
      id: 'step_${workflow.steps.length + 1}',
      appId: appId,
      action: action,
      parameters: parameters,
      required: required,
    );

    workflow.steps.add(step);
    return this;
  }

  WorkflowEditor removeStep(String stepId) {
    workflow.steps.removeWhere((step) => step.id == stepId);
    return this;
  }

  WorkflowEditor updateStep(String stepId, {String? appId, String? action, Map<String, dynamic>? parameters, bool? required}) {
    final stepIndex = workflow.steps.indexWhere((step) => step.id == stepId);
    if (stepIndex != -1) {
      final step = workflow.steps[stepIndex];
      workflow.steps[stepIndex] = WorkflowStep(
        id: step.id,
        appId: appId ?? step.appId,
        action: action ?? step.action,
        parameters: parameters ?? step.parameters,
        required: required ?? step.required,
      );
    }
    return this;
  }

  WorkflowEditor reorderSteps(List<String> stepIds) {
    final reorderedSteps = <WorkflowStep>[];
    for (final stepId in stepIds) {
      final step = workflow.steps.firstWhere((s) => s.id == stepId);
      reorderedSteps.add(step);
    }
    workflow.steps.clear();
    workflow.steps.addAll(reorderedSteps);
    return this;
  }

  Future<AppWorkflow> save() async {
    await _builder.saveWorkflow(workflow);
    return workflow;
  }

  Future<IntegrationResult> test() async {
    return await AppIntegrationService.instance.executeWorkflow(workflow);
  }
}

class WorkflowTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<WorkflowStepTemplate> steps;

  WorkflowTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.steps,
  });

  AppWorkflow instantiate(Map<String, dynamic> parameters) {
    final workflowSteps = steps.map((stepTemplate) {
      final substitutedParameters = <String, dynamic>{};

      stepTemplate.parameters.forEach((key, value) {
        if (value is String) {
          substitutedParameters[key] = _substituteVariables(value, parameters);
        } else {
          substitutedParameters[key] = value;
        }
      });

      return WorkflowStep(
        id: stepTemplate.id,
        appId: stepTemplate.appId,
        action: stepTemplate.action,
        parameters: substitutedParameters,
        required: stepTemplate.required,
      );
    }).toList();

    return AppWorkflow(
      id: '${id}_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      steps: workflowSteps,
    );
  }

  String _substituteVariables(String text, Map<String, dynamic> parameters) {
    String result = text;

    parameters.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });

    // Handle special variables
    result = result.replaceAll('{today}', DateTime.now().toIso8601String().split('T')[0]);
    result = result.replaceAll('{tomorrow}', DateTime.now().add(Duration(days: 1)).toIso8601String().split('T')[0]);
    result = result.replaceAll('{user_location}', 'current_location'); // Would be actual location
    result = result.replaceAll('{user_email}', 'user@example.com'); // Would be actual email

    return result;
  }
}

class WorkflowStepTemplate {
  final String id;
  final String appId;
  final String action;
  final String name;
  final String description;
  final Map<String, dynamic> parameters;
  final bool required;

  WorkflowStepTemplate({
    required this.id,
    required this.appId,
    required this.action,
    required this.name,
    required this.description,
    required this.parameters,
    required this.required,
  });
}

class WorkflowSuggestion {
  final String templateId;
  final String title;
  final String description;
  final double relevance;
  final Duration estimatedTime;
  final Map<String, dynamic> suggestedParameters;

  WorkflowSuggestion({
    required this.templateId,
    required this.title,
    required this.description,
    required this.relevance,
    required this.estimatedTime,
    this.suggestedParameters = const {},
  });
}

// Extensions for AppWorkflow
extension AppWorkflowExtensions on AppWorkflow {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'steps': steps.map((step) => {
        'id': step.id,
        'appId': step.appId,
        'action': step.action,
        'parameters': step.parameters,
        'required': step.required,
      }).toList(),
    };
  }

  static AppWorkflow fromJson(Map<String, dynamic> json) {
    final steps = (json['steps'] as List).map((stepJson) {
      return WorkflowStep(
        id: stepJson['id'],
        appId: stepJson['appId'],
        action: stepJson['action'],
        parameters: Map<String, dynamic>.from(stepJson['parameters']),
        required: stepJson['required'] ?? true,
      );
    }).toList();

    return AppWorkflow(
      id: json['id'],
      name: json['name'],
      steps: steps,
    );
  }

  void substituteParameters(Map<String, dynamic> parameters) {
    for (final step in steps) {
      step.parameters.forEach((key, value) {
        if (value is String) {
          parameters.forEach((paramKey, paramValue) {
            step.parameters[key] = value.toString().replaceAll('{$paramKey}', paramValue.toString());
          });
        }
      });
    }
  }
}