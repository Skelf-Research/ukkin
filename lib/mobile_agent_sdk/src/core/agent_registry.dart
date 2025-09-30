import 'dart:async';
import 'dart:collection';

import 'agent.dart';
import '../models/agent_message.dart';
import '../models/task_request.dart';
import '../utils/logger.dart';

/// Registry for managing available agents and their capabilities
class AgentRegistry {
  static AgentRegistry? _instance;
  static AgentRegistry get instance => _instance ??= AgentRegistry._();

  AgentRegistry._();

  final Map<String, Agent> _agents = <String, Agent>{};
  final Map<String, Set<String>> _capabilityIndex = <String, Set<String>>{};
  final StreamController<AgentRegistryEvent> _eventController =
      StreamController<AgentRegistryEvent>.broadcast();

  bool _initialized = false;

  /// Stream of registry events (agent added, removed, etc.)
  Stream<AgentRegistryEvent> get events => _eventController.stream;

  /// Initialize the agent registry
  Future<void> initialize() async {
    if (_initialized) return;

    Logger.info('Initializing Agent Registry');

    // Register default agents
    await _registerDefaultAgents();

    _initialized = true;
    Logger.info('Agent Registry initialized with ${_agents.length} agents');
  }

  /// Shutdown the registry and cleanup resources
  Future<void> shutdown() async {
    if (!_initialized) return;

    Logger.info('Shutting down Agent Registry');

    // Shutdown all agents
    for (final agent in _agents.values) {
      try {
        await agent.shutdown();
      } catch (e) {
        Logger.warning('Error shutting down agent ${agent.id}', error: e);
      }
    }

    _agents.clear();
    _capabilityIndex.clear();
    await _eventController.close();

    _initialized = false;
  }

  /// Register a new agent
  Future<void> registerAgent(Agent agent) async {
    if (!_initialized) {
      throw StateError('Agent Registry not initialized');
    }

    if (_agents.containsKey(agent.id)) {
      throw ArgumentError('Agent with id ${agent.id} already registered');
    }

    Logger.info('Registering agent: ${agent.id}');

    // Initialize the agent
    await agent.initialize();

    // Add to registry
    _agents[agent.id] = agent;

    // Update capability index
    for (final capability in agent.capabilities) {
      _capabilityIndex.putIfAbsent(capability, () => <String>{});
      _capabilityIndex[capability]!.add(agent.id);
    }

    // Notify listeners
    _eventController.add(AgentRegistryEvent.agentAdded(agent.id));

    Logger.info('Agent ${agent.id} registered successfully');
  }

  /// Unregister an agent
  Future<void> unregisterAgent(String agentId) async {
    if (!_initialized) {
      throw StateError('Agent Registry not initialized');
    }

    final agent = _agents[agentId];
    if (agent == null) {
      Logger.warning('Attempted to unregister unknown agent: $agentId');
      return;
    }

    Logger.info('Unregistering agent: $agentId');

    // Remove from capability index
    for (final capability in agent.capabilities) {
      _capabilityIndex[capability]?.remove(agentId);
      if (_capabilityIndex[capability]?.isEmpty == true) {
        _capabilityIndex.remove(capability);
      }
    }

    // Shutdown and remove agent
    await agent.shutdown();
    _agents.remove(agentId);

    // Notify listeners
    _eventController.add(AgentRegistryEvent.agentRemoved(agentId));

    Logger.info('Agent $agentId unregistered successfully');
  }

  /// Get all registered agents
  List<Agent> getAllAgents() {
    return List.unmodifiable(_agents.values);
  }

  /// Get agent by ID
  Agent? getAgent(String agentId) {
    return _agents[agentId];
  }

  /// Find agents with specific capability
  List<Agent> getAgentsWithCapability(String capability) {
    final agentIds = _capabilityIndex[capability] ?? <String>{};
    return agentIds
        .map((id) => _agents[id])
        .where((agent) => agent != null)
        .cast<Agent>()
        .toList();
  }

  /// Find the best agent for a specific task
  Agent? findBestAgentForTask(TaskRequest request) {
    final candidates = getAgentsWithCapability(request.taskType);

    if (candidates.isEmpty) {
      Logger.warning('No agents found for task type: ${request.taskType}');
      return null;
    }

    // For now, return the first capable agent
    // In the future, this could use more sophisticated selection logic
    for (final agent in candidates) {
      if (agent.canHandleTask(request.taskType)) {
        return agent;
      }
    }

    return null;
  }

  /// Find agents that can handle a message
  List<Agent> findAgentsForMessage(AgentMessage message) {
    final allAgents = getAllAgents();
    final capableAgents = <Agent>[];

    for (final agent in allAgents) {
      if (agent.canHandleMessage(message)) {
        capableAgents.add(agent);
      }
    }

    return capableAgents;
  }

  /// Get all available capabilities
  Set<String> getAllCapabilities() {
    return Set.unmodifiable(_capabilityIndex.keys);
  }

  /// Get agent statistics
  AgentRegistryStats getStats() {
    return AgentRegistryStats(
      totalAgents: _agents.length,
      totalCapabilities: _capabilityIndex.length,
      agentsByCapability: Map.fromEntries(
        _capabilityIndex.entries.map(
          (entry) => MapEntry(entry.key, entry.value.length),
        ),
      ),
    );
  }

  /// Check if registry is initialized
  bool get isInitialized => _initialized;

  /// Register default agents that come with the SDK
  Future<void> _registerDefaultAgents() async {
    // Register core conversation agent
    await registerAgent(ConversationAgent());

    // Register task coordination agent
    await registerAgent(TaskCoordinationAgent());

    // Add other default agents as needed
  }
}

/// Statistics about the agent registry
class AgentRegistryStats {
  final int totalAgents;
  final int totalCapabilities;
  final Map<String, int> agentsByCapability;

  const AgentRegistryStats({
    required this.totalAgents,
    required this.totalCapabilities,
    required this.agentsByCapability,
  });

  @override
  String toString() {
    return 'AgentRegistryStats(agents: $totalAgents, capabilities: $totalCapabilities)';
  }
}

/// Events emitted by the agent registry
class AgentRegistryEvent {
  final AgentRegistryEventType type;
  final String agentId;
  final DateTime timestamp;

  const AgentRegistryEvent._({
    required this.type,
    required this.agentId,
    required this.timestamp,
  });

  factory AgentRegistryEvent.agentAdded(String agentId) {
    return AgentRegistryEvent._(
      type: AgentRegistryEventType.agentAdded,
      agentId: agentId,
      timestamp: DateTime.now(),
    );
  }

  factory AgentRegistryEvent.agentRemoved(String agentId) {
    return AgentRegistryEvent._(
      type: AgentRegistryEventType.agentRemoved,
      agentId: agentId,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AgentRegistryEvent(type: $type, agentId: $agentId, timestamp: $timestamp)';
  }
}

/// Types of agent registry events
enum AgentRegistryEventType {
  agentAdded,
  agentRemoved,
}

/// Default conversation agent for basic chat functionality
class ConversationAgent extends Agent {
  @override
  String get id => 'conversation_agent';

  @override
  String get name => 'Conversation Agent';

  @override
  List<String> get capabilities => ['conversation', 'chat', 'general_query'];

  @override
  Future<void> initialize() async {
    Logger.info('Initializing Conversation Agent');
  }

  @override
  Future<AgentMessage> processMessage(AgentMessage message) async {
    // Basic echo response for now
    return AgentMessage.response(
      'I received your message: ${message.content}',
      agentId: id,
    );
  }

  @override
  bool canHandleTask(String taskType) {
    return capabilities.contains(taskType);
  }

  @override
  bool canHandleMessage(AgentMessage message) {
    return message.type == MessageType.user;
  }

  @override
  Future<void> shutdown() async {
    Logger.info('Shutting down Conversation Agent');
  }
}

/// Default task coordination agent for managing complex tasks
class TaskCoordinationAgent extends Agent {
  @override
  String get id => 'task_coordination_agent';

  @override
  String get name => 'Task Coordination Agent';

  @override
  List<String> get capabilities => ['task_coordination', 'workflow', 'planning'];

  @override
  Future<void> initialize() async {
    Logger.info('Initializing Task Coordination Agent');
  }

  @override
  Future<AgentMessage> processMessage(AgentMessage message) async {
    // Handle task coordination messages
    return AgentMessage.response(
      'Task coordination response for: ${message.content}',
      agentId: id,
    );
  }

  @override
  bool canHandleTask(String taskType) {
    return capabilities.contains(taskType);
  }

  @override
  bool canHandleMessage(AgentMessage message) {
    return message.type == MessageType.user || message.type == MessageType.system;
  }

  @override
  Future<void> shutdown() async {
    Logger.info('Shutting down Task Coordination Agent');
  }
}