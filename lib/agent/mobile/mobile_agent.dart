import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/agent.dart';
import '../models/task.dart';
import '../models/agent_message.dart';
import '../tools/tool.dart';
import '../memory/memory_manager.dart';
import '../llm/llm_interface.dart';
import '../llm/fllama_adapter.dart';
import 'mobile_controller.dart';
import 'app_automation_tool.dart';
import 'accessibility_service.dart';
import 'screen_recorder.dart';
import 'workflow_engine.dart';
import 'phone_integrations.dart';

class MobileAgent extends AutonomousAgent {
  final MobileController mobileController;
  final AppAutomationTool appAutomation;
  final AccessibilityService accessibilityService;
  final ScreenRecorder screenRecorder;
  final WorkflowEngine workflowEngine;
  final PhoneIntegrations phoneIntegrations;

  bool _isLearningMode = false;
  String? _currentWorkflowId;
  StreamSubscription? _workflowSubscription;

  MobileAgent({
    required super.id,
    required super.name,
    required super.description,
    required super.tools,
    required super.memory,
    required super.llm,
    required this.mobileController,
    required this.appAutomation,
    required this.accessibilityService,
    required this.screenRecorder,
    required this.workflowEngine,
    required this.phoneIntegrations,
  }) {
    _setupWorkflowListening();
  }

  void _setupWorkflowListening() {
    _workflowSubscription = workflowEngine.events.listen((event) {
      _handleWorkflowEvent(event);
    });
  }

  @override
  Future<List<Task>> planTasks(String objective) async {
    _messageController.add(AgentMessage(
      id: _generateId(),
      agentId: id,
      type: MessageType.status,
      content: "Planning mobile automation tasks for: $objective",
      timestamp: DateTime.now(),
    ));

    final planningPrompt = """
    You are a mobile automation agent. Plan tasks to achieve this objective: "$objective"

    Available mobile capabilities:
    - Mobile Control: tap, swipe, type, scroll, navigate apps
    - App Automation: WhatsApp, Telegram, Gmail, Chrome, Instagram, YouTube, etc.
    - Phone Integration: SMS, calls, contacts, notifications, calendar
    - Screen Analysis: screenshots, recording, UI understanding
    - Workflow Automation: complex multi-step task chains

    Break down the objective into specific mobile automation tasks. Consider:
    1. Which apps need to be used
    2. What permissions might be required
    3. UI interactions needed
    4. Error handling and verification steps

    Return tasks in JSON format:
    [
      {
        "type": "mobile_control",
        "description": "Open WhatsApp app",
        "parameters": {"action": "open_app", "app_package": "com.whatsapp"}
      },
      {
        "type": "app_automation",
        "description": "Send message to contact",
        "parameters": {"app": "whatsapp", "action": "send_message", "recipient": "John", "message": "Hello"}
      }
    ]
    """;

    try {
      final response = await llm.generateResponse(planningPrompt);
      return _parseTasksFromResponse(response);
    } catch (e) {
      _messageController.add(AgentMessage(
        id: _generateId(),
        agentId: id,
        type: MessageType.error,
        content: "Failed to plan mobile tasks: $e",
        timestamp: DateTime.now(),
      ));
      return [];
    }
  }

  @override
  Future<TaskResult> executeTask(Task task) async {
    _messageController.add(AgentMessage(
      id: _generateId(),
      agentId: id,
      type: MessageType.status,
      content: "Executing mobile task: ${task.description}",
      timestamp: DateTime.now(),
    ));

    try {
      // Check if accessibility service is enabled for UI interactions
      if (_requiresAccessibility(task) && !await accessibilityService.isServiceEnabled()) {
        throw Exception("Accessibility service required but not enabled");
      }

      // Record screen if in learning mode
      if (_isLearningMode && !screenRecorder.isRecording) {
        await screenRecorder.execute({
          'action': 'start_recording',
          'duration': 300, // 5 minutes
        });
      }

      // Execute the task
      final tool = _getToolForTask(task);
      if (tool == null) {
        throw Exception("No tool available for task type: ${task.type}");
      }

      final toolResult = await tool.execute(task.parameters);

      if (toolResult.success) {
        _messageController.add(AgentMessage(
          id: _generateId(),
          agentId: id,
          type: MessageType.status,
          content: "Mobile task completed successfully: ${task.description}",
          timestamp: DateTime.now(),
        ));

        return TaskResult(
          taskId: task.id,
          status: TaskStatus.completed,
          result: toolResult.data,
          completedAt: DateTime.now(),
        );
      } else {
        throw Exception(toolResult.error ?? "Task execution failed");
      }
    } catch (e) {
      _messageController.add(AgentMessage(
        id: _generateId(),
        agentId: id,
        type: MessageType.error,
        content: "Mobile task failed: ${task.description} - $e",
        timestamp: DateTime.now(),
      ));

      return TaskResult(
        taskId: task.id,
        status: TaskStatus.failed,
        error: e.toString(),
        completedAt: DateTime.now(),
      );
    }
  }

  Tool? _getToolForTask(Task task) {
    switch (task.type) {
      case 'mobile_control':
        return mobileController;
      case 'app_automation':
        return appAutomation;
      case 'accessibility':
        return accessibilityService;
      case 'screen_recording':
        return screenRecorder;
      case 'workflow':
        return workflowEngine;
      case 'phone_integration':
        return phoneIntegrations;
      default:
        return tools.firstWhere(
          (tool) => tool.canHandle(task),
          orElse: () => null,
        );
    }
  }

  bool _requiresAccessibility(Task task) {
    return task.type == 'mobile_control' ||
           task.type == 'app_automation' ||
           task.type == 'accessibility';
  }

  Future<void> startComplexWorkflow(String objective) async {
    try {
      _messageController.add(AgentMessage(
        id: _generateId(),
        agentId: id,
        type: MessageType.status,
        content: "Creating mobile workflow for: $objective",
        timestamp: DateTime.now(),
      ));

      // Generate workflow using workflow engine
      final workflowResult = await workflowEngine.execute({
        'action': 'create_workflow',
        'objective': objective,
        'context': {
          'agent_id': id,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });

      if (workflowResult.success) {
        final workflowId = workflowResult.data['workflow_id'] as String;
        _currentWorkflowId = workflowId;

        _messageController.add(AgentMessage(
          id: _generateId(),
          agentId: id,
          type: MessageType.status,
          content: "Workflow created. Executing: $workflowId",
          timestamp: DateTime.now(),
        ));

        // Execute the workflow
        final executionResult = await workflowEngine.execute({
          'action': 'execute_workflow',
          'workflow_id': workflowId,
        });

        if (executionResult.success) {
          _messageController.add(AgentMessage(
            id: _generateId(),
            agentId: id,
            type: MessageType.status,
            content: "Mobile workflow started successfully",
            timestamp: DateTime.now(),
          ));
        } else {
          throw Exception("Failed to execute workflow: ${executionResult.error}");
        }
      } else {
        throw Exception("Failed to create workflow: ${workflowResult.error}");
      }
    } catch (e) {
      _messageController.add(AgentMessage(
        id: _generateId(),
        agentId: id,
        type: MessageType.error,
        content: "Failed to start complex workflow: $e",
        timestamp: DateTime.now(),
      ));
    }
  }

  void _handleWorkflowEvent(WorkflowEvent event) {
    String statusMessage;
    MessageType messageType = MessageType.status;

    switch (event.type) {
      case WorkflowEventType.executionStarted:
        statusMessage = "Workflow execution started";
        break;
      case WorkflowEventType.stepStarted:
        statusMessage = "Starting step: ${event.stepId}";
        break;
      case WorkflowEventType.stepCompleted:
        statusMessage = "Completed step: ${event.stepId}";
        break;
      case WorkflowEventType.stepFailed:
        statusMessage = "Step failed: ${event.stepId} - ${event.data['error']}";
        messageType = MessageType.error;
        break;
      case WorkflowEventType.executionCompleted:
        statusMessage = "Workflow completed successfully";
        _currentWorkflowId = null;
        break;
      case WorkflowEventType.executionFailed:
        statusMessage = "Workflow failed: ${event.data['error']}";
        messageType = MessageType.error;
        _currentWorkflowId = null;
        break;
      default:
        statusMessage = "Workflow event: ${event.type.name}";
    }

    _messageController.add(AgentMessage(
      id: _generateId(),
      agentId: id,
      type: messageType,
      content: statusMessage,
      timestamp: DateTime.now(),
      metadata: {
        'workflow_id': event.workflowId,
        'execution_id': event.executionId,
        'step_id': event.stepId,
        'event_type': event.type.name,
      },
    ));
  }

  Future<void> enableLearningMode() async {
    _isLearningMode = true;

    _messageController.add(AgentMessage(
      id: _generateId(),
      agentId: id,
      type: MessageType.learning,
      content: "Learning mode enabled. I will record and analyze interactions to improve automation.",
      timestamp: DateTime.now(),
    ));
  }

  Future<void> disableLearningMode() async {
    _isLearningMode = false;

    if (screenRecorder.isRecording) {
      await screenRecorder.execute({'action': 'stop_recording'});
    }

    _messageController.add(AgentMessage(
      id: _generateId(),
      agentId: id,
      type: MessageType.learning,
      content: "Learning mode disabled.",
      timestamp: DateTime.now(),
    ));
  }

  Future<AgentMessage> handleVoiceCommand(String voiceText) async {
    _messageController.add(AgentMessage(
      id: _generateId(),
      agentId: id,
      type: MessageType.user,
      content: "Voice command: $voiceText",
      timestamp: DateTime.now(),
      metadata: {'input_type': 'voice'},
    ));

    // Process voice command
    final interpretationPrompt = """
    Interpret this voice command for mobile automation: "$voiceText"

    Common voice patterns:
    - "Send a message to [name] saying [message]"
    - "Call [name]"
    - "Open [app name]"
    - "Take a screenshot"
    - "What notifications do I have?"
    - "Set a reminder for [time] to [task]"

    Respond with either:
    1. A direct mobile action in JSON format
    2. A clarifying question if the command is ambiguous
    3. An explanation if the command cannot be automated

    If it's a mobile action, format as:
    {
      "action_type": "mobile_task",
      "task": {
        "type": "app_automation",
        "parameters": {...}
      }
    }
    """;

    try {
      final interpretation = await llm.generateResponse(interpretationPrompt);

      // Try to parse as JSON for direct action
      if (interpretation.contains('"action_type": "mobile_task"')) {
        // Extract and execute mobile task
        final task = _parseVoiceCommandTask(interpretation);
        if (task != null) {
          await executeTask(task);
          return AgentMessage(
            id: _generateId(),
            agentId: id,
            type: MessageType.agent,
            content: "Voice command executed: ${task.description}",
            timestamp: DateTime.now(),
          );
        }
      }

      // Return interpretation/clarification
      return AgentMessage(
        id: _generateId(),
        agentId: id,
        type: MessageType.agent,
        content: interpretation,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return AgentMessage(
        id: _generateId(),
        agentId: id,
        type: MessageType.error,
        content: "Failed to process voice command: $e",
        timestamp: DateTime.now(),
      );
    }
  }

  Task? _parseVoiceCommandTask(String interpretation) {
    // TODO: Implement JSON parsing from LLM response
    return null;
  }

  Future<void> pauseCurrentWorkflow() async {
    if (_currentWorkflowId != null) {
      await workflowEngine.execute({
        'action': 'pause_workflow',
        'execution_id': _currentWorkflowId,
      });
    }
  }

  Future<void> resumeCurrentWorkflow() async {
    if (_currentWorkflowId != null) {
      await workflowEngine.execute({
        'action': 'resume_workflow',
        'execution_id': _currentWorkflowId,
      });
    }
  }

  Future<void> cancelCurrentWorkflow() async {
    if (_currentWorkflowId != null) {
      await workflowEngine.execute({
        'action': 'cancel_workflow',
        'execution_id': _currentWorkflowId,
      });
      _currentWorkflowId = null;
    }
  }

  Future<Map<String, dynamic>> getAgentStatus() async {
    final batteryStatus = await phoneIntegrations.execute({'action': 'get_battery_status'});
    final networkStatus = await phoneIntegrations.execute({'action': 'get_network_status'});
    final accessibilityEnabled = await accessibilityService.isServiceEnabled();
    final recordingStatus = screenRecorder.isRecording;

    return {
      'agent_id': id,
      'agent_name': name,
      'is_learning_mode': _isLearningMode,
      'current_workflow': _currentWorkflowId,
      'accessibility_enabled': accessibilityEnabled,
      'recording_active': recordingStatus,
      'device_status': {
        'battery': batteryStatus.data,
        'network': networkStatus.data,
      },
      'capabilities': {
        'mobile_control': true,
        'app_automation': true,
        'phone_integration': true,
        'workflow_automation': true,
        'screen_analysis': true,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<void> setupRequiredPermissions() async {
    _messageController.add(AgentMessage(
      id: _generateId(),
      agentId: id,
      type: MessageType.status,
      content: "Checking required permissions for mobile automation...",
      timestamp: DateTime.now(),
    ));

    try {
      // Check accessibility service
      if (!await accessibilityService.isServiceEnabled()) {
        _messageController.add(AgentMessage(
          id: _generateId(),
          agentId: id,
          type: MessageType.status,
          content: "Requesting accessibility service permission...",
          timestamp: DateTime.now(),
        ));

        await accessibilityService.requestServicePermission();
      }

      // Check screen recording permissions
      if (!await screenRecorder.hasPermissions()) {
        _messageController.add(AgentMessage(
          id: _generateId(),
          agentId: id,
          type: MessageType.status,
          content: "Requesting screen recording permissions...",
          timestamp: DateTime.now(),
        ));

        await screenRecorder.requestPermissions();
      }

      // Check phone integration permissions
      final phonePermissions = await phoneIntegrations.checkAllPermissions();
      final missingPermissions = phonePermissions.entries
          .where((entry) => !entry.value)
          .map((entry) => entry.key)
          .toList();

      if (missingPermissions.isNotEmpty) {
        _messageController.add(AgentMessage(
          id: _generateId(),
          agentId: id,
          type: MessageType.status,
          content: "Requesting phone permissions: ${missingPermissions.join(', ')}",
          timestamp: DateTime.now(),
        ));

        for (final permission in missingPermissions) {
          await phoneIntegrations.requestPermission(permission);
        }
      }

      _messageController.add(AgentMessage(
        id: _generateId(),
        agentId: id,
        type: MessageType.status,
        content: "Permission setup completed. Mobile agent ready for automation.",
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _messageController.add(AgentMessage(
        id: _generateId(),
        agentId: id,
        type: MessageType.error,
        content: "Failed to setup permissions: $e",
        timestamp: DateTime.now(),
      ));
    }
  }

  List<Task> _parseTasksFromResponse(String response) {
    try {
      // Extract JSON from LLM response
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
          type: taskData['type'] ?? 'mobile_control',
          description: taskData['description'] ?? 'No description',
          parameters: Map<String, dynamic>.from(taskData['parameters'] ?? {}),
          priority: TaskPriority.values.firstWhere(
            (p) => p.name == (taskData['priority'] ?? 'normal'),
            orElse: () => TaskPriority.normal,
          ),
        );
      }).toList();
    } catch (e) {
      // Fallback: create a single task from the response
      return [
        Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'mobile_control',
          description: 'Process user request: ${response.substring(0, 100)}...',
          parameters: {'objective': response},
        )
      ];
    }
  }

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void dispose() {
    _workflowSubscription?.cancel();
    workflowEngine.dispose();
    super.dispose();
  }

  static Future<MobileAgent> create({
    required String agentId,
    required Database database,
    required String modelPath,
    VLMInterface? vlm,
  }) async {
    final memory = await MemoryManager.create(database);

    // Initialize LLM
    final llm = FllamaLLMAdapter(modelPath: modelPath);
    await llm.initialize();

    // Create mobile tools
    final mobileController = MobileController(vlm: vlm);
    final accessibilityService = AccessibilityService();
    final screenRecorder = ScreenRecorder(vlm: vlm);
    final phoneIntegrations = PhoneIntegrations();

    final appAutomation = AppAutomationTool(
      mobileController: mobileController,
      vlm: vlm,
    );

    final workflowEngine = WorkflowEngine(
      llm: llm,
      mobileController: mobileController,
      appAutomation: appAutomation,
      accessibilityService: accessibilityService,
      screenRecorder: screenRecorder,
    );

    final tools = <Tool>[
      mobileController,
      appAutomation,
      accessibilityService,
      screenRecorder,
      workflowEngine,
      phoneIntegrations,
    ];

    return MobileAgent(
      id: agentId,
      name: 'Mobile Automation Agent',
      description: 'Private AI agent for autonomous mobile device control and app automation',
      tools: tools,
      memory: memory,
      llm: llm,
      mobileController: mobileController,
      appAutomation: appAutomation,
      accessibilityService: accessibilityService,
      screenRecorder: screenRecorder,
      workflowEngine: workflowEngine,
      phoneIntegrations: phoneIntegrations,
    );
  }
}