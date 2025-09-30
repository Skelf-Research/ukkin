import 'dart:convert';
import '../models/task.dart';
import '../llm/llm_interface.dart';
import '../tools/tool.dart';
import '../memory/memory_manager.dart';

class TaskPlanner {
  final LLMInterface llm;
  final List<Tool> availableTools;
  final MemoryManager memory;

  TaskPlanner({
    required this.llm,
    required this.availableTools,
    required this.memory,
  });

  Future<List<Task>> planTasks(String objective, {String? context}) async {
    final planningContext = await _buildPlanningContext(objective, context);
    final prompt = _buildPlanningPrompt(objective, planningContext);

    final response = await llm.generateResponse(prompt);
    return _parseTasksFromResponse(response, objective);
  }

  Future<List<Task>> refinePlan(List<Task> currentTasks, String feedback) async {
    final prompt = _buildRefinementPrompt(currentTasks, feedback);
    final response = await llm.generateResponse(prompt);
    return _parseTasksFromResponse(response, "Refined plan");
  }

  Future<Task> adaptTask(Task task, String error, {String? context}) async {
    final prompt = _buildAdaptationPrompt(task, error, context);
    final response = await llm.generateResponse(prompt);

    final adaptedTasks = _parseTasksFromResponse(response, "Adapted task");
    return adaptedTasks.isNotEmpty ? adaptedTasks.first : task;
  }

  Future<bool> shouldContinue(String objective, List<TaskResult> completedTasks) async {
    final prompt = _buildContinuationPrompt(objective, completedTasks);
    final response = await llm.generateResponse(prompt);
    return response.trim().toLowerCase().contains('continue');
  }

  Future<List<Task>> breakDownComplexTask(Task complexTask) async {
    final prompt = _buildBreakdownPrompt(complexTask);
    final response = await llm.generateResponse(prompt);
    return _parseTasksFromResponse(response, complexTask.description);
  }

  Future<String> _buildPlanningContext(String objective, String? additionalContext) async {
    final relevantMemories = await memory.getRelevantContext(objective, limit: 5);
    final recentTasks = await memory.getRecentTasks(limit: 10);

    return '''
Previous relevant experiences:
${relevantMemories.join('\n')}

Recent task history:
${recentTasks.map((t) => '${t.type}: ${t.description} (${t.status})').join('\n')}

${additionalContext != null ? 'Additional context:\n$additionalContext' : ''}
''';
  }

  String _buildPlanningPrompt(String objective, String context) {
    final toolDescriptions = availableTools
        .map((tool) => '${tool.name}: ${tool.description}')
        .join('\n');

    return '''
You are an autonomous agent planning system. Break down this objective into executable tasks.

OBJECTIVE: $objective

AVAILABLE TOOLS:
$toolDescriptions

CONTEXT:
$context

PLANNING RULES:
1. Each task must use exactly one available tool
2. Tasks should be specific and actionable
3. Consider dependencies between tasks
4. Plan for error handling and adaptation
5. Include verification/validation tasks

Return a JSON array of tasks with this structure:
[
  {
    "type": "tool_name",
    "description": "Clear description of what this task accomplishes",
    "parameters": {
      "param1": "value1",
      "param2": "value2"
    },
    "priority": "normal|high|urgent",
    "dependencies": ["task_id_1", "task_id_2"]
  }
]

Focus on creating a logical sequence that achieves the objective efficiently.
''';
  }

  String _buildRefinementPrompt(List<Task> currentTasks, String feedback) {
    final tasksJson = currentTasks.map((t) => t.toJson()).toList();

    return '''
Current task plan:
${jsonEncode(tasksJson)}

Feedback/Issues:
$feedback

Refine the task plan based on this feedback. Consider:
1. What went wrong and why
2. Alternative approaches
3. Missing dependencies or steps
4. Better tool selection

Return an improved JSON array of tasks with the same structure.
''';
  }

  String _buildAdaptationPrompt(Task task, String error, String? context) {
    return '''
Failed task:
${jsonEncode(task.toJson())}

Error encountered:
$error

${context != null ? 'Additional context:\n$context' : ''}

Create an adapted version of this task that:
1. Addresses the root cause of the failure
2. Uses alternative approaches if needed
3. Includes better error handling
4. May break into smaller sub-tasks if necessary

Return a JSON array with the adapted task(s).
''';
  }

  String _buildContinuationPrompt(String objective, List<TaskResult> completedTasks) {
    final resultsJson = completedTasks.map((r) => r.toJson()).toList();

    return '''
Original objective: $objective

Completed tasks and results:
${jsonEncode(resultsJson)}

Based on these results, has the objective been achieved?

Respond with either:
- "COMPLETED: [summary of achievement]"
- "CONTINUE: [what still needs to be done]"
''';
  }

  String _buildBreakdownPrompt(Task complexTask) {
    return '''
Complex task to break down:
${jsonEncode(complexTask.toJson())}

Available tools: ${availableTools.map((t) => t.name).join(', ')}

Break this complex task into smaller, more manageable sub-tasks that:
1. Each use a single available tool
2. Build towards completing the original task
3. Have clear dependencies
4. Are specific and actionable

Return a JSON array of sub-tasks.
''';
  }

  List<Task> _parseTasksFromResponse(String response, String parentDescription) {
    try {
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;

      if (jsonStart == -1 || jsonEnd == 0) {
        throw Exception('No valid JSON array found in response');
      }

      final jsonString = response.substring(jsonStart, jsonEnd);
      final List<dynamic> tasksJson = jsonDecode(jsonString);

      return tasksJson.asMap().entries.map((entry) {
        final index = entry.key;
        final taskData = entry.value as Map<String, dynamic>;

        return Task(
          id: '${DateTime.now().millisecondsSinceEpoch}_$index',
          type: taskData['type'] ?? 'unknown',
          description: taskData['description'] ?? 'No description',
          parameters: Map<String, dynamic>.from(taskData['parameters'] ?? {}),
          priority: TaskPriority.values.firstWhere(
            (p) => p.name == taskData['priority'],
            orElse: () => TaskPriority.normal,
          ),
          dependencies: List<String>.from(taskData['dependencies'] ?? []),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to parse tasks from LLM response: $e\nResponse: $response');
    }
  }

  Future<TaskGraph> createExecutionGraph(List<Task> tasks) async {
    final graph = TaskGraph();

    for (final task in tasks) {
      graph.addTask(task);
    }

    if (graph.hasCircularDependencies()) {
      throw Exception('Circular dependencies detected in task plan');
    }

    return graph;
  }

  Future<List<Task>> optimizePlan(List<Task> tasks) async {
    final prompt = '''
Task plan to optimize:
${jsonEncode(tasks.map((t) => t.toJson()).toList())}

Optimize this plan for:
1. Parallel execution opportunities
2. Resource efficiency
3. Reduced redundancy
4. Better error recovery

Return an optimized JSON array of tasks.
''';

    final response = await llm.generateResponse(prompt);
    return _parseTasksFromResponse(response, "Optimized plan");
  }
}