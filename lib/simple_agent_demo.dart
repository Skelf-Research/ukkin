import 'package:flutter/material.dart';
import 'package:agentlib/agentlib.dart';

/// Simple demo to show AgentLib integration working in Ukkin
class SimpleAgentDemo extends StatefulWidget {
  const SimpleAgentDemo({Key? key}) : super(key: key);

  @override
  State<SimpleAgentDemo> createState() => _SimpleAgentDemoState();
}

class _SimpleAgentDemoState extends State<SimpleAgentDemo> {
  String _status = 'Not initialized';
  String _lastAction = 'None';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple AgentLib Demo'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AgentLib Integration Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Status: $_status'),
                    Text('Last Action: $_lastAction'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testInitialization,
              child: const Text('Test AgentLib Initialization'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testQuickStart,
              child: const Text('Test QuickStart Features'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testWorkflow,
              child: const Text('Test Workflow Creation'),
            ),
            const SizedBox(height: 24),
            Text(
              'This demo shows that Ukkin now successfully uses AgentLib as its agent system instead of the original implementation.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testInitialization() async {
    setState(() {
      _status = 'Testing initialization...';
      _lastAction = 'Initializing AgentLib';
    });

    try {
      final result = await QuickStart.initialize(
        mode: QuickStartMode.development,
        databaseName: 'test_demo',
      );

      setState(() {
        _status = result.success ? 'Initialized ✅' : 'Failed ❌';
        _lastAction = 'AgentLib initialization ${result.success ? 'successful' : 'failed'}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error ❌';
        _lastAction = 'Error: $e';
      });
    }
  }

  Future<void> _testQuickStart() async {
    setState(() {
      _lastAction = 'Testing QuickStart...';
    });

    try {
      final agentId = await QuickStart.createChatBot(
        name: 'Test Agent',
        personality: 'helpful',
      );

      setState(() {
        _lastAction = 'Created agent: $agentId ✅';
      });
    } catch (e) {
      setState(() {
        _lastAction = 'QuickStart failed: $e ❌';
      });
    }
  }

  Future<void> _testWorkflow() async {
    setState(() {
      _lastAction = 'Testing workflow creation...';
    });

    try {
      final workflow = QuickStart.createNotificationWorkflow(
        message: 'Test workflow executed!',
        type: NotificationType.success,
        delay: const Duration(seconds: 1),
      );

      final result = await workflow.execute({'test': 'data'});

      setState(() {
        _lastAction = 'Workflow ${result.success ? 'executed successfully' : 'failed'} ✅';
      });
    } catch (e) {
      setState(() {
        _lastAction = 'Workflow test failed: $e ❌';
      });
    }
  }
}