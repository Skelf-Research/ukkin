# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Core Flutter Commands
- **Build and run**: `flutter run` - Launches the app in development mode
- **Analyze code**: `dart analyze` - Static analysis (expect ~1000 issues, focus on critical errors only)
- **Install dependencies**: `flutter pub get` - Install all packages
- **Clean project**: `flutter clean` - Reset build cache when dependencies change

### Testing and Quality
- **Run tests**: `flutter test` - Execute unit and widget tests
- **Lint check**: `flutter analyze --suppress-analytics` - Quick error check without telemetry
- **Critical errors only**: `dart analyze lib/ui/conversational_agent_builder.dart` - Check specific files

### Platform-Specific Development
- **Android**: Requires ANDROID_HOME environment variable set
- **iOS**: Minimum deployment target iOS 11.0, configure Info.plist permissions

## Architecture Overview

### Multi-Package Architecture
This project uses a sophisticated multi-package architecture:

1. **Main App (ukkin/)**: Flutter UI application consuming AgentLib
2. **AgentLib Package (../agentlib/)**: Standalone SDK for mobile AI agents
   - Local dependency: `path: ../agentlib` in pubspec.yaml
   - Provides agent creation, scheduling, and automation capabilities
   - Can be extracted as a standalone pub.dev package

### Core System Design

**AgentLib Integration Pattern**:
```dart
// Main app initialization pattern
final initResult = await QuickStart.initialize(
  mode: QuickStartMode.development,
  databaseName: 'ukkin',
);

final agentId = await QuickStart.createMobileAssistant(
  name: 'Ukkin AI Assistant',
  supportedApps: [...],
  requireConfirmation: true,
);
```

**Agent System Architecture**:
- **RepetitiveTaskAgent**: Base class for background automation agents
- **TaskScheduler**: Centralized agent coordination and execution
- **AppPluginSystem**: Modular app integration framework
- **ConversationalAgentBuilder**: Natural language agent creation interface

### Key Architectural Components

**Multi-Agent Coordination**:
- AgentLib provides base classes: `Agent`, `RepetitiveTaskAgent`, `TaskAgent`
- Specialized agents: `InstagramWatcherAgent`, `EmailTriageAgent`, `PriceWatcherAgent`
- Task scheduling with device condition awareness (battery, network, time)

**Conversational Agent Creation**:
- Multi-stage conversation flow: introduction → requirements → clarification → confirmation
- AI-powered flow extraction from natural language
- Real-time flow editing through chat commands
- Integration with existing agent templates

**UI Architecture**:
- Bottom navigation: Chat interface + Agent Dashboard
- Material Design 3 with custom theming
- Modal workflows for complex operations (agent setup, flow preview)
- Responsive design optimized for mobile-first experience

### Agent Creation Patterns

**Template-Based Agents** (via AgentSetupWizard):
```dart
// Multi-step wizard for predefined agent types
switch (agentType) {
  case AgentType.socialMedia: return _buildSocialMediaPages(); // 6 steps
  case AgentType.communication: return _buildCommunicationPages(); // 7 steps
  case AgentType.shopping: return _buildShoppingPages(); // 7 steps
}
```

**Conversational Agents** (via ConversationalAgentBuilder):
```dart
// Natural language to agent flow conversion
final flow = _generateFlowFromConversation();
await _createActualAgent(flow); // Creates real AgentLib agents
```

### Data Flow Architecture

**Agent Lifecycle**:
1. User creates agent (via wizard or conversation)
2. Agent registration with TaskScheduler
3. Background execution based on schedule/conditions
4. Results notification and dashboard updates

**Key Import Patterns**:
```dart
// Handle AgentLib type conflicts
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:agentlib/agentlib.dart' hide TaskResult;
import 'package:agentlib/src/agents/repetitive_task_agent.dart' show TaskResult;
```

## Development Considerations

### Critical Integration Points
- **AgentLib Dependency**: All agent functionality depends on ../agentlib package
- **Type Conflicts**: TimeOfDay and TaskResult exist in both Flutter and AgentLib
- **Agent Constructors**: Use exact parameter names from AgentLib agent classes

### Error Handling Strategy
- **Expected State**: ~1000 analysis issues (mostly deprecation warnings)
- **Critical Focus**: Only fix actual runtime errors and type mismatches
- **AgentLib Integration**: Proper error handling required for agent creation failures

### Mobile-Specific Patterns
- **Accessibility Services**: Required for app automation capabilities
- **Background Processing**: Agents run as background services with proper lifecycle management
- **Permission Management**: Granular app integration permissions through Android/iOS native channels

### Code Organization
- **lib/ui/**: Core UI components (4 main files: dashboard, detail, wizard, conversational builder)
- **lib/agent/**: Legacy agent implementation (being migrated to AgentLib)
- **lib/voice/**: Voice interaction and speech processing
- **lib/vlm/**: Computer vision and visual processing
- **lib/integrations/**: App-specific automation modules

### Performance Considerations
- **On-Device Processing**: All AI computation happens locally
- **Memory Management**: Aggressive optimization for mobile constraints
- **Battery Awareness**: Agent scheduling considers device power state
- **Network Intelligence**: Adaptive behavior based on connection quality

## Important Development Notes

### Agent Creation Integration
The conversational agent builder represents the most complex integration point:
- Parses natural language into structured agent configurations
- Maps conversation requirements to AgentLib constructor parameters
- Handles all agent types: social media, communication, shopping, custom
- Provides real-time flow editing and preview capabilities

### Testing Approach
- Focus on UI components and conversation flow logic
- AgentLib integration testing requires device/simulator with proper permissions
- Mock agent creation for unit tests, integration tests for E2E flows

### Deployment Considerations
- Requires platform-specific permission setup for app automation
- AgentLib package must be publishable to pub.dev for wider distribution
- Mobile-first optimization with careful attention to performance constraints