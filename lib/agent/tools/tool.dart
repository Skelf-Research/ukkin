import '../models/task.dart';

abstract class Tool {
  String get name;
  String get description;
  Map<String, String> get parameters;

  bool canHandle(Task task);
  Future<dynamic> execute(Map<String, dynamic> parameters);
  Future<bool> validate(Map<String, dynamic> parameters);
}

class ToolRegistry {
  final Map<String, Tool> _tools = {};

  void register(Tool tool) {
    _tools[tool.name] = tool;
  }

  void unregister(String toolName) {
    _tools.remove(toolName);
  }

  Tool? getTool(String name) => _tools[name];

  List<Tool> getAllTools() => _tools.values.toList();

  Tool? findToolForTask(Task task) {
    return _tools.values.firstWhere(
      (tool) => tool.canHandle(task),
      orElse: () => throw Exception('No tool found for task type: ${task.type}'),
    );
  }

  List<Tool> getToolsByCategory(String category) {
    return _tools.values
        .where((tool) => tool.name.startsWith(category))
        .toList();
  }
}

class ToolExecutionResult {
  final bool success;
  final dynamic data;
  final String? error;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  ToolExecutionResult({
    required this.success,
    this.data,
    this.error,
    this.metadata = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ToolExecutionResult.success(dynamic data, {Map<String, dynamic>? metadata}) {
    return ToolExecutionResult(
      success: true,
      data: data,
      metadata: metadata ?? {},
    );
  }

  factory ToolExecutionResult.failure(String error, {Map<String, dynamic>? metadata}) {
    return ToolExecutionResult(
      success: false,
      error: error,
      metadata: metadata ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'error': error,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

mixin ToolValidation {
  bool validateRequired(Map<String, dynamic> parameters, List<String> required) {
    for (final param in required) {
      if (!parameters.containsKey(param) || parameters[param] == null) {
        return false;
      }
    }
    return true;
  }

  bool validateUrl(String? url) {
    if (url == null) return false;
    return Uri.tryParse(url) != null;
  }

  bool validateEmail(String? email) {
    if (email == null) return false;
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  bool validatePositiveInteger(dynamic value) {
    if (value is int) return value > 0;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed != null && parsed > 0;
    }
    return false;
  }
}