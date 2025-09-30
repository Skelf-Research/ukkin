import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'core/agent.dart';
import 'models/task.dart';
import 'models/agent_message.dart';
import 'tools/tool.dart';
import 'tools/web_browser_tool.dart';
import 'tools/search_tool.dart';
import 'tools/vision_tool.dart';
import 'memory/memory_manager.dart';
import 'llm/llm_interface.dart';
import 'llm/fllama_adapter.dart';
import 'coordination/agent_coordinator.dart';
import 'planning/task_planner.dart';

class AgentFactory {
  final Database database;
  final String modelsPath;

  AgentFactory({
    required this.database,
    required this.modelsPath,
  });

  Future<AutonomousAgent> createWebBrowsingAgent({
    String? agentId,
    String? modelPath,
    WebViewController? webViewController,
  }) async {
    final id = agentId ?? 'web_agent_${DateTime.now().millisecondsSinceEpoch}';
    final memory = await MemoryManager.create(database);

    // Initialize LLM
    final llm = FllamaLLMAdapter(
      modelPath: modelPath ?? '$modelsPath/stablelm-2-zephyr-1_6b-q4_0.gguf',
    );
    await llm.initialize();

    // Create tools
    final tools = <Tool>[
      WebBrowserTool(webViewController: webViewController),
      SearchTool(),
      VisionTool(),
    ];

    return AutonomousAgent(
      id: id,
      name: 'Web Browsing Agent',
      description: 'Specialized agent for web browsing, content extraction, and online research',
      tools: tools,
      memory: memory,
      llm: llm,
    );
  }

  Future<AutonomousAgent> createResearchAgent({
    String? agentId,
    String? modelPath,
  }) async {
    final id = agentId ?? 'research_agent_${DateTime.now().millisecondsSinceEpoch}';
    final memory = await MemoryManager.create(database);

    // Initialize LLM
    final llm = FllamaLLMAdapter(
      modelPath: modelPath ?? '$modelsPath/stablelm-2-zephyr-1_6b-q4_0.gguf',
    );
    await llm.initialize();

    // Create tools focused on research
    final tools = <Tool>[
      SearchTool(),
      WebBrowserTool(),
      VisionTool(),
    ];

    return AutonomousAgent(
      id: id,
      name: 'Research Agent',
      description: 'Specialized agent for information gathering, research, and data analysis',
      tools: tools,
      memory: memory,
      llm: llm,
    );
  }

  Future<AutonomousAgent> createGeneralAgent({
    String? agentId,
    String? modelPath,
    List<Tool>? additionalTools,
    WebViewController? webViewController,
  }) async {
    final id = agentId ?? 'general_agent_${DateTime.now().millisecondsSinceEpoch}';
    final memory = await MemoryManager.create(database);

    // Initialize LLM
    final llm = FllamaLLMAdapter(
      modelPath: modelPath ?? '$modelsPath/stablelm-2-zephyr-1_6b-q4_0.gguf',
    );
    await llm.initialize();

    // Create comprehensive tool set
    final tools = <Tool>[
      WebBrowserTool(webViewController: webViewController),
      SearchTool(),
      VisionTool(),
      ...?additionalTools,
    ];

    return AutonomousAgent(
      id: id,
      name: 'General Purpose Agent',
      description: 'Versatile agent capable of handling various tasks including web browsing, research, and general assistance',
      tools: tools,
      memory: memory,
      llm: llm,
    );
  }

  Future<AutonomousAgent> createVisionAgent({
    String? agentId,
    String? modelPath,
    String? vlmModelPath,
  }) async {
    final id = agentId ?? 'vision_agent_${DateTime.now().millisecondsSinceEpoch}';
    final memory = await MemoryManager.create(database);

    // Initialize LLM
    final llm = FllamaLLMAdapter(
      modelPath: modelPath ?? '$modelsPath/stablelm-2-zephyr-1_6b-q4_0.gguf',
    );
    await llm.initialize();

    // Initialize VLM if available
    VLMInterface? vlm;
    if (vlmModelPath != null && await File(vlmModelPath).exists()) {
      vlm = FllamaVLMAdapter(modelPath: vlmModelPath);
      await vlm.initialize();
    }

    // Create tools with vision capabilities
    final tools = <Tool>[
      VisionTool(vlm: vlm),
      WebBrowserTool(),
      SearchTool(),
    ];

    return AutonomousAgent(
      id: id,
      name: 'Vision Agent',
      description: 'Specialized agent for visual understanding, image analysis, and UI interaction',
      tools: tools,
      memory: memory,
      llm: llm,
    );
  }

  Future<AgentCoordinator> createCoordinator() async {
    return AgentCoordinator();
  }

  Future<List<AutonomousAgent>> createAgentTeam({
    WebViewController? webViewController,
    String? baseModelPath,
  }) async {
    final agents = <AutonomousAgent>[];

    // Create specialized agents for different tasks
    agents.add(await createWebBrowsingAgent(
      agentId: 'team_web_agent',
      modelPath: baseModelPath,
      webViewController: webViewController,
    ));

    agents.add(await createResearchAgent(
      agentId: 'team_research_agent',
      modelPath: baseModelPath,
    ));

    agents.add(await createVisionAgent(
      agentId: 'team_vision_agent',
      modelPath: baseModelPath,
    ));

    return agents;
  }

  Future<bool> isModelAvailable(String modelPath) async {
    return await File(modelPath).exists();
  }

  Future<List<String>> getAvailableModels() async {
    final modelsDir = Directory(modelsPath);
    if (!await modelsDir.exists()) {
      return [];
    }

    final files = await modelsDir.list().toList();
    return files
        .where((file) => file is File && file.path.endsWith('.gguf'))
        .map((file) => file.path)
        .toList();
  }

  Future<Map<String, dynamic>> getModelInfo(String modelPath) async {
    final file = File(modelPath);
    if (!await file.exists()) {
      return {'exists': false};
    }

    final stat = await file.stat();
    return {
      'exists': true,
      'path': modelPath,
      'size': stat.size,
      'modified': stat.modified.toIso8601String(),
      'name': file.path.split('/').last,
    };
  }

  static Future<AgentFactory> create({
    required Database database,
    String? modelsPath,
  }) async {
    final defaultModelsPath = modelsPath ?? await _getDefaultModelsPath();

    // Ensure models directory exists
    final modelsDir = Directory(defaultModelsPath);
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    return AgentFactory(
      database: database,
      modelsPath: defaultModelsPath,
    );
  }

  static Future<String> _getDefaultModelsPath() async {
    // TODO: Implement platform-specific model paths
    return '/data/data/com.example.ukkin/files/models';
  }

  void dispose() {
    // Cleanup if needed
  }
}

class AgentManager {
  final AgentFactory factory;
  final AgentCoordinator coordinator;
  final Map<String, AutonomousAgent> _activeAgents = {};

  AgentManager({
    required this.factory,
    required this.coordinator,
  });

  Future<AutonomousAgent> getOrCreateAgent(String type, {
    String? agentId,
    Map<String, dynamic>? options,
  }) async {
    final id = agentId ?? '${type}_${DateTime.now().millisecondsSinceEpoch}';

    if (_activeAgents.containsKey(id)) {
      return _activeAgents[id]!;
    }

    AutonomousAgent agent;
    switch (type) {
      case 'web':
        agent = await factory.createWebBrowsingAgent(
          agentId: id,
          webViewController: options?['webViewController'],
        );
        break;
      case 'research':
        agent = await factory.createResearchAgent(agentId: id);
        break;
      case 'vision':
        agent = await factory.createVisionAgent(agentId: id);
        break;
      case 'general':
      default:
        agent = await factory.createGeneralAgent(
          agentId: id,
          webViewController: options?['webViewController'],
        );
        break;
    }

    _activeAgents[id] = agent;
    coordinator.registerAgent(agent);

    return agent;
  }

  void removeAgent(String agentId) {
    final agent = _activeAgents.remove(agentId);
    if (agent != null) {
      coordinator.unregisterAgent(agentId);
      agent.dispose();
    }
  }

  List<AutonomousAgent> getActiveAgents() {
    return _activeAgents.values.toList();
  }

  AutonomousAgent? getAgent(String agentId) {
    return _activeAgents[agentId];
  }

  Future<void> disposeAll() async {
    for (final agent in _activeAgents.values) {
      agent.dispose();
    }
    _activeAgents.clear();
    coordinator.dispose();
    factory.dispose();
  }

  static Future<AgentManager> create({
    required Database database,
    String? modelsPath,
  }) async {
    final factory = await AgentFactory.create(
      database: database,
      modelsPath: modelsPath,
    );

    final coordinator = await factory.createCoordinator();

    return AgentManager(
      factory: factory,
      coordinator: coordinator,
    );
  }
}