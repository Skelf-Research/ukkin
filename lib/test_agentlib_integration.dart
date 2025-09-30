import 'package:flutter/material.dart';
import 'package:agentlib/agentlib.dart';

/// Test file to demonstrate agentlib integration
class TestAgentLibIntegration extends StatefulWidget {
  const TestAgentLibIntegration({Key? key}) : super(key: key);

  @override
  State<TestAgentLibIntegration> createState() => _TestAgentLibIntegrationState();
}

class _TestAgentLibIntegrationState extends State<TestAgentLibIntegration> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AgentLib Integration Test')),
      body: Column(
        children: [
          // Example: Using AgentChatInterface from agentlib
          Expanded(
            child: AgentChatInterface(
              onMessageSent: (message) {
                print('Message sent: $message');
              },
              onVoiceCommand: (command) {
                print('Voice command: $command');
              },
            ),
          ),

          // Example: Creating an agent message
          ElevatedButton(
            onPressed: () {
              final message = AgentMessage.user('Hello from Ukkin!');
              print('Created message: ${message.id}');
            },
            child: const Text('Create Test Message'),
          ),

          // Example: Access agent registry
          ElevatedButton(
            onPressed: () {
              final agents = AgentRegistry.instance.getAllAgents();
              print('Active agents: ${agents.length}');
            },
            child: const Text('Check Active Agents'),
          ),
        ],
      ),
    );
  }
}