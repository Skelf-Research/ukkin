import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agentlib/agentlib.dart';
import 'dart:async';

import 'task_session.dart';
import 'voice/voice_chat_widget.dart';
import 'vlm/visual_assistant.dart';
import 'vlm/image_analysis_widget.dart';
import 'vlm/screen_understanding_widget.dart';
import 'platform/platform_manager.dart';
import 'integrations/app_integration_service.dart';
import 'integrations/workflow_builder.dart';
import 'integrations/ui/app_integrations_screen.dart';
import 'integrations/ui/workflows_screen.dart';
import 'integrations/ui/performance_settings_screen.dart';

class AIAssistantHome extends StatefulWidget {
  final String agentId;

  const AIAssistantHome({Key? key, required this.agentId}) : super(key: key);

  @override
  _AIAssistantHomeState createState() => _AIAssistantHomeState();
}

class _AIAssistantHomeState extends State<AIAssistantHome> with TickerProviderStateMixin {
  final SessionManager _sessionManager = SessionManager();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  TaskSession? _currentSession;
  bool _isTyping = false;
  bool _isListening = false;
  bool _showSuggestions = true;
  Agent? _agent;
  StreamSubscription? _messageSubscription;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);

    // Initialize platform optimizations and app integrations
    _initializePlatformFeatures();

    // Initialize AgentLib agent
    _initializeAgent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: ScreenUnderstandingWidget(
        enableRealTimeAnalysis: false, // Can be enabled per user preference
        analysisInterval: Duration(seconds: 10),
        showOverlay: false, // Keep UI clean by default
        onAnalysisComplete: (analysis) {
          // Optionally send insights to chat
          if (analysis.suggestedActions.isNotEmpty && _currentSession != null) {
            final actionCount = analysis.suggestedActions.length;
            _sendMessage("I notice $actionCount possible actions on this screen. Would you like me to help?");
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _currentSession == null
                    ? _buildWelcomeScreen()
                    : _buildChatInterface(),
              ),
              _buildInputArea(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildVLMFloatingButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isTyping ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[600]!, Colors.purple[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
              );
            },
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentSession?.title ?? 'Ukkin AI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                if (_currentSession != null) ...[
                  Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_currentSession != null) ...[
            _buildProgressIndicator(),
            SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                PopupMenuItem(value: 'pause', child: Text('Pause Tasks')),
                PopupMenuItem(value: 'clear', child: Text('Clear Session')),
                PopupMenuItem(value: 'save', child: Text('Save Session')),
                PopupMenuItem(value: 'sessions', child: Text('All Sessions')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'visual_assistant', child: Text('Visual Assistant')),
                PopupMenuItem(value: 'image_analysis', child: Text('Image Analysis')),
                PopupMenuItem(value: 'screen_reader', child: Text('Screen Reader')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'app_integrations', child: Text('App Integrations')),
                PopupMenuItem(value: 'workflows', child: Text('Workflows')),
                PopupMenuItem(value: 'performance', child: Text('Performance')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          Text(
            'Hi! I\'m your AI assistant.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'I can help you get things done on your phone. Just tell me what you need.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          SizedBox(height: 32),
          if (_showSuggestions) _buildSuggestions(),
          SizedBox(height: 32),
          _buildRecentSessions(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = [
      {
        'icon': Icons.message,
        'title': 'Send a message',
        'subtitle': 'WhatsApp, SMS, or email',
        'prompt': 'Send a WhatsApp message to',
      },
      {
        'icon': Icons.search,
        'title': 'Research something',
        'subtitle': 'Find information online',
        'prompt': 'Research and summarize',
      },
      {
        'icon': Icons.schedule,
        'title': 'Set reminders',
        'subtitle': 'Schedule tasks and events',
        'prompt': 'Remind me to',
      },
      {
        'icon': Icons.photo_camera,
        'title': 'Take action',
        'subtitle': 'Photos, calls, app control',
        'prompt': 'Take a photo and',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What can I help you with?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return GestureDetector(
              onTap: () => _startSuggestion(suggestion['prompt'] as String),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      suggestion['icon'] as IconData,
                      size: 24,
                      color: Colors.blue[600],
                    ),
                    SizedBox(height: 8),
                    Text(
                      suggestion['title'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      suggestion['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentSessions() {
    final recentSessions = _sessionManager.getRecentSessions(limit: 3);

    if (recentSessions.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Sessions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        ...recentSessions.map((session) => _buildSessionCard(session)).toList(),
      ],
    );
  }

  Widget _buildSessionCard(TaskSession session) {
    return GestureDetector(
      onTap: () => _resumeSession(session),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getSessionStatusColor(session.status).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getSessionStatusIcon(session.status),
                color: _getSessionStatusColor(session.status),
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${session.formattedDuration} • ${session.messages.length} messages',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (session.progressPercentage > 0)
              Text(
                '${session.progressPercentage.round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        if (_currentSession!.progressPercentage > 0) _buildTaskProgress(),
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: EdgeInsets.all(16),
            itemCount: _currentSession!.messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _currentSession!.messages.length && _isTyping) {
                return _buildTypingIndicator();
              }
              return _buildMessageBubble(_currentSession!.messages[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskProgress() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work_outline, size: 16, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text(
                'Working on your request...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[600],
                ),
              ),
              Spacer(),
              Text(
                '${_currentSession!.progressPercentage.round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: _currentSession!.progressPercentage / 100,
            backgroundColor: Colors.blue[100],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
          if (_currentSession!.tasks.isNotEmpty) ...[
            SizedBox(height: 12),
            ...(_currentSession!.tasks.take(3).map((task) => _buildTaskItem(task))),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskItem(TaskProgress task) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            _getTaskIcon(task.status),
            size: 12,
            color: _getTaskColor(task.status),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              task.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AgentMessage message) {
    final isUser = message.type == MessageType.user;
    final isSystem = message.type == MessageType.status ||
                     message.type == MessageType.system;

    if (isSystem) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.purple[600]!],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[600] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 16,
                  color: isUser ? Colors.white : Colors.grey[800],
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) SizedBox(width: 40),
          if (!isUser) SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.purple[600]!],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(3, (index) => Container(
                  margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: VoiceChatWidget(
        onMessageSent: _sendMessage,
        onVoiceCommand: _handleVoiceCommand,
        showVoiceButton: true,
        autoSendVoiceInput: false, // Show confirmation dialog
        enableWakeWord: false,
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (_currentSession == null || _currentSession!.progressPercentage == 0) {
      return SizedBox.shrink();
    }

    return Container(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        value: _currentSession!.progressPercentage / 100,
        strokeWidth: 2,
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
      ),
    );
  }

  void _startSuggestion(String prompt) {
    _messageController.text = prompt;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: prompt.length),
    );
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Create or continue session
    if (_currentSession == null) {
      final title = _generateSessionTitle(text);
      _currentSession = _sessionManager.createSession(title);
    }

    final userMessage = AgentMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      agentId: 'user',
      type: MessageType.user,
      content: text.trim(),
    );

    setState(() {
      _currentSession!.addMessage(userMessage);
      _currentSession!.status = SessionStatus.working;
      _currentSession!.currentObjective = text.trim();
      _isTyping = true;
      _showSuggestions = false;
    });

    _messageController.clear();
    _scrollToBottom();

    // Send to agent
    try {
      if (_agent != null) {
        if (_looksLikeComplexTask(text)) {
          // Create and execute a workflow using AgentLib
          final workflow = QuickStart.createWorkflow('User Task')
              .addTask(
                'user_request',
                description: 'Process user request: $text',
                parameters: {'request': text},
              )
              .build();

          final result = await workflow.execute({'user_input': text});

          final responseMessage = AgentMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            agentId: widget.agentId,
            type: MessageType.agent,
            content: result.success
                ? "I've processed your request successfully."
                : "I encountered an issue: ${result.error}",
            timestamp: DateTime.now(),
          );

          setState(() {
            _isTyping = false;
            _currentSession!.addMessage(responseMessage);
          });
        } else {
          final response = await _agent!.processMessage(userMessage);
          setState(() {
            _isTyping = false;
            _currentSession!.addMessage(response);
          });
        }
      }
    } catch (e) {
      setState(() {
        _isTyping = false;
        _currentSession!.addMessage(AgentMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          agentId: widget.agentId,
          type: MessageType.error,
          content: "Sorry, I encountered an error: $e",
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  void _resumeSession(TaskSession session) {
    setState(() {
      _currentSession = session;
      _showSuggestions = false;
    });
  }

  void _handleVoiceCommand(String command) {
    final lowerCommand = command.toLowerCase();

    // Handle system-level voice commands
    if (lowerCommand.contains('new session') || lowerCommand.contains('start over')) {
      setState(() {
        _currentSession = null;
        _showSuggestions = true;
      });
      _showVoiceCommandFeedback('New session started');
    } else if (lowerCommand.contains('clear chat') || lowerCommand.contains('clear conversation')) {
      setState(() {
        _currentSession = null;
        _showSuggestions = true;
      });
      _showVoiceCommandFeedback('Chat cleared');
    } else if (lowerCommand.contains('pause') || lowerCommand.contains('stop task')) {
      // TODO: Implement workflow pause using AgentLib
      _showVoiceCommandFeedback('Task paused');
    } else if (lowerCommand.contains('resume') || lowerCommand.contains('continue task')) {
      // TODO: Implement workflow resume using AgentLib
      _showVoiceCommandFeedback('Task resumed');
    } else {
      // Treat unrecognized commands as regular messages
      _sendMessage(command);
    }
  }

  void _showVoiceCommandFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mic, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'pause':
        // TODO: Implement workflow pause using AgentLib
        break;
      case 'clear':
        setState(() {
          _currentSession = null;
          _showSuggestions = true;
        });
        break;
      case 'save':
        // TODO: Implement save session
        break;
      case 'sessions':
        _showSessionsDialog();
        break;
      case 'visual_assistant':
        _showVisualAssistant();
        break;
      case 'image_analysis':
        _showImageAnalysis();
        break;
      case 'screen_reader':
        _showScreenReader();
        break;
      case 'app_integrations':
        _showAppIntegrations();
        break;
      case 'workflows':
        _showWorkflows();
        break;
      case 'performance':
        _showPerformanceSettings();
        break;
    }
  }

  void _showSessionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('All Sessions'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _sessionManager.sessions.length,
            itemBuilder: (context, index) {
              final session = _sessionManager.sessions[index];
              return ListTile(
                title: Text(session.title),
                subtitle: Text('${session.formattedDuration} • ${session.messages.length} messages'),
                onTap: () {
                  Navigator.pop(context);
                  _resumeSession(session);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _generateSessionTitle(String text) {
    if (text.length <= 30) return text;
    return text.substring(0, 30) + '...';
  }

  bool _looksLikeComplexTask(String text) {
    final complexKeywords = [
      'and then', 'after that', 'next', 'also', 'workflow',
      'multiple', 'first', 'second', 'finally', 'steps'
    ];
    return complexKeywords.any((keyword) => text.toLowerCase().contains(keyword));
  }

  String _getStatusText() {
    switch (_currentSession!.status) {
      case SessionStatus.active:
        return 'Ready to help';
      case SessionStatus.working:
        return 'Working on it...';
      case SessionStatus.completed:
        return 'Task completed';
      case SessionStatus.failed:
        return 'Something went wrong';
      case SessionStatus.paused:
        return 'Paused';
    }
  }

  Color _getStatusColor() {
    switch (_currentSession!.status) {
      case SessionStatus.active:
        return Colors.green[600]!;
      case SessionStatus.working:
        return Colors.blue[600]!;
      case SessionStatus.completed:
        return Colors.green[600]!;
      case SessionStatus.failed:
        return Colors.red[600]!;
      case SessionStatus.paused:
        return Colors.orange[600]!;
    }
  }

  IconData _getSessionStatusIcon(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return Icons.chat_bubble_outline;
      case SessionStatus.working:
        return Icons.work_outline;
      case SessionStatus.completed:
        return Icons.check_circle_outline;
      case SessionStatus.failed:
        return Icons.error_outline;
      case SessionStatus.paused:
        return Icons.pause_circle_outline;
    }
  }

  Color _getSessionStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return Colors.blue[600]!;
      case SessionStatus.working:
        return Colors.orange[600]!;
      case SessionStatus.completed:
        return Colors.green[600]!;
      case SessionStatus.failed:
        return Colors.red[600]!;
      case SessionStatus.paused:
        return Colors.grey[600]!;
    }
  }

  IconData _getTaskIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.schedule;
      case TaskStatus.running:
        return Icons.play_circle_outline;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.failed:
        return Icons.error;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getTaskColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.grey[600]!;
      case TaskStatus.running:
        return Colors.blue[600]!;
      case TaskStatus.completed:
        return Colors.green[600]!;
      case TaskStatus.failed:
        return Colors.red[600]!;
      case TaskStatus.cancelled:
        return Colors.orange[600]!;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildVLMFloatingButton() {
    return FloatingActionButton(
      onPressed: _showVLMOptions,
      backgroundColor: Colors.purple[600],
      child: Icon(Icons.visibility, color: Colors.white),
      tooltip: 'Visual AI Features',
    );
  }

  void _showVLMOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Visual AI Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.assistant, color: Colors.blue[600]),
              title: Text('Visual Assistant'),
              subtitle: Text('Proactive help and accessibility assistance'),
              onTap: () {
                Navigator.pop(context);
                _showVisualAssistant();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera, color: Colors.green[600]),
              title: Text('Image Analysis'),
              subtitle: Text('Analyze photos and detect objects'),
              onTap: () {
                Navigator.pop(context);
                _showImageAnalysis();
              },
            ),
            ListTile(
              leading: Icon(Icons.record_voice_over, color: Colors.orange[600]),
              title: Text('Screen Reader'),
              subtitle: Text('Read screen content aloud'),
              onTap: () {
                Navigator.pop(context);
                _showScreenReader();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVisualAssistant() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Visual Assistant'),
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
          body: VisualAssistant(
            enableProactiveHelp: true,
            enableAccessibilityAssist: true,
            enableContextAwareness: true,
            onHelpSuggestion: (suggestion) {
              // Add suggestion to chat
              _sendMessage("Visual Assistant suggests: $suggestion");
            },
            onAccessibilityIssue: (issue) {
              _sendMessage("Accessibility issue detected: $issue");
            },
            onFormDetected: (formType) {
              _sendMessage("Form detected: $formType. Would you like help filling it?");
            },
          ),
        ),
      ),
    );
  }

  void _showImageAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Image Analysis'),
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
          ),
          body: ImageAnalysisWidget(
            enableObjectDetection: true,
            enableTextExtraction: true,
            enableSemanticAnalysis: true,
            enableSmartCropping: true,
            onAnalysisComplete: (result) {
              _sendMessage("Image analysis: ${result.description}");
              if (result.detectedObjects.isNotEmpty) {
                _sendMessage("Found objects: ${result.detectedObjects.map((e) => e.label).join(', ')}");
              }
              if (result.extractedText.isNotEmpty) {
                _sendMessage("Extracted text: ${result.extractedText}");
              }
            },
            onObjectsDetected: (objects) {
              _sendMessage("Detected ${objects.length} objects in the image");
            },
          ),
        ),
      ),
    );
  }

  void _showScreenReader() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Screen Reader'),
            backgroundColor: Colors.orange[600],
            foregroundColor: Colors.white,
          ),
          body: SmartScreenReader(
            onTextDetected: (text) {
              _sendMessage("Screen reader detected: $text");
            },
            onScreenAnalyzed: (analysis) {
              if (analysis.suggestedActions.isNotEmpty) {
                _sendMessage("Found ${analysis.suggestedActions.length} possible actions on screen");
              }
            },
            enableContinuousReading: false,
            readingInterval: Duration(seconds: 3),
          ),
        ),
      ),
    );
  }

  Future<void> _initializePlatformFeatures() async {
    try {
      // Initialize platform manager
      await PlatformManager.instance.initialize();

      // Initialize app integrations
      await AppIntegrationService.instance.initialize();

      // Initialize workflow builder
      await WorkflowBuilder.instance.initialize();

      debugPrint('Platform features initialized successfully');
    } catch (e) {
      debugPrint('Platform features initialization failed: $e');
    }
  }

  void _showAppIntegrations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppIntegrationsScreen(),
      ),
    );
  }

  void _showWorkflows() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkflowsScreen(),
      ),
    );
  }

  void _showPerformanceSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PerformanceSettingsScreen(),
      ),
    );
  }

  Future<void> _initializeAgent() async {
    try {
      _agent = AgentRegistry.instance.getAgent(widget.agentId);
      if (_agent != null) {
        // Listen to agent messages if the agent supports streaming
        // For now, we'll handle responses synchronously
        debugPrint('Agent initialized: ${_agent!.name}');
      }
    } catch (e) {
      debugPrint('Failed to initialize agent: $e');
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _pulseController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    _sessionManager.dispose();
    super.dispose();
  }
}