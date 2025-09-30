import 'dart:convert';
import 'dart:async';
import '../models/task.dart';
import '../tools/tool.dart';
import '../llm/llm_interface.dart';
import 'mobile_controller.dart';
import 'app_automation_tool.dart';
import 'accessibility_service.dart';
import 'screen_recorder.dart';

class WorkflowStep {
  final String id;
  final String type;
  final String description;
  final Map<String, dynamic> parameters;
  final List<String> dependencies;
  final Duration? timeout;
  final int retryCount;
  final Map<String, dynamic> conditions;

  WorkflowStep({
    required this.id,
    required this.type,
    required this.description,
    required this.parameters,
    this.dependencies = const [],
    this.timeout,
    this.retryCount = 1,
    this.conditions = const {},
  });

  factory WorkflowStep.fromJson(Map<String, dynamic> json) {
    return WorkflowStep(
      id: json['id'],
      type: json['type'],
      description: json['description'],
      parameters: Map<String, dynamic>.from(json['parameters']),
      dependencies: List<String>.from(json['dependencies'] ?? []),
      timeout: json['timeout'] != null ? Duration(milliseconds: json['timeout']) : null,
      retryCount: json['retryCount'] ?? 1,
      conditions: Map<String, dynamic>.from(json['conditions'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'parameters': parameters,
      'dependencies': dependencies,
      'timeout': timeout?.inMilliseconds,
      'retryCount': retryCount,
      'conditions': conditions,
    };
  }
}

class WorkflowExecution {
  final String id;
  final String workflowId;
  final DateTime startTime;
  DateTime? endTime;
  WorkflowStatus status;
  final Map<String, WorkflowStepResult> stepResults;
  String? error;
  final Map<String, dynamic> context;

  WorkflowExecution({
    required this.id,
    required this.workflowId,
    DateTime? startTime,
    this.status = WorkflowStatus.pending,
  }) : startTime = startTime ?? DateTime.now(),
       stepResults = {},
       context = {};

  double get progressPercentage {
    if (stepResults.isEmpty) return 0.0;
    final completedSteps = stepResults.values.where((r) => r.status == WorkflowStepStatus.completed).length;
    return (completedSteps / stepResults.length) * 100;
  }

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }
}

class WorkflowStepResult {
  final String stepId;
  final WorkflowStepStatus status;
  final dynamic result;
  final String? error;
  final DateTime timestamp;
  final Duration? executionTime;

  WorkflowStepResult({
    required this.stepId,
    required this.status,
    this.result,
    this.error,
    DateTime? timestamp,
    this.executionTime,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum WorkflowStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
  paused,
}

enum WorkflowStepStatus {
  pending,
  running,
  completed,
  failed,
  skipped,
  retrying,
}

class WorkflowDefinition {
  final String id;
  final String name;
  final String description;
  final List<WorkflowStep> steps;
  final Map<String, dynamic> metadata;
  final List<String> tags;

  WorkflowDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.steps,
    this.metadata = const {},
    this.tags = const [],
  });

  factory WorkflowDefinition.fromJson(Map<String, dynamic> json) {
    return WorkflowDefinition(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      steps: (json['steps'] as List).map((s) => WorkflowStep.fromJson(s)).toList(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'steps': steps.map((s) => s.toJson()).toList(),
      'metadata': metadata,
      'tags': tags,
    };
  }
}

class WorkflowEngine extends Tool with ToolValidation {
  final LLMInterface llm;
  final MobileController mobileController;
  final AppAutomationTool appAutomation;
  final AccessibilityService accessibilityService;
  final ScreenRecorder screenRecorder;

  final Map<String, WorkflowDefinition> _workflows = {};
  final Map<String, WorkflowExecution> _executions = {};
  final StreamController<WorkflowEvent> _eventController = StreamController<WorkflowEvent>.broadcast();

  WorkflowEngine({
    required this.llm,
    required this.mobileController,
    required this.appAutomation,
    required this.accessibilityService,
    required this.screenRecorder,
  });

  @override
  String get name => 'workflow_engine';

  @override
  String get description => 'Execute complex multi-step mobile automation workflows';

  @override
  Map<String, String> get parameters => {
        'action': 'Action: create_workflow, execute_workflow, pause_workflow, resume_workflow, cancel_workflow',
        'workflow_id': 'Workflow identifier',
        'workflow_definition': 'JSON workflow definition',
        'execution_id': 'Execution identifier',
        'objective': 'High-level objective for workflow generation',
        'context': 'Additional context for workflow execution',
      };

  Stream<WorkflowEvent> get events => _eventController.stream;

  @override
  bool canHandle(Task task) {
    return task.type == 'workflow' || task.type.startsWith('workflow_');
  }

  @override
  Future<bool> validate(Map<String, dynamic> parameters) async {
    return validateRequired(parameters, ['action']);
  }

  @override
  Future<dynamic> execute(Map<String, dynamic> parameters) async {
    if (!await validate(parameters)) {
      throw Exception('Invalid parameters for workflow engine');
    }

    final action = parameters['action'] as String;

    try {
      switch (action) {
        case 'create_workflow':
          return await _createWorkflow(
            parameters['objective'],
            parameters['context'],
          );
        case 'execute_workflow':
          return await _executeWorkflow(
            parameters['workflow_id'],
            parameters['context'],
          );
        case 'pause_workflow':
          return await _pauseWorkflow(parameters['execution_id']);
        case 'resume_workflow':
          return await _resumeWorkflow(parameters['execution_id']);
        case 'cancel_workflow':
          return await _cancelWorkflow(parameters['execution_id']);
        case 'get_execution_status':
          return await _getExecutionStatus(parameters['execution_id']);
        case 'list_workflows':
          return await _listWorkflows();
        default:
          throw Exception('Unknown workflow action: $action');
      }
    } catch (e) {
      return ToolExecutionResult.failure('Workflow action failed: $e');
    }
  }

  Future<ToolExecutionResult> _createWorkflow(String? objective, Map<String, dynamic>? context) async {
    if (objective == null) {
      return ToolExecutionResult.failure('Objective is required');
    }

    try {
      final workflowDefinition = await _generateWorkflowFromObjective(objective, context ?? {});

      _workflows[workflowDefinition.id] = workflowDefinition;

      _eventController.add(WorkflowEvent(
        type: WorkflowEventType.workflowCreated,
        workflowId: workflowDefinition.id,
        timestamp: DateTime.now(),
        data: {'objective': objective},
      ));

      return ToolExecutionResult.success({
        'action': 'create_workflow',
        'workflow_id': workflowDefinition.id,
        'workflow': workflowDefinition.toJson(),
        'objective': objective,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Create workflow failed: $e');
    }
  }

  Future<ToolExecutionResult> _executeWorkflow(String? workflowId, Map<String, dynamic>? context) async {
    if (workflowId == null) {
      return ToolExecutionResult.failure('Workflow ID is required');
    }

    final workflow = _workflows[workflowId];
    if (workflow == null) {
      return ToolExecutionResult.failure('Workflow not found: $workflowId');
    }

    try {
      final executionId = '${workflowId}_${DateTime.now().millisecondsSinceEpoch}';
      final execution = WorkflowExecution(
        id: executionId,
        workflowId: workflowId,
        status: WorkflowStatus.running,
      );

      if (context != null) {
        execution.context.addAll(context);
      }

      _executions[executionId] = execution;

      _eventController.add(WorkflowEvent(
        type: WorkflowEventType.executionStarted,
        workflowId: workflowId,
        executionId: executionId,
        timestamp: DateTime.now(),
      ));

      // Execute workflow asynchronously
      _executeWorkflowSteps(workflow, execution);

      return ToolExecutionResult.success({
        'action': 'execute_workflow',
        'workflow_id': workflowId,
        'execution_id': executionId,
        'status': 'started',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Execute workflow failed: $e');
    }
  }

  Future<void> _executeWorkflowSteps(WorkflowDefinition workflow, WorkflowExecution execution) async {
    try {
      // Start screen recording if not already recording
      if (!screenRecorder.isRecording) {
        await screenRecorder.execute({
          'action': 'start_recording',
          'duration': 3600, // 1 hour max
          'quality': 'medium',
        });
      }

      for (final step in workflow.steps) {
        if (execution.status != WorkflowStatus.running) {
          break; // Workflow was paused or cancelled
        }

        // Check dependencies
        if (!_areDependenciesMet(step, execution)) {
          execution.stepResults[step.id] = WorkflowStepResult(
            stepId: step.id,
            status: WorkflowStepStatus.skipped,
            error: 'Dependencies not met',
          );
          continue;
        }

        // Execute step with retries
        await _executeStepWithRetries(step, execution);
      }

      // Complete execution
      if (execution.status == WorkflowStatus.running) {
        execution.status = WorkflowStatus.completed;
        execution.endTime = DateTime.now();

        _eventController.add(WorkflowEvent(
          type: WorkflowEventType.executionCompleted,
          workflowId: execution.workflowId,
          executionId: execution.id,
          timestamp: DateTime.now(),
        ));
      }

      // Stop screen recording and analyze
      await _finalizeExecution(execution);

    } catch (e) {
      execution.status = WorkflowStatus.failed;
      execution.error = e.toString();
      execution.endTime = DateTime.now();

      _eventController.add(WorkflowEvent(
        type: WorkflowEventType.executionFailed,
        workflowId: execution.workflowId,
        executionId: execution.id,
        timestamp: DateTime.now(),
        data: {'error': e.toString()},
      ));
    }
  }

  Future<void> _executeStepWithRetries(WorkflowStep step, WorkflowExecution execution) async {
    int attempts = 0;
    while (attempts <= step.retryCount) {
      try {
        final stepResult = WorkflowStepResult(
          stepId: step.id,
          status: WorkflowStepStatus.running,
        );
        execution.stepResults[step.id] = stepResult;

        _eventController.add(WorkflowEvent(
          type: WorkflowEventType.stepStarted,
          workflowId: execution.workflowId,
          executionId: execution.id,
          stepId: step.id,
          timestamp: DateTime.now(),
        ));

        final startTime = DateTime.now();
        final result = await _executeStep(step, execution);
        final executionTime = DateTime.now().difference(startTime);

        execution.stepResults[step.id] = WorkflowStepResult(
          stepId: step.id,
          status: WorkflowStepStatus.completed,
          result: result.data,
          executionTime: executionTime,
        );

        _eventController.add(WorkflowEvent(
          type: WorkflowEventType.stepCompleted,
          workflowId: execution.workflowId,
          executionId: execution.id,
          stepId: step.id,
          timestamp: DateTime.now(),
        ));

        break; // Success, exit retry loop

      } catch (e) {
        attempts++;

        if (attempts > step.retryCount) {
          execution.stepResults[step.id] = WorkflowStepResult(
            stepId: step.id,
            status: WorkflowStepStatus.failed,
            error: e.toString(),
          );

          _eventController.add(WorkflowEvent(
            type: WorkflowEventType.stepFailed,
            workflowId: execution.workflowId,
            executionId: execution.id,
            stepId: step.id,
            timestamp: DateTime.now(),
            data: {'error': e.toString(), 'attempts': attempts},
          ));

          throw e; // Re-throw to fail the workflow
        } else {
          execution.stepResults[step.id] = WorkflowStepResult(
            stepId: step.id,
            status: WorkflowStepStatus.retrying,
            error: e.toString(),
          );

          _eventController.add(WorkflowEvent(
            type: WorkflowEventType.stepRetrying,
            workflowId: execution.workflowId,
            executionId: execution.id,
            stepId: step.id,
            timestamp: DateTime.now(),
            data: {'error': e.toString(), 'attempt': attempts},
          ));

          // Wait before retry
          await Future.delayed(Duration(seconds: 2 * attempts));
        }
      }
    }
  }

  Future<ToolExecutionResult> _executeStep(WorkflowStep step, WorkflowExecution execution) async {
    switch (step.type) {
      case 'mobile_control':
        return await mobileController.execute(step.parameters);
      case 'app_automation':
        return await appAutomation.execute(step.parameters);
      case 'accessibility':
        return await accessibilityService.execute(step.parameters);
      case 'screen_recording':
        return await screenRecorder.execute(step.parameters);
      case 'wait':
        await Future.delayed(Duration(milliseconds: step.parameters['duration'] ?? 1000));
        return ToolExecutionResult.success({'waited': true});
      case 'conditional':
        return await _executeConditionalStep(step, execution);
      case 'loop':
        return await _executeLoopStep(step, execution);
      default:
        throw Exception('Unknown step type: ${step.type}');
    }
  }

  Future<ToolExecutionResult> _executeConditionalStep(WorkflowStep step, WorkflowExecution execution) async {
    final condition = step.parameters['condition'] as String;
    final conditionMet = await _evaluateCondition(condition, execution);

    if (conditionMet) {
      final thenSteps = step.parameters['then'] as List;
      for (final stepData in thenSteps) {
        final subStep = WorkflowStep.fromJson(stepData);
        await _executeStep(subStep, execution);
      }
    } else {
      final elseSteps = step.parameters['else'] as List?;
      if (elseSteps != null) {
        for (final stepData in elseSteps) {
          final subStep = WorkflowStep.fromJson(stepData);
          await _executeStep(subStep, execution);
        }
      }
    }

    return ToolExecutionResult.success({'condition_met': conditionMet});
  }

  Future<ToolExecutionResult> _executeLoopStep(WorkflowStep step, WorkflowExecution execution) async {
    final maxIterations = step.parameters['max_iterations'] as int? ?? 10;
    final condition = step.parameters['condition'] as String?;
    final loopSteps = step.parameters['steps'] as List;

    int iterations = 0;
    while (iterations < maxIterations) {
      if (condition != null && !await _evaluateCondition(condition, execution)) {
        break;
      }

      for (final stepData in loopSteps) {
        final subStep = WorkflowStep.fromJson(stepData);
        await _executeStep(subStep, execution);
      }

      iterations++;
    }

    return ToolExecutionResult.success({'iterations': iterations});
  }

  Future<bool> _evaluateCondition(String condition, WorkflowExecution execution) async {
    // Simple condition evaluation - can be expanded
    if (condition.startsWith('element_exists:')) {
      final elementDesc = condition.substring('element_exists:'.length);
      final result = await accessibilityService.execute({
        'action': 'find_by_text',
        'text': elementDesc,
      });
      return result.success && (result.data['count'] as int) > 0;
    }

    return true; // Default to true for unknown conditions
  }

  bool _areDependenciesMet(WorkflowStep step, WorkflowExecution execution) {
    for (final depId in step.dependencies) {
      final depResult = execution.stepResults[depId];
      if (depResult == null || depResult.status != WorkflowStepStatus.completed) {
        return false;
      }
    }
    return true;
  }

  Future<WorkflowDefinition> _generateWorkflowFromObjective(String objective, Map<String, dynamic> context) async {
    final prompt = '''
    Generate a mobile automation workflow to achieve this objective: "$objective"

    Context: ${jsonEncode(context)}

    Available actions:
    - mobile_control: tap, swipe, type, scroll, back, home, open_app, close_app
    - app_automation: whatsapp, telegram, gmail, chrome, instagram, youtube, etc.
    - accessibility: find elements, get text, perform actions
    - screen_recording: take screenshots, record interactions

    Create a workflow with these step types and return JSON:
    {
      "id": "workflow_id",
      "name": "Workflow Name",
      "description": "Description",
      "steps": [
        {
          "id": "step1",
          "type": "mobile_control",
          "description": "Description",
          "parameters": {...},
          "dependencies": [],
          "retryCount": 1
        }
      ]
    }

    Make the workflow robust with proper error handling and retries.
    ''';

    final response = await llm.generateResponse(prompt);

    try {
      final workflowJson = _extractJsonFromResponse(response);
      return WorkflowDefinition.fromJson(workflowJson);
    } catch (e) {
      throw Exception('Failed to generate workflow: $e');
    }
  }

  Map<String, dynamic> _extractJsonFromResponse(String response) {
    // Extract JSON from LLM response
    final jsonStart = response.indexOf('{');
    final jsonEnd = response.lastIndexOf('}') + 1;

    if (jsonStart == -1 || jsonEnd == 0) {
      throw Exception('No valid JSON found in response');
    }

    final jsonString = response.substring(jsonStart, jsonEnd);
    return jsonDecode(jsonString);
  }

  Future<void> _finalizeExecution(WorkflowExecution execution) async {
    try {
      // Stop screen recording
      final recordingResult = await screenRecorder.execute({'action': 'stop_recording'});

      if (recordingResult.success) {
        final recordingPath = recordingResult.data['output_path'] as String;

        // Analyze the workflow execution
        final analysisResult = await screenRecorder.execute({
          'action': 'analyze_recording',
          'recording_path': recordingPath,
          'analysis_prompt': 'Analyze this mobile automation workflow execution',
        });

        execution.context['recording_analysis'] = analysisResult.data;
      }
    } catch (e) {
      // Don't fail the execution if recording analysis fails
      execution.context['recording_error'] = e.toString();
    }
  }

  Future<ToolExecutionResult> _pauseWorkflow(String? executionId) async {
    if (executionId == null) {
      return ToolExecutionResult.failure('Execution ID is required');
    }

    final execution = _executions[executionId];
    if (execution == null) {
      return ToolExecutionResult.failure('Execution not found');
    }

    execution.status = WorkflowStatus.paused;

    return ToolExecutionResult.success({
      'action': 'pause_workflow',
      'execution_id': executionId,
      'status': 'paused',
    });
  }

  Future<ToolExecutionResult> _resumeWorkflow(String? executionId) async {
    if (executionId == null) {
      return ToolExecutionResult.failure('Execution ID is required');
    }

    final execution = _executions[executionId];
    if (execution == null) {
      return ToolExecutionResult.failure('Execution not found');
    }

    execution.status = WorkflowStatus.running;

    return ToolExecutionResult.success({
      'action': 'resume_workflow',
      'execution_id': executionId,
      'status': 'running',
    });
  }

  Future<ToolExecutionResult> _cancelWorkflow(String? executionId) async {
    if (executionId == null) {
      return ToolExecutionResult.failure('Execution ID is required');
    }

    final execution = _executions[executionId];
    if (execution == null) {
      return ToolExecutionResult.failure('Execution not found');
    }

    execution.status = WorkflowStatus.cancelled;
    execution.endTime = DateTime.now();

    return ToolExecutionResult.success({
      'action': 'cancel_workflow',
      'execution_id': executionId,
      'status': 'cancelled',
    });
  }

  Future<ToolExecutionResult> _getExecutionStatus(String? executionId) async {
    if (executionId == null) {
      return ToolExecutionResult.failure('Execution ID is required');
    }

    final execution = _executions[executionId];
    if (execution == null) {
      return ToolExecutionResult.failure('Execution not found');
    }

    return ToolExecutionResult.success({
      'execution_id': executionId,
      'workflow_id': execution.workflowId,
      'status': execution.status.name,
      'progress_percentage': execution.progressPercentage,
      'start_time': execution.startTime.toIso8601String(),
      'end_time': execution.endTime?.toIso8601String(),
      'duration_seconds': execution.duration?.inSeconds,
      'step_count': execution.stepResults.length,
      'completed_steps': execution.stepResults.values.where((r) => r.status == WorkflowStepStatus.completed).length,
      'failed_steps': execution.stepResults.values.where((r) => r.status == WorkflowStepStatus.failed).length,
    });
  }

  Future<ToolExecutionResult> _listWorkflows() async {
    final workflows = _workflows.values.map((w) => {
      'id': w.id,
      'name': w.name,
      'description': w.description,
      'step_count': w.steps.length,
      'tags': w.tags,
    }).toList();

    return ToolExecutionResult.success({
      'workflows': workflows,
      'count': workflows.length,
    });
  }

  void dispose() {
    _eventController.close();
  }
}

enum WorkflowEventType {
  workflowCreated,
  executionStarted,
  executionCompleted,
  executionFailed,
  executionPaused,
  executionResumed,
  executionCancelled,
  stepStarted,
  stepCompleted,
  stepFailed,
  stepRetrying,
}

class WorkflowEvent {
  final WorkflowEventType type;
  final String workflowId;
  final String? executionId;
  final String? stepId;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  WorkflowEvent({
    required this.type,
    required this.workflowId,
    this.executionId,
    this.stepId,
    required this.timestamp,
    this.data = const {},
  });
}