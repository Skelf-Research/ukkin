# API Reference

This document provides comprehensive API documentation for all Ukkin modules, including class definitions, method signatures, and usage examples.

## Core Services

### Agent System API

#### AgentCoordinator

Central coordination service for managing multiple AI agents and task delegation.

```dart
class AgentCoordinator {
  // Agent lifecycle management
  Future<void> registerAgent(Agent agent);
  Future<void> unregisterAgent(String agentId);
  List<Agent> getAvailableAgents();

  // Task delegation and execution
  Future<TaskResult> delegateTask(TaskRequest request);
  Future<void> pauseTask(String taskId);
  Future<void> resumeTask(String taskId);
  Future<void> cancelTask(String taskId);

  // Status monitoring
  Stream<TaskStatus> getTaskStatusStream();
  TaskStatus getTaskStatus(String taskId);
  List<TaskProgress> getActiveTasks();
}
```

#### MobileAgent

Primary conversational AI agent for general task processing and conversation management.

```dart
class MobileAgent extends Agent {
  // Conversation management
  Future<AgentMessage> processMessage(AgentMessage message);
  Future<void> startComplexWorkflow(String userRequest);
  Future<void> pauseCurrentWorkflow();
  Future<void> resumeCurrentWorkflow();

  // Capability assessment
  bool canHandleTask(String taskType);
  List<String> getSupportedCapabilities();

  // Event streams
  Stream<AgentMessage> get messageStream;
  Stream<TaskResult> get taskResultStream;
  Stream<WorkflowStatus> get workflowStatusStream;
}
```

#### TaskSession

Session management for maintaining conversation context and task state.

```dart
class TaskSession {
  // Session properties
  String get id;
  String get title;
  SessionStatus get status;
  DateTime get createdAt;
  Duration get duration;

  // Message management
  void addMessage(AgentMessage message);
  List<AgentMessage> get messages;
  AgentMessage? getLastMessage();

  // Task tracking
  void addTask(TaskProgress task);
  void updateTask(String taskId, TaskStatus status, {dynamic result, String? error});
  List<TaskProgress> get tasks;
  double get progressPercentage;

  // Objectives and context
  String? get currentObjective;
  set currentObjective(String? objective);
  Map<String, dynamic> get context;
  void updateContext(String key, dynamic value);
}
```

### Voice Processing API

#### VoiceInputService

Real-time voice recognition and processing service.

```dart
class VoiceInputService {
  // Voice recognition control
  Future<void> initialize();
  Future<void> startListening({
    String? language,
    Duration? timeout,
    bool partialResults = true,
  });
  Future<void> stopListening();
  bool get isListening;

  // Configuration
  Future<void> setLanguage(String languageCode);
  Future<void> setTimeout(Duration timeout);
  Future<void> setPartialResults(bool enabled);

  // Event streams
  Stream<String> get onResult;
  Stream<String> get onPartialResult;
  Stream<VoiceInputError> get onError;
  Stream<double> get onVolumeLevel;
}
```

#### VoiceChatWidget

Voice-enabled chat interface widget with conversation management.

```dart
class VoiceChatWidget extends StatefulWidget {
  const VoiceChatWidget({
    Key? key,
    required this.onMessageSent,
    this.onVoiceCommand,
    this.showVoiceButton = true,
    this.autoSendVoiceInput = true,
    this.enableWakeWord = false,
    this.placeholder = 'Type a message...',
  });

  // Callback functions
  final Function(String) onMessageSent;
  final Function(String)? onVoiceCommand;

  // Configuration options
  final bool showVoiceButton;
  final bool autoSendVoiceInput;
  final bool enableWakeWord;
  final String placeholder;
}
```

### Computer Vision API

#### VLMService

Computer vision and visual language model service for image analysis and screen understanding.

```dart
abstract class VLMInterface {
  // Core analysis methods
  Future<String> analyzeImage(String imagePath, {String? prompt});
  Future<VLMAnalysisResult> analyzeImageDetailed(String imagePath, {String? prompt});
  Future<List<VLMDetection>> detectObjects(String imagePath);
  Future<String> extractText(String imagePath);

  // Screen analysis
  Future<VLMScreenAnalysis> analyzeScreen(String screenshotPath);
  Future<List<VLMUIElement>> findUIElements(String imagePath, {String? elementType});
  Future<List<VLMAction>> suggestActions(String imagePath, {String? userIntent});

  // Accessibility analysis
  Future<List<VLMAccessibilityIssue>> analyzeAccessibility(String imagePath);
  Future<List<VLMFormField>> detectFormFields(String imagePath);
}

class VLMService implements VLMInterface {
  // Service lifecycle
  Future<void> initialize();
  void dispose();

  // Configuration
  Future<void> setModelPath(String path);
  Future<void> setAnalysisQuality(VLMQuality quality);
  Future<void> enableGPUAcceleration(bool enabled);
}
```

#### ScreenUnderstandingWidget

Widget for real-time screen analysis and UI element detection.

```dart
class ScreenUnderstandingWidget extends StatefulWidget {
  const ScreenUnderstandingWidget({
    Key? key,
    required this.child,
    this.onAnalysisComplete,
    this.onActionsDetected,
    this.enableRealTimeAnalysis = false,
    this.analysisInterval = const Duration(seconds: 5),
    this.showOverlay = false,
    this.enableAccessibilityCheck = true,
  });

  // Child widget to analyze
  final Widget child;

  // Callback functions
  final Function(VLMScreenAnalysis)? onAnalysisComplete;
  final Function(List<VLMAction>)? onActionsDetected;

  // Configuration options
  final bool enableRealTimeAnalysis;
  final Duration analysisInterval;
  final bool showOverlay;
  final bool enableAccessibilityCheck;

  // Public API
  Future<VLMScreenAnalysis?> analyzeScreen();
  Future<List<VLMUIElement>> findElementsByType(String elementType);
  Future<List<VLMAction>> suggestActionsForIntent(String userIntent);
}
```

### App Integration API

#### AppIntegrationService

Service for managing app integrations and cross-app automation.

```dart
class AppIntegrationService {
  // Service initialization
  Future<void> initialize();
  void dispose();

  // Integration management
  Future<bool> activateIntegration(String appId, {Map<String, dynamic>? config});
  Future<void> deactivateIntegration(String appId);
  bool isIntegrationActive(String appId);

  // Integration discovery
  List<AppIntegration> get availableIntegrations;
  List<AppIntegration> get installedIntegrations;
  List<AppIntegration> get activeIntegrations;

  // Action execution
  Future<IntegrationResult> executeAction(String appId, String action, Map<String, dynamic> parameters);

  // Specific integration methods
  Future<IntegrationResult> sendMessage(String appId, String recipient, String message, {String? messageType});
  Future<IntegrationResult> makeCall(String phoneNumber);
  Future<IntegrationResult> sendEmail(String to, String subject, String body, {List<String>? attachments});
  Future<IntegrationResult> createCalendarEvent(String title, DateTime startTime, DateTime endTime, {String? description, String? location});

  // Workflow execution
  Future<IntegrationResult> executeWorkflow(AppWorkflow workflow);

  // Smart suggestions
  Future<List<AppSuggestion>> getSmartSuggestions(String userInput, {String? context});
}
```

#### WorkflowBuilder

Service for creating and managing automation workflows.

```dart
class WorkflowBuilder {
  // Service initialization
  Future<void> initialize();

  // Workflow management
  Future<void> saveWorkflow(AppWorkflow workflow);
  Future<void> deleteWorkflow(String workflowId);
  List<AppWorkflow> get savedWorkflows;

  // Template management
  List<WorkflowTemplate> get templates;
  WorkflowTemplate? getTemplate(String templateId);

  // Workflow creation
  WorkflowEditor createWorkflow(String name, {String? description});
  WorkflowEditor editWorkflow(String workflowId);
  WorkflowEditor createFromTemplate(String templateId, Map<String, dynamic> parameters);

  // Execution
  Future<IntegrationResult> executeWorkflow(String workflowId, {Map<String, dynamic>? parameters});

  // Smart suggestions
  Future<List<WorkflowSuggestion>> getWorkflowSuggestions(String userInput, {String? context});
}
```

#### WorkflowEditor

Fluent interface for building and editing workflows.

```dart
class WorkflowEditor {
  // Step management
  WorkflowEditor addStep(String appId, String action, Map<String, dynamic> parameters, {bool required = true});
  WorkflowEditor removeStep(String stepId);
  WorkflowEditor updateStep(String stepId, {String? appId, String? action, Map<String, dynamic>? parameters, bool? required});
  WorkflowEditor reorderSteps(List<String> stepIds);

  // Workflow operations
  Future<AppWorkflow> save();
  Future<IntegrationResult> test();
}
```

### Platform Optimization API

#### PlatformManager

Central platform optimization and configuration management.

```dart
class PlatformManager {
  // Service initialization
  Future<void> initialize();
  void dispose();

  // Optimization control
  Future<void> setOptimizationLevel(OptimizationLevel level);

  // Platform-specific actions
  Future<void> enablePictureInPicture();
  Future<void> addShortcut(String id, String label, String intent);
  Future<void> updateWidget(String widgetId, Map<String, dynamic> data);

  // Diagnostics
  Future<PlatformDiagnostics> getDiagnostics();

  // Component access
  PerformanceOptimizer get performanceOptimizer;
  NetworkOptimizer get networkOptimizer;
  PlatformConfiguration get configuration;
  bool get isInitialized;
}
```

#### PerformanceOptimizer

Service for managing device performance and resource optimization.

```dart
class PerformanceOptimizer {
  // Service initialization
  Future<void> initialize();
  void dispose();

  // Performance events
  Future<void> onMemoryPressure();
  Future<void> onBatteryLow();
  Future<void> onBatteryOkay();

  // Settings management
  Future<void> setLowMemoryMode(bool enabled);
  Future<void> setBatteryOptimization(bool enabled);
  Future<void> setNetworkOptimization(bool enabled);
  Future<void> setBackgroundProcessing(bool enabled);

  // Monitoring
  Future<Map<String, dynamic>> getPerformanceMetrics();
  Future<Map<String, dynamic>> getMemoryUsage();
  Future<double> getBatteryLevel();
  Future<bool> isLowPowerModeEnabled();

  // Configuration properties
  bool get lowMemoryMode;
  bool get batteryOptimizationEnabled;
  bool get networkOptimizationEnabled;
  bool get backgroundProcessingEnabled;
}
```

#### NetworkOptimizer

Service for managing network performance and data usage optimization.

```dart
class NetworkOptimizer {
  // Service initialization
  Future<void> initialize();
  void dispose();

  // Settings management
  Future<void> setCompressionEnabled(bool enabled);
  Future<void> setCachingEnabled(bool enabled);
  Future<void> setPrefetchingEnabled(bool enabled);
  Future<void> setBatteryAwareNetworking(bool enabled);
  Future<void> setMaxConcurrentRequests(int count);
  Future<void> setRequestTimeout(Duration timeout);
  Future<void> setRetryAttempts(int attempts);

  // Network monitoring
  Stream<NetworkState> get networkStateStream;
  NetworkConnectionType get connectionType;
  NetworkSpeed get networkSpeed;
  bool get isMeteredConnection;

  // Diagnostics
  Future<NetworkDiagnostics> runNetworkDiagnostics();
  Future<double> measureLatency(String host);
  Future<double> measureBandwidth();

  // Configuration properties
  bool get compressionEnabled;
  bool get cachingEnabled;
  bool get prefetchingEnabled;
  bool get batteryAwareNetworking;
  Duration get requestTimeout;
  int get maxConcurrentRequests;
  int get retryAttempts;
}
```

## Data Models

### Core Models

#### AgentMessage

Message structure for agent communication.

```dart
class AgentMessage {
  final String id;
  final String agentId;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final List<MessageAttachment>? attachments;

  // Message types
  enum MessageType {
    user,
    assistant,
    system,
    error,
    status,
  }
}
```

#### TaskProgress

Task execution progress and status tracking.

```dart
class TaskProgress {
  final String id;
  final String description;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double progressPercentage;
  final dynamic result;
  final String? error;
  final Map<String, dynamic> metadata;

  // Task status enumeration
  enum TaskStatus {
    pending,
    running,
    completed,
    failed,
    cancelled,
  }
}
```

### VLM Models

#### VLMAnalysisResult

Comprehensive image analysis result.

```dart
class VLMAnalysisResult {
  final String description;
  final List<VLMDetection> detectedObjects;
  final String extractedText;
  final double confidence;
  final Map<String, dynamic> metadata;
  final List<VLMCaption> captions;
  final VLMSemanticAnalysis? semanticAnalysis;
}
```

#### VLMScreenAnalysis

Screen understanding and analysis result.

```dart
class VLMScreenAnalysis {
  final List<VLMUIElement> uiElements;
  final List<VLMAction> suggestedActions;
  final String extractedText;
  final VLMAccessibilityReport? accessibilityReport;
  final Map<String, dynamic> screenContext;
  final double analysisConfidence;
}
```

### Integration Models

#### AppWorkflow

Workflow definition for app automation.

```dart
class AppWorkflow {
  final String id;
  final String name;
  final List<WorkflowStep> steps;
  final Map<String, dynamic> _stepResults;

  // Step result management
  void setStepResult(String stepId, Map<String, dynamic> result);
  Map<String, dynamic>? getStepResult(String stepId);

  // Parameter substitution
  void substituteParameters(Map<String, dynamic> parameters);

  // Serialization
  Map<String, dynamic> toJson();
  static AppWorkflow fromJson(Map<String, dynamic> json);
}
```

#### IntegrationResult

Result of app integration action execution.

```dart
class IntegrationResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
  final String? error;

  // Factory constructors
  IntegrationResult.success(this.data, {this.message});
  IntegrationResult.error(this.error, {this.message});
}
```

### Platform Models

#### PlatformDiagnostics

Comprehensive platform and performance diagnostics.

```dart
class PlatformDiagnostics {
  final String platform;
  final String version;
  final Map<String, dynamic> performanceMetrics;
  final Map<String, dynamic> memoryUsage;
  final double batteryLevel;
  final NetworkDiagnostics networkDiagnostics;
  final PlatformConfiguration configuration;
}
```

#### NetworkState

Current network connection state and characteristics.

```dart
class NetworkState {
  final bool isConnected;
  final NetworkConnectionType connectionType;
  final bool isMetered;
  final NetworkSpeed speed;

  // Connection type enumeration
  enum NetworkConnectionType {
    wifi,
    cellular,
    ethernet,
    none,
    unknown,
  }

  // Network speed enumeration
  enum NetworkSpeed {
    slow,
    moderate,
    fast,
    unknown,
  }
}
```

## Error Handling

### Exception Types

All services use standardized exception types for consistent error handling:

```dart
// Service initialization errors
class ServiceInitializationException implements Exception {
  final String service;
  final String message;
  final dynamic cause;
}

// Integration errors
class IntegrationException implements Exception {
  final String appId;
  final String action;
  final String message;
  final dynamic cause;
}

// VLM processing errors
class VLMProcessingException implements Exception {
  final String operation;
  final String message;
  final dynamic cause;
}

// Platform optimization errors
class PlatformOptimizationException implements Exception {
  final String feature;
  final String message;
  final dynamic cause;
}
```

### Error Handling Patterns

Services follow consistent error handling patterns:

1. **Graceful Degradation**: Services continue operation with reduced functionality when possible
2. **Error Recovery**: Automatic retry mechanisms for transient failures
3. **User Notification**: Clear error messages with actionable guidance
4. **Logging**: Comprehensive error logging for debugging and monitoring

## Usage Examples

### Basic Agent Interaction

```dart
// Initialize and use the mobile agent
final agent = MobileAgent();
await agent.initialize();

// Send a message and get response
final userMessage = AgentMessage(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  agentId: 'user',
  type: MessageType.user,
  content: 'Help me schedule a meeting for tomorrow',
);

final response = await agent.processMessage(userMessage);
print('Agent response: ${response.content}');
```

### Voice Input Integration

```dart
// Initialize voice service
final voiceService = VoiceInputService();
await voiceService.initialize();

// Listen for voice input
voiceService.onResult.listen((result) {
  print('Voice input received: $result');
  // Process voice command
});

// Start listening
await voiceService.startListening(
  language: 'en-US',
  timeout: Duration(seconds: 30),
);
```

### VLM Image Analysis

```dart
// Initialize VLM service
final vlmService = VLMService();
await vlmService.initialize();

// Analyze an image
final analysisResult = await vlmService.analyzeImageDetailed(imagePath);
print('Image description: ${analysisResult.description}');
print('Detected objects: ${analysisResult.detectedObjects.length}');
print('Extracted text: ${analysisResult.extractedText}');
```

### Workflow Creation and Execution

```dart
// Create a workflow
final workflowBuilder = WorkflowBuilder.instance;
final editor = workflowBuilder.createWorkflow('Morning Routine');

// Add workflow steps
editor
  .addStep('weather', 'getWeather', {'location': 'current'})
  .addStep('calendar', 'getEvents', {'date': 'today'})
  .addStep('music', 'play', {'query': 'morning playlist'});

// Save and execute
final workflow = await editor.save();
final result = await workflowBuilder.executeWorkflow(workflow.id);

if (result.success) {
  print('Workflow completed successfully');
} else {
  print('Workflow failed: ${result.error}');
}
```

This API reference provides the foundation for extending Ukkin's capabilities and integrating with external systems while maintaining consistency and reliability across all platform features.