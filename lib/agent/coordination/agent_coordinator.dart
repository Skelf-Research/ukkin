import 'dart:async';
import '../core/agent.dart';
import '../models/task.dart';
import '../models/agent_message.dart';
import '../planning/task_planner.dart';

// Helper function for fire-and-forget async calls
void unawaited(Future<void> future) {
  // Intentionally not awaiting the future
}

class AgentCoordinator {
  final Map<String, Agent> _agents = {};
  final TaskGraph _globalTaskGraph = TaskGraph();
  final StreamController<CoordinationEvent> _eventController =
      StreamController<CoordinationEvent>.broadcast();

  final Map<String, StreamSubscription> _agentSubscriptions = {};

  Stream<CoordinationEvent> get events => _eventController.stream;

  void registerAgent(Agent agent) {
    _agents[agent.id] = agent;

    // Subscribe to agent messages and task results
    _agentSubscriptions[agent.id] = agent.messageStream.listen((message) {
      _handleAgentMessage(agent.id, message);
    });

    _agentSubscriptions['${agent.id}_tasks'] = agent.taskResultStream.listen((result) {
      _handleTaskResult(agent.id, result);
    });

    _eventController.add(CoordinationEvent(
      type: CoordinationEventType.agentRegistered,
      agentId: agent.id,
      timestamp: DateTime.now(),
      data: {'agent_name': agent.name},
    ));
  }

  void unregisterAgent(String agentId) {
    _agentSubscriptions[agentId]?.cancel();
    _agentSubscriptions['${agentId}_tasks']?.cancel();
    _agentSubscriptions.remove(agentId);
    _agentSubscriptions.remove('${agentId}_tasks');

    _agents.remove(agentId);

    _eventController.add(CoordinationEvent(
      type: CoordinationEventType.agentUnregistered,
      agentId: agentId,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> executeCollaborativeTask(String objective) async {
    _eventController.add(CoordinationEvent(
      type: CoordinationEventType.collaborationStarted,
      timestamp: DateTime.now(),
      data: {'objective': objective},
    ));

    try {
      // Plan the high-level task breakdown
      final masterPlan = await _createMasterPlan(objective);

      // Assign tasks to appropriate agents
      await _assignTasks(masterPlan);

      // Monitor and coordinate execution
      await _coordinateExecution();

    } catch (e) {
      _eventController.add(CoordinationEvent(
        type: CoordinationEventType.collaborationFailed,
        timestamp: DateTime.now(),
        data: {'error': e.toString()},
      ));
    }
  }

  Future<List<Task>> _createMasterPlan(String objective) async {
    // Use the most capable agent for planning
    final plannerAgent = _selectBestAgentForPlanning();
    if (plannerAgent == null) {
      throw Exception('No suitable agent found for planning');
    }

    final tasks = await plannerAgent.planTasks(objective);

    // Add tasks to global graph
    for (final task in tasks) {
      _globalTaskGraph.addTask(task);
    }

    return tasks;
  }

  Future<void> _assignTasks(List<Task> tasks) async {
    for (final task in tasks) {
      final bestAgent = _selectBestAgentForTask(task);
      if (bestAgent != null) {
        task.assignedAgentId = bestAgent.id;
        _globalTaskGraph.updateTaskStatus(task.id, TaskStatus.pending);

        _eventController.add(CoordinationEvent(
          type: CoordinationEventType.taskAssigned,
          agentId: bestAgent.id,
          taskId: task.id,
          timestamp: DateTime.now(),
          data: {'task_type': task.type, 'task_description': task.description},
        ));
      }
    }
  }

  Future<void> _coordinateExecution() async {
    while (_globalTaskGraph.getTasksByStatus(TaskStatus.pending).isNotEmpty ||
           _globalTaskGraph.getTasksByStatus(TaskStatus.running).isNotEmpty) {

      final executableTasks = _globalTaskGraph.getExecutableTasks();

      for (final task in executableTasks) {
        if (task.assignedAgentId != null) {
          final agent = _agents[task.assignedAgentId];
          if (agent != null) {
            _globalTaskGraph.updateTaskStatus(task.id, TaskStatus.running);

            // Execute task asynchronously
            unawaited(agent.executeTask(task));
          }
        }
      }

      // Wait a bit before checking again
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  Agent? _selectBestAgentForPlanning() {
    // Simple selection - pick first available agent
    // TODO: Implement more sophisticated selection based on agent capabilities
    return _agents.values.isNotEmpty ? _agents.values.first : null;
  }

  Agent? _selectBestAgentForTask(Task task) {
    // Find agent with tools that can handle this task
    for (final agent in _agents.values) {
      if (agent.tools.any((tool) => tool.canHandle(task))) {
        return agent;
      }
    }
    return null;
  }

  void _handleAgentMessage(String agentId, AgentMessage message) {
    _eventController.add(CoordinationEvent(
      type: CoordinationEventType.messageReceived,
      agentId: agentId,
      timestamp: DateTime.now(),
      data: {
        'message_type': message.type.name,
        'content': message.content,
        'message_id': message.id,
      },
    ));

    // Check if message requires coordination response
    if (message.type == MessageType.error) {
      _handleAgentError(agentId, message);
    }
  }

  void _handleTaskResult(String agentId, TaskResult result) {
    _globalTaskGraph.updateTaskStatus(
      result.taskId,
      result.status,
    );

    _eventController.add(CoordinationEvent(
      type: CoordinationEventType.taskCompleted,
      agentId: agentId,
      taskId: result.taskId,
      timestamp: DateTime.now(),
      data: {
        'status': result.status.name,
        'success': result.status == TaskStatus.completed,
        'error': result.error,
      },
    ));

    if (result.status == TaskStatus.failed) {
      _handleTaskFailure(agentId, result);
    }
  }

  void _handleAgentError(String agentId, AgentMessage errorMessage) {
    _eventController.add(CoordinationEvent(
      type: CoordinationEventType.agentError,
      agentId: agentId,
      timestamp: DateTime.now(),
      data: {
        'error_message': errorMessage.content,
        'message_id': errorMessage.id,
      },
    ));

    // TODO: Implement error recovery strategies
  }

  void _handleTaskFailure(String agentId, TaskResult failedResult) {
    _eventController.add(CoordinationEvent(
      type: CoordinationEventType.taskFailed,
      agentId: agentId,
      taskId: failedResult.taskId,
      timestamp: DateTime.now(),
      data: {
        'error': failedResult.error,
        'result': failedResult.result,
      },
    ));

    // Try to reassign task to different agent or break it down
    _reassignOrBreakdownTask(failedResult.taskId);
  }

  Future<void> _reassignOrBreakdownTask(String taskId) async {
    final task = _globalTaskGraph.getTask(taskId);
    if (task == null) return;

    // Try to find another agent
    final alternativeAgent = _selectBestAgentForTask(task);
    if (alternativeAgent != null && alternativeAgent.id != task.assignedAgentId) {
      task.assignedAgentId = alternativeAgent.id;
      _globalTaskGraph.updateTaskStatus(taskId, TaskStatus.pending);

      _eventController.add(CoordinationEvent(
        type: CoordinationEventType.taskReassigned,
        agentId: alternativeAgent.id,
        taskId: taskId,
        timestamp: DateTime.now(),
      ));
    } else {
      // Try to break down the task
      await _breakdownFailedTask(task);
    }
  }

  Future<void> _breakdownFailedTask(Task task) async {
    final plannerAgent = _selectBestAgentForPlanning();
    if (plannerAgent == null) return;

    // TODO: Implement task breakdown
    _eventController.add(CoordinationEvent(
      type: CoordinationEventType.taskBreakdownAttempted,
      taskId: task.id,
      timestamp: DateTime.now(),
      data: {'original_task': task.description},
    ));
  }

  Future<void> broadcastMessage(AgentMessage message) async {
    for (final agent in _agents.values) {
      if (agent.id != message.agentId) {
        await agent.processMessage(message);
      }
    }

    _eventController.add(CoordinationEvent(
      type: CoordinationEventType.messageBroadcast,
      agentId: message.agentId,
      timestamp: DateTime.now(),
      data: {
        'message_type': message.type.name,
        'content': message.content,
        'recipient_count': _agents.length - 1,
      },
    ));
  }

  List<Agent> getActiveAgents() {
    return _agents.values.toList();
  }

  Agent? getAgent(String agentId) {
    return _agents[agentId];
  }

  Map<String, dynamic> getCoordinationStatus() {
    final tasksByStatus = <String, int>{};
    for (final status in TaskStatus.values) {
      tasksByStatus[status.name] = _globalTaskGraph.getTasksByStatus(status).length;
    }

    return {
      'active_agents': _agents.length,
      'total_tasks': _globalTaskGraph.getAllTasks().length,
      'tasks_by_status': tasksByStatus,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  void dispose() {
    for (final subscription in _agentSubscriptions.values) {
      subscription.cancel();
    }
    _agentSubscriptions.clear();
    _eventController.close();
  }
}

enum CoordinationEventType {
  agentRegistered,
  agentUnregistered,
  agentError,
  taskAssigned,
  taskReassigned,
  taskCompleted,
  taskFailed,
  taskBreakdownAttempted,
  messageReceived,
  messageBroadcast,
  collaborationStarted,
  collaborationCompleted,
  collaborationFailed,
}

class CoordinationEvent {
  final CoordinationEventType type;
  final String? agentId;
  final String? taskId;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  CoordinationEvent({
    required this.type,
    this.agentId,
    this.taskId,
    required this.timestamp,
    this.data = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'agent_id': agentId,
      'task_id': taskId,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}