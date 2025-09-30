import 'dart:async';
import 'dart:collection';
import '../models/task.dart';
import '../models/agent_message.dart';
import '../tools/tool.dart';
import '../memory/memory_manager.dart';
import '../llm/llm_interface.dart';

abstract class Agent {
  final String id;
  final String name;
  final String description;
  final List<Tool> tools;
  final MemoryManager memory;
  final LLMInterface llm;

  Agent({
    required this.id,
    required this.name,
    required this.description,
    required this.tools,
    required this.memory,
    required this.llm,
  });

  Future<AgentMessage> processMessage(AgentMessage message);
  Future<TaskResult> executeTask(Task task);
  Future<List<Task>> planTasks(String objective);
  Future<void> learnFromExecution(Task task, TaskResult result);

  Stream<AgentMessage> get messageStream;
  Stream<TaskResult> get taskResultStream;
}

class AutonomousAgent extends Agent {
  final StreamController<AgentMessage> _messageController = StreamController<AgentMessage>.broadcast();
  final StreamController<TaskResult> _taskResultController = StreamController<TaskResult>.broadcast();

  bool _isRunning = false;
  String? _currentObjective;
  Queue<Task> _taskQueue = Queue<Task>();

  AutonomousAgent({
    required super.id,
    required super.name,
    required super.description,
    required super.tools,
    required super.memory,
    required super.llm,
  });

  @override
  Stream<AgentMessage> get messageStream => _messageController.stream;

  @override
  Stream<TaskResult> get taskResultStream => _taskResultController.stream;

  Future<void> start(String objective) async {
    if (_isRunning) return;

    _isRunning = true;
    _currentObjective = objective;

    _messageController.add(AgentMessage(
      id: _generateId(),
      agentId: id,
      type: MessageType.status,
      content: "Starting autonomous execution for: $objective",
      timestamp: DateTime.now(),
    ));

    await _autonomousLoop();
  }

  Future<void> stop() async {
    _isRunning = false;
    _taskQueue.clear();

    _messageController.add(AgentMessage(
      id: _generateId(),
      agentId: id,
      type: MessageType.status,
      content: "Stopping autonomous execution",
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _autonomousLoop() async {
    while (_isRunning && _currentObjective != null) {
      try {
        if (_taskQueue.isEmpty) {
          final tasks = await planTasks(_currentObjective!);
          _taskQueue.addAll(tasks);
        }

        if (_taskQueue.isNotEmpty) {
          final task = _taskQueue.removeFirst();
          final result = await executeTask(task);
          await learnFromExecution(task, result);

          if (result.status == TaskStatus.completed) {
            await _checkObjectiveCompletion();
          }
        }

        await Future.delayed(Duration(milliseconds: 100));
      } catch (e) {
        _messageController.add(AgentMessage(
          id: _generateId(),
          agentId: id,
          type: MessageType.error,
          content: "Error in autonomous loop: $e",
          timestamp: DateTime.now(),
        ));

        await Future.delayed(Duration(seconds: 1));
      }
    }
  }

  @override
  Future<AgentMessage> processMessage(AgentMessage message) async {
    await memory.storeMessage(message);

    final context = await memory.getRelevantContext(message.content, limit: 10);
    final prompt = _buildPrompt(message, context);

    final response = await llm.generateResponse(prompt);

    final responseMessage = AgentMessage(
      id: _generateId(),
      agentId: id,
      type: MessageType.response,
      content: response,
      timestamp: DateTime.now(),
      replyTo: message.id,
    );

    await memory.storeMessage(responseMessage);
    _messageController.add(responseMessage);

    return responseMessage;
  }

  @override
  Future<TaskResult> executeTask(Task task) async {
    _messageController.add(AgentMessage(
      id: _generateId(),
      agentId: id,
      type: MessageType.status,
      content: "Executing task: ${task.description}",
      timestamp: DateTime.now(),
    ));

    try {
      final requiredTool = tools.firstWhere(
        (tool) => tool.canHandle(task),
        orElse: () => throw Exception("No tool available for task: ${task.type}"),
      );

      final toolResult = await requiredTool.execute(task.parameters);

      final result = TaskResult(
        taskId: task.id,
        status: TaskStatus.completed,
        result: toolResult,
        completedAt: DateTime.now(),
      );

      _taskResultController.add(result);
      return result;
    } catch (e) {
      final result = TaskResult(
        taskId: task.id,
        status: TaskStatus.failed,
        error: e.toString(),
        completedAt: DateTime.now(),
      );

      _taskResultController.add(result);
      return result;
    }
  }

  @override
  Future<List<Task>> planTasks(String objective) async {
    final planningPrompt = """
    Objective: $objective

    Available tools: ${tools.map((t) => "${t.name}: ${t.description}").join(", ")}

    Break down this objective into specific, actionable tasks. Each task should:
    1. Be executable by one of the available tools
    2. Have clear parameters
    3. Build towards the overall objective

    Return tasks in JSON format:
    [{"type": "tool_name", "description": "task description", "parameters": {...}}]
    """;

    final response = await llm.generateResponse(planningPrompt);
    return _parseTasksFromResponse(response);
  }

  @override
  Future<void> learnFromExecution(Task task, TaskResult result) async {
    final learningEntry = """
    Task: ${task.description}
    Type: ${task.type}
    Parameters: ${task.parameters}
    Result: ${result.status}
    ${result.error != null ? 'Error: ${result.error}' : 'Success: ${result.result}'}
    Timestamp: ${result.completedAt}
    """;

    await memory.storeExecution(learningEntry);

    if (result.status == TaskStatus.failed) {
      await _adaptStrategy(task, result);
    }
  }

  Future<void> _checkObjectiveCompletion() async {
    if (_currentObjective == null) return;

    final completionPrompt = """
    Objective: $_currentObjective
    Recent task results: ${await _getRecentTaskResults()}

    Has the objective been completed? If not, what still needs to be done?
    Respond with: COMPLETED or CONTINUE: [next steps]
    """;

    final response = await llm.generateResponse(completionPrompt);

    if (response.trim().startsWith("COMPLETED")) {
      await stop();
      _messageController.add(AgentMessage(
        id: _generateId(),
        agentId: id,
        type: MessageType.status,
        content: "Objective completed: $_currentObjective",
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _adaptStrategy(Task task, TaskResult result) async {
    final adaptationPrompt = """
    Failed task: ${task.description}
    Error: ${result.error}

    How should I adapt my approach? Suggest alternative strategies or modified parameters.
    """;

    final adaptation = await llm.generateResponse(adaptationPrompt);

    _messageController.add(AgentMessage(
      id: _generateId(),
      agentId: id,
      type: MessageType.learning,
      content: "Adapting strategy: $adaptation",
      timestamp: DateTime.now(),
    ));
  }

  List<Task> _parseTasksFromResponse(String response) {
    // TODO: Implement JSON parsing with error handling
    return [];
  }

  String _buildPrompt(AgentMessage message, List<String> context) {
    return """
    Agent: $name ($description)

    Context:
    ${context.join('\n')}

    User message: ${message.content}

    Respond helpfully and consider available tools: ${tools.map((t) => t.name).join(', ')}
    """;
  }

  Future<String> _getRecentTaskResults() async {
    // TODO: Implement recent task results retrieval
    return "Recent task results...";
  }

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void dispose() {
    _messageController.close();
    _taskResultController.close();
  }
}