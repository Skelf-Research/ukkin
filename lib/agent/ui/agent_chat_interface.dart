import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/agent.dart';
import '../models/agent_message.dart';
import '../models/task.dart';
import '../coordination/agent_coordinator.dart';

class AgentChatInterface extends StatefulWidget {
  final Agent agent;
  final AgentCoordinator? coordinator;

  const AgentChatInterface({
    Key? key,
    required this.agent,
    this.coordinator,
  }) : super(key: key);

  @override
  _AgentChatInterfaceState createState() => _AgentChatInterfaceState();
}

class _AgentChatInterfaceState extends State<AgentChatInterface> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AgentMessage> _messages = [];
  final List<TaskResult> _taskResults = [];

  late Stream<AgentMessage> _messageStream;
  late Stream<TaskResult> _taskStream;
  late Stream<CoordinationEvent>? _coordinationStream;

  bool _isAutonomousMode = false;
  String? _currentObjective;

  @override
  void initState() {
    super.initState();
    _messageStream = widget.agent.messageStream;
    _taskStream = widget.agent.taskResultStream;
    _coordinationStream = widget.coordinator?.events;

    // Listen to agent messages
    _messageStream.listen((message) {
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
    });

    // Listen to task results
    _taskStream.listen((result) {
      setState(() {
        _taskResults.add(result);
      });
    });

    // Listen to coordination events if coordinator is available
    _coordinationStream?.listen((event) {
      if (event.agentId == widget.agent.id) {
        _handleCoordinationEvent(event);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(_getAgentIcon()),
            SizedBox(width: 8),
            Expanded(
              child: Text(widget.agent.name),
            ),
            IconButton(
              icon: Icon(_isAutonomousMode ? Icons.pause : Icons.play_arrow),
              onPressed: _toggleAutonomousMode,
              tooltip: _isAutonomousMode ? 'Stop Autonomous Mode' : 'Start Autonomous Mode',
            ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                PopupMenuItem(value: 'clear', child: Text('Clear Chat')),
                PopupMenuItem(value: 'export', child: Text('Export Chat')),
                PopupMenuItem(value: 'tasks', child: Text('View Tasks')),
                PopupMenuItem(value: 'memory', child: Text('Memory Stats')),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_isAutonomousMode) _buildObjectiveBanner(),
          Expanded(
            child: _buildMessageList(),
          ),
          _buildTaskStatusBar(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildObjectiveBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      color: Colors.blue.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.auto_mode, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Autonomous Mode: ${_currentObjective ?? "No objective set"}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: _stopAutonomousMode,
            child: Text('Stop'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(AgentMessage message) {
    final isUserMessage = message.type == MessageType.user;
    final isErrorMessage = message.type == MessageType.error;
    final isStatusMessage = message.type == MessageType.status;

    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: _getMessageColor(message.type),
          borderRadius: BorderRadius.circular(12),
          border: isErrorMessage ? Border.all(color: Colors.red, width: 1) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUserMessage)
              Text(
                _getMessageTypeLabel(message.type),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            SizedBox(height: 4),
            Text(
              message.content,
              style: TextStyle(
                color: isUserMessage ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isUserMessage ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStatusBar() {
    if (_taskResults.isEmpty) return SizedBox.shrink();

    final recentTasks = _taskResults.reversed.take(3).toList();

    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.task_alt, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: recentTasks.map((result) =>
                  _buildTaskStatusChip(result)
                ).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatusChip(TaskResult result) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTaskStatusColor(result.status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTaskStatusIcon(result.status),
            size: 12,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            result.status.name,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: _isAutonomousMode
                    ? 'Agent is in autonomous mode...'
                    : 'Type your message or objective...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              enabled: !_isAutonomousMode,
              maxLines: null,
              onSubmitted: _sendMessage,
            ),
          ),
          SizedBox(width: 8),
          FloatingActionButton.small(
            onPressed: _isAutonomousMode ? null : () => _sendMessage(_messageController.text),
            child: Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final message = AgentMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      agentId: 'user',
      type: MessageType.user,
      content: text.trim(),
    );

    setState(() {
      _messages.add(message);
      _messageController.clear();
    });

    _scrollToBottom();

    // Check if this looks like an objective for autonomous mode
    if (_looksLikeObjective(text)) {
      _showAutonomousModePrompt(text);
    } else {
      // Send regular message to agent
      await widget.agent.processMessage(message);
    }
  }

  bool _looksLikeObjective(String text) {
    final objectiveKeywords = ['search for', 'find me', 'research', 'get me', 'help me', 'i need'];
    return objectiveKeywords.any((keyword) => text.toLowerCase().contains(keyword));
  }

  void _showAutonomousModePrompt(String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Autonomous Mode'),
        content: Text('This looks like an objective. Would you like me to work on this autonomously?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.agent.processMessage(AgentMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                agentId: 'user',
                type: MessageType.user,
                content: text,
              ));
            },
            child: Text('No, just respond'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startAutonomousMode(text);
            },
            child: Text('Yes, work autonomously'),
          ),
        ],
      ),
    );
  }

  void _toggleAutonomousMode() {
    if (_isAutonomousMode) {
      _stopAutonomousMode();
    } else {
      _showObjectiveInput();
    }
  }

  void _showObjectiveInput() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Objective'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'What would you like me to accomplish?',
          ),
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _startAutonomousMode(controller.text.trim());
              }
            },
            child: Text('Start'),
          ),
        ],
      ),
    );
  }

  void _startAutonomousMode(String objective) async {
    setState(() {
      _isAutonomousMode = true;
      _currentObjective = objective;
    });

    if (widget.agent is AutonomousAgent) {
      await (widget.agent as AutonomousAgent).start(objective);
    }
  }

  void _stopAutonomousMode() async {
    setState(() {
      _isAutonomousMode = false;
      _currentObjective = null;
    });

    if (widget.agent is AutonomousAgent) {
      await (widget.agent as AutonomousAgent).stop();
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear':
        setState(() {
          _messages.clear();
          _taskResults.clear();
        });
        break;
      case 'export':
        _exportChat();
        break;
      case 'tasks':
        _showTasksDialog();
        break;
      case 'memory':
        _showMemoryStats();
        break;
    }
  }

  void _exportChat() {
    // TODO: Implement chat export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export functionality coming soon')),
    );
  }

  void _showTasksDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recent Tasks'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _taskResults.length,
            itemBuilder: (context, index) {
              final result = _taskResults[index];
              return ListTile(
                leading: Icon(_getTaskStatusIcon(result.status)),
                title: Text('Task ${result.taskId}'),
                subtitle: Text(result.status.name),
                trailing: Text(_formatTimestamp(result.completedAt)),
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

  void _showMemoryStats() async {
    final stats = await widget.agent.memory.getMemoryStats();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Memory Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Memories: ${stats['total_memories']}'),
            Text('Total Tasks: ${stats['total_tasks']}'),
            SizedBox(height: 16),
            Text('Memory Types:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...((stats['memory_types'] as Map).entries.map((entry) =>
              Text('  ${entry.key}: ${entry.value}')
            )),
          ],
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

  void _handleCoordinationEvent(CoordinationEvent event) {
    // Handle coordination events for this agent
    setState(() {
      // Update UI based on coordination events
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  IconData _getAgentIcon() {
    // TODO: Return appropriate icon based on agent type/capabilities
    return Icons.smart_toy;
  }

  Color _getMessageColor(MessageType type) {
    switch (type) {
      case MessageType.user:
        return Colors.blue;
      case MessageType.error:
        return Colors.red[100]!;
      case MessageType.status:
        return Colors.green[100]!;
      case MessageType.learning:
        return Colors.purple[100]!;
      default:
        return Colors.grey[200]!;
    }
  }

  String _getMessageTypeLabel(MessageType type) {
    switch (type) {
      case MessageType.agent:
        return 'Agent';
      case MessageType.system:
        return 'System';
      case MessageType.status:
        return 'Status';
      case MessageType.error:
        return 'Error';
      case MessageType.learning:
        return 'Learning';
      case MessageType.tool:
        return 'Tool';
      default:
        return type.name.toUpperCase();
    }
  }

  Color _getTaskStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.failed:
        return Colors.red;
      case TaskStatus.running:
        return Colors.blue;
      case TaskStatus.cancelled:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTaskStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.failed:
        return Icons.error;
      case TaskStatus.running:
        return Icons.play_circle;
      case TaskStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}