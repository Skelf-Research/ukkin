import 'package:flutter/material.dart';
import 'package:agentlib/agentlib.dart';

/// Demo showcasing AgentLib's enhanced capabilities
class AgentLibDemo extends StatefulWidget {
  const AgentLibDemo({Key? key}) : super(key: key);

  @override
  State<AgentLibDemo> createState() => _AgentLibDemoState();
}

class _AgentLibDemoState extends State<AgentLibDemo> {
  String _status = 'Not initialized';
  List<String> _deployedAgents = [];
  List<String> _demoLogs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AgentLib Enhanced Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: $_status', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Deployed Agents: ${_deployedAgents.length}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Actions
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _initializeAgentLib,
                  child: const Text('Initialize AgentLib'),
                ),
                ElevatedButton(
                  onPressed: _deployChatBot,
                  child: const Text('Deploy ChatBot'),
                ),
                ElevatedButton(
                  onPressed: _deployMobileAssistant,
                  child: const Text('Deploy Mobile Assistant'),
                ),
                ElevatedButton(
                  onPressed: _deployMultiAgentSystem,
                  child: const Text('Deploy Multi-Agent'),
                ),
                ElevatedButton(
                  onPressed: _createWorkflow,
                  child: const Text('Create Workflow'),
                ),
                ElevatedButton(
                  onPressed: _runExampleWorkflow,
                  child: const Text('Run Example Workflow'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Logs Section
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Demo Logs', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _demoLogs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                _demoLogs[index],
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Initialize AgentLib with smart defaults
  Future<void> _initializeAgentLib() async {
    _addLog('Initializing AgentLib...');

    try {
      final result = await QuickStart.initialize(
        mode: QuickStartMode.development,
        databaseName: 'demo_agents',
      );

      if (result.success) {
        setState(() {
          _status = 'Initialized';
        });
        _addLog('✅ AgentLib initialized successfully');
      } else {
        _addLog('❌ Initialization failed: ${result.error}');
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    }
  }

  /// Deploy a simple chatbot
  Future<void> _deployChatBot() async {
    _addLog('Deploying ChatBot...');

    try {
      final agentId = await QuickStart.createChatBot(
        name: 'Demo ChatBot',
        personality: 'friendly',
        capabilities: ['conversation', 'help', 'jokes'],
      );

      setState(() {
        _deployedAgents.add(agentId);
      });

      _addLog('✅ ChatBot deployed: $agentId');
    } catch (e) {
      _addLog('❌ ChatBot deployment failed: $e');
    }
  }

  /// Deploy a mobile assistant
  Future<void> _deployMobileAssistant() async {
    _addLog('Deploying Mobile Assistant...');

    try {
      final agentId = await QuickStart.createMobileAssistant(
        name: 'Demo Mobile Assistant',
        supportedApps: ['com.whatsapp', 'com.google.android.gm'],
        requireConfirmation: true,
      );

      setState(() {
        _deployedAgents.add(agentId);
      });

      _addLog('✅ Mobile Assistant deployed: $agentId');
    } catch (e) {
      _addLog('❌ Mobile Assistant deployment failed: $e');
    }
  }

  /// Deploy a multi-agent system
  Future<void> _deployMultiAgentSystem() async {
    _addLog('Deploying Multi-Agent System...');

    try {
      final agentIds = await QuickStart.createMultiAgentSystem(
        coordinatorName: 'Demo Coordinator',
        specializations: ['conversation', 'mobile', 'analysis'],
      );

      setState(() {
        _deployedAgents.addAll(agentIds);
      });

      _addLog('✅ Multi-Agent System deployed: ${agentIds.length} agents');
      for (final id in agentIds) {
        _addLog('  - Agent: $id');
      }
    } catch (e) {
      _addLog('❌ Multi-Agent deployment failed: $e');
    }
  }

  /// Create a simple workflow
  Future<void> _createWorkflow() async {
    _addLog('Creating demo workflow...');

    try {
      final workflow = QuickStart.createWorkflow('Demo Workflow')
          .addNotification(
            message: 'Workflow started!',
            type: NotificationType.info,
          )
          .addWait(Duration(seconds: 2))
          .addTask(
            'demo_task',
            description: 'Execute demo task',
            parameters: {'action': 'process_demo_data'},
          )
          .addNotification(
            message: 'Workflow completed successfully!',
            type: NotificationType.success,
          )
          .build();

      _addLog('✅ Workflow created: ${workflow.name}');
      _addLog('  - Steps: ${workflow.steps.length}');
      _addLog('  - ID: ${workflow.id}');
    } catch (e) {
      _addLog('❌ Workflow creation failed: $e');
    }
  }

  /// Run an example workflow
  Future<void> _runExampleWorkflow() async {
    _addLog('Running example workflow...');

    try {
      final workflow = QuickStart.createNotificationWorkflow(
        message: 'Hello from AgentLib workflow!',
        type: NotificationType.success,
        delay: Duration(seconds: 1),
      );

      _addLog('🚀 Executing workflow: ${workflow.name}');

      final result = await workflow.execute({'demo_var': 'test_value'});

      if (result.success) {
        _addLog('✅ Workflow completed successfully');
        _addLog('  - Duration: ${result.duration.inMilliseconds}ms');
        _addLog('  - Steps executed: ${result.executionHistory.length}');
      } else {
        _addLog('❌ Workflow failed: ${result.error}');
      }
    } catch (e) {
      _addLog('❌ Workflow execution failed: $e');
    }
  }

  void _addLog(String message) {
    setState(() {
      _demoLogs.add('${DateTime.now().toIso8601String().substring(11, 19)}: $message');
    });
  }
}

/// Example of how easy it is to use AgentLib now
class AgentLibUsageExamples {
  /// One-line agent deployment
  static Future<void> oneLineDeployment() async {
    // Initialize and deploy a chatbot in just 2 lines!
    await QuickStart.initialize();
    final agentId = await QuickStart.createChatBot(name: 'My Assistant');
    print('Agent deployed: $agentId');
  }

  /// One-line workflow creation and execution
  static Future<void> oneLineWorkflow() async {
    // Create and run a workflow in just 2 lines!
    final workflow = QuickStart.createNotificationWorkflow(
      message: 'Task completed!',
      type: NotificationType.success,
    );
    final result = await workflow.execute();
    print('Workflow result: ${result.success}');
  }

  /// Complete system deployment
  static Future<void> completeSystemDeployment() async {
    // Deploy a complete multi-agent system with workflows
    await QuickStart.initialize(mode: QuickStartMode.production);

    final package = await QuickStart.deployComplete(
      name: 'Business Assistant System',
      type: QuickDeploymentType.multiAgent,
      config: {
        'specializations': ['conversation', 'mobile', 'analysis'],
        'business_mode': true,
      },
      workflows: [
        QuickStart.createDataProcessingWorkflow(
          inputVariable: 'customer_data',
          outputVariable: 'processed_report',
          processingType: 'customer_analysis',
        ),
      ],
    );

    print('Complete system deployed: ${package.name}');
    print('Agents: ${package.agentIds.length}');
    print('Workflows: ${package.workflowIds.length}');
  }

  /// Advanced workflow example
  static Workflow createAdvancedWorkflow() {
    return WorkflowBuilder.sequential('Advanced Customer Service')
        // Get customer input
        .addUserInput(
          prompt: 'How can we help you today?',
          variableName: 'customer_inquiry',
          type: UserInputType.text,
        )

        // Analyze sentiment
        .addTask(
          'sentiment_analysis',
          description: 'Analyze customer sentiment',
          parameters: {'text': '\${customer_inquiry}'},
        )

        // Branch based on sentiment
        .addDecision(
          condition: 'sentiment == negative',
          trueWorkflow: WorkflowBuilder.sequential('Escalation Path')
              .addNotification(
                message: 'Negative sentiment detected - escalating',
                type: NotificationType.warning,
              )
              .addTask(
                'create_priority_ticket',
                description: 'Create high-priority support ticket',
                parameters: {
                  'priority': 'high',
                  'inquiry': '\${customer_inquiry}',
                  'sentiment': '\${sentiment}',
                },
              ),
          falseWorkflow: WorkflowBuilder.sequential('Auto-Response Path')
              .addTask(
                'generate_response',
                description: 'Generate helpful auto-response',
                parameters: {'inquiry': '\${customer_inquiry}'},
              )
              .addNotification(
                message: 'Auto-response generated and sent',
                type: NotificationType.success,
              ),
        )

        // Log interaction
        .addTask(
          'log_interaction',
          description: 'Log customer interaction',
          parameters: {
            'inquiry': '\${customer_inquiry}',
            'sentiment': '\${sentiment}',
            'resolution_path': '\${branch}',
          },
        )

        // Final notification
        .addNotification(
          message: 'Customer service interaction completed',
          type: NotificationType.info,
        )
        .build();
  }
}