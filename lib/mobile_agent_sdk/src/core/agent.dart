import 'dart:async';

import '../models/agent_message.dart';

/// Abstract base class for all agents in the Mobile Agent SDK
///
/// An agent is a specialized component that can process messages, handle tasks,
/// and provide specific capabilities within the mobile AI system.
abstract class Agent {
  /// Unique identifier for this agent
  String get id;

  /// Human-readable name for this agent
  String get name;

  /// List of capabilities this agent provides
  List<String> get capabilities;

  /// Current status of the agent
  AgentStatus get status => _status;
  AgentStatus _status = AgentStatus.inactive;

  /// Stream of status changes
  Stream<AgentStatus> get statusStream => _statusController.stream;
  final StreamController<AgentStatus> _statusController =
      StreamController<AgentStatus>.broadcast();

  /// Initialize the agent (called when registered)
  Future<void> initialize() async {
    _updateStatus(AgentStatus.initializing);
    await onInitialize();
    _updateStatus(AgentStatus.active);
  }

  /// Shutdown the agent (called when unregistered)
  Future<void> shutdown() async {
    _updateStatus(AgentStatus.shutting_down);
    await onShutdown();
    _updateStatus(AgentStatus.inactive);
    await _statusController.close();
  }

  /// Process a message and return a response
  Future<AgentMessage> processMessage(AgentMessage message);

  /// Check if this agent can handle a specific task type
  bool canHandleTask(String taskType) {
    return capabilities.contains(taskType);
  }

  /// Check if this agent can handle a specific message
  bool canHandleMessage(AgentMessage message) {
    return true; // Override in subclasses for specific logic
  }

  /// Get agent metadata
  AgentMetadata getMetadata() {
    return AgentMetadata(
      id: id,
      name: name,
      capabilities: capabilities,
      status: status,
      version: getVersion(),
      description: getDescription(),
    );
  }

  /// Get agent version (override in subclasses)
  String getVersion() => '1.0.0';

  /// Get agent description (override in subclasses)
  String getDescription() => 'Mobile Agent SDK Agent';

  /// Called during initialization (override in subclasses)
  Future<void> onInitialize() async {}

  /// Called during shutdown (override in subclasses)
  Future<void> onShutdown() async {}

  /// Update agent status and notify listeners
  void _updateStatus(AgentStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(newStatus);
    }
  }
}

/// Agent status enumeration
enum AgentStatus {
  inactive,
  initializing,
  active,
  busy,
  error,
  shutting_down,
}

/// Agent metadata container
class AgentMetadata {
  final String id;
  final String name;
  final List<String> capabilities;
  final AgentStatus status;
  final String version;
  final String description;

  const AgentMetadata({
    required this.id,
    required this.name,
    required this.capabilities,
    required this.status,
    required this.version,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'capabilities': capabilities,
      'status': status.name,
      'version': version,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'AgentMetadata(id: $id, name: $name, status: $status)';
  }
}

/// Specialized agent for handling conversational interactions
abstract class ConversationalAgent extends Agent {
  /// Process a conversation turn
  Future<AgentMessage> processConversation(
    AgentMessage message,
    List<AgentMessage> conversationHistory,
  ) async {
    return processMessage(message);
  }

  /// Get conversation capabilities
  ConversationCapabilities getConversationCapabilities() {
    return ConversationCapabilities(
      supportsContext: true,
      supportsMultiTurn: true,
      maxContextLength: 4000,
      supportedLanguages: ['en'],
    );
  }
}

/// Specialized agent for handling tasks and workflows
abstract class TaskAgent extends Agent {
  /// Execute a specific task
  Future<TaskResult> executeTask(TaskRequest request);

  /// Get task execution capabilities
  TaskCapabilities getTaskCapabilities() {
    return TaskCapabilities(
      maxConcurrentTasks: 1,
      supportsLongRunningTasks: false,
      supportsTaskCancellation: true,
      estimatedExecutionTime: Duration(seconds: 30),
    );
  }

  /// Cancel a running task
  Future<void> cancelTask(String taskId) async {
    // Override in subclasses
    throw UnimplementedError('Task cancellation not implemented');
  }
}

/// Specialized agent for handling integrations with external services
abstract class IntegrationAgent extends Agent {
  /// Execute an integration action
  Future<IntegrationResult> executeAction(
    String action,
    Map<String, dynamic> parameters,
  );

  /// Get supported integrations
  List<String> getSupportedIntegrations();

  /// Check if an integration is available
  Future<bool> isIntegrationAvailable(String integrationId);
}

/// Conversation capabilities
class ConversationCapabilities {
  final bool supportsContext;
  final bool supportsMultiTurn;
  final int maxContextLength;
  final List<String> supportedLanguages;

  const ConversationCapabilities({
    required this.supportsContext,
    required this.supportsMultiTurn,
    required this.maxContextLength,
    required this.supportedLanguages,
  });
}

/// Task execution capabilities
class TaskCapabilities {
  final int maxConcurrentTasks;
  final bool supportsLongRunningTasks;
  final bool supportsTaskCancellation;
  final Duration estimatedExecutionTime;

  const TaskCapabilities({
    required this.maxConcurrentTasks,
    required this.supportsLongRunningTasks,
    required this.supportsTaskCancellation,
    required this.estimatedExecutionTime,
  });
}

/// Task request
class TaskRequest {
  final String id;
  final String taskType;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  const TaskRequest({
    required this.id,
    required this.taskType,
    required this.parameters,
    required this.timestamp,
  });

  factory TaskRequest.create(String taskType, Map<String, dynamic> parameters) {
    return TaskRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskType: taskType,
      parameters: parameters,
      timestamp: DateTime.now(),
    );
  }
}

/// Task execution result
class TaskResult {
  final String taskId;
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;
  final DateTime completedAt;

  const TaskResult({
    required this.taskId,
    required this.success,
    this.data,
    this.error,
    required this.completedAt,
  });

  factory TaskResult.success(String taskId, Map<String, dynamic> data) {
    return TaskResult(
      taskId: taskId,
      success: true,
      data: data,
      completedAt: DateTime.now(),
    );
  }

  factory TaskResult.failure(String taskId, String error) {
    return TaskResult(
      taskId: taskId,
      success: false,
      error: error,
      completedAt: DateTime.now(),
    );
  }
}

/// Integration execution result
class IntegrationResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;

  const IntegrationResult({
    required this.success,
    this.data,
    this.error,
  });

  factory IntegrationResult.success(Map<String, dynamic> data) {
    return IntegrationResult(success: true, data: data);
  }

  factory IntegrationResult.failure(String error) {
    return IntegrationResult(success: false, error: error);
  }
}