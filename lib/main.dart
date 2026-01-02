import 'package:flutter/material.dart';
import 'package:agentlib/agentlib.dart' hide AgentChatInterface;
import 'ui/agent_dashboard.dart';
import 'agent/ui/agent_chat_interface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AgentLib SDK with QuickStart for rapid setup
  final initResult = await QuickStart.initialize(
    mode: QuickStartMode.development,
    databaseName: 'ukkin',
  );

  if (!initResult.success) {
    throw Exception('Failed to initialize AgentLib: ${initResult.error}');
  }

  // Create the core mobile assistant agent
  final agentId = await QuickStart.createMobileAssistant(
    name: 'Ukkin AI Assistant',
    supportedApps: [
      'com.android.chrome',
      'com.whatsapp',
      'com.google.android.gm',
      'com.google.android.dialer',
      'com.instagram.android',
      'com.twitter.android',
      'com.google.android.youtube',
    ],
    requireConfirmation: true,
  );

  // Setup repetitive task agents for automated background work
  await QuickStart.setupRepetitiveAgents(
    enableSocialMedia: true,
    enableCommunication: true,
    enableShopping: true,
    customConfig: {
      'social_media': {
        'instagram_accounts': ['competitor1', 'industry_leader'],
        'twitter_hashtags': ['#flutter', '#AI', '#mobile'],
      },
      'communication': {
        'important_senders': ['boss@company.com', 'important@client.com'],
        'auto_archive_days': 30,
      },
      'shopping': {
        'max_budget': 5000.0,
        'categories': ['Electronics', 'Books', 'Fashion'],
      },
    },
  );

  runApp(UkkinApp(agentId: agentId));
}

class UkkinApp extends StatelessWidget {
  final String agentId;

  const UkkinApp({Key? key, required this.agentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ukkin AI Assistant',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        fontFamily: 'SF Pro Display',
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        fontFamily: 'SF Pro Display',
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: MainInterface(agentId: agentId),
    );
  }
}

/// Main interface with bottom navigation between chat and agent management
class MainInterface extends StatefulWidget {
  final String agentId;

  const MainInterface({Key? key, required this.agentId}) : super(key: key);

  @override
  State<MainInterface> createState() => _MainInterfaceState();
}

class _MainInterfaceState extends State<MainInterface> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AgentChatInterface(agentId: widget.agentId),
          const AgentDashboard(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Agents',
          ),
        ],
      ),
    );
  }
}
