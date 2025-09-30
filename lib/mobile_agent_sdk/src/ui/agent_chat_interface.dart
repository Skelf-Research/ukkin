import 'package:flutter/material.dart';
import 'dart:async';

import '../core/agent_registry.dart';
import '../core/message_system.dart';
import '../models/agent_message.dart';
import '../utils/logger.dart';
import 'customization/agent_theme.dart';
import 'customization/agent_features.dart';
import 'voice_input_widget.dart';
import 'agent_status_widget.dart';

/// Main chat interface widget for interacting with agents
class AgentChatInterface extends StatefulWidget {
  /// Callback when a message is sent
  final Function(String)? onMessageSent;

  /// Callback when a voice command is received
  final Function(String)? onVoiceCommand;

  /// UI customizations
  final AgentUICustomizations customizations;

  /// Whether to show agent status
  final bool showAgentStatus;

  /// Whether to enable voice input
  final bool enableVoiceInput;

  /// Whether to enable message suggestions
  final bool enableSuggestions;

  /// Placeholder text for input field
  final String placeholder;

  const AgentChatInterface({
    Key? key,
    this.onMessageSent,
    this.onVoiceCommand,
    this.customizations = const AgentUICustomizations(),
    this.showAgentStatus = true,
    this.enableVoiceInput = true,
    this.enableSuggestions = true,
    this.placeholder = 'Type a message...',
  }) : super(key: key);

  @override
  State<AgentChatInterface> createState() => _AgentChatInterfaceState();
}

class _AgentChatInterfaceState extends State<AgentChatInterface> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AgentMessage> _messages = [];

  late StreamSubscription<AgentMessage> _messageSubscription;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _setupMessageListener();
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupMessageListener() {
    _messageSubscription = MessageSystem.instance.messageStream.listen(
      (message) {
        setState(() {
          _messages.add(message);
          _isProcessing = false;
        });
        _scrollToBottom();
      },
      onError: (error) {
        Logger.error('Message stream error', error: error);
        setState(() {
          _isProcessing = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.customizations.theme.backgroundColor,
      appBar: widget.showAgentStatus ? _buildAppBar() : null,
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'AI Assistant',
        style: widget.customizations.theme.titleStyle,
      ),
      backgroundColor: widget.customizations.theme.primaryColor,
      elevation: 1,
      actions: [
        AgentStatusWidget(
          showAgentCount: true,
          onAgentTap: _showAgentDetails,
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return _buildWelcomeScreen();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: _messages.length + (_isProcessing ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isProcessing) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy,
            size: 80,
            color: widget.customizations.theme.primaryColor.withOpacity(0.6),
          ),
          SizedBox(height: 24),
          Text(
            'Welcome to your AI Assistant',
            style: widget.customizations.theme.titleStyle.copyWith(
              fontSize: 24,
              color: widget.customizations.theme.primaryColor,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Start a conversation or try one of the suggestions below',
            style: widget.customizations.theme.subtitleStyle,
            textAlign: TextAlign.center,
          ),
          if (widget.enableSuggestions) ...[
            SizedBox(height: 32),
            _buildSuggestions(),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = [
      'Help me with my daily tasks',
      'What can you do?',
      'Set a reminder for tomorrow',
      'Analyze this image',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((suggestion) {
        return ActionChip(
          label: Text(suggestion),
          onPressed: () => _sendMessage(suggestion),
          backgroundColor: widget.customizations.theme.primaryColor.withOpacity(0.1),
          labelStyle: TextStyle(
            color: widget.customizations.theme.primaryColor,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMessageBubble(AgentMessage message) {
    final isUser = message.type == MessageType.user;
    final isSystem = message.type == MessageType.system;

    if (isSystem) {
      return _buildSystemMessage(message);
    }

    return Container(
      margin: EdgeInsets.only(
        bottom: 16,
        left: isUser ? 60 : 0,
        right: isUser ? 0 : 60,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAgentAvatar(message.agentId),
            SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser
                    ? widget.customizations.theme.primaryColor
                    : widget.customizations.theme.secondaryColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  if (message.metadata != null) ...[
                    SizedBox(height: 8),
                    _buildMessageMetadata(message.metadata!),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 12),
            _buildUserAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemMessage(AgentMessage message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.only(bottom: 16, right: 60),
      child: Row(
        children: [
          _buildAgentAvatar('assistant'),
          SizedBox(width: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.customizations.theme.secondaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                SizedBox(width: 4),
                _buildTypingDot(200),
                SizedBox(width: 4),
                _buildTypingDot(400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[500],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAgentAvatar(String agentId) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: widget.customizations.theme.primaryColor,
      child: Icon(
        Icons.smart_toy,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildUserAvatar() {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey[300],
      child: Icon(
        Icons.person,
        color: Colors.grey[600],
        size: 20,
      ),
    );
  }

  Widget _buildMessageMetadata(Map<String, dynamic> metadata) {
    return Wrap(
      spacing: 8,
      children: metadata.entries.map((entry) {
        return Chip(
          label: Text(
            '${entry.key}: ${entry.value}',
            style: TextStyle(fontSize: 10),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: widget.placeholder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: _sendMessage,
              textInputAction: TextInputAction.send,
            ),
          ),
          SizedBox(width: 12),
          if (widget.enableVoiceInput)
            VoiceInputWidget(
              onVoiceInput: _handleVoiceInput,
              onVoiceCommand: widget.onVoiceCommand,
            ),
          SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            onPressed: _isProcessing ? null : () => _sendMessage(_messageController.text),
            backgroundColor: widget.customizations.theme.primaryColor,
            child: _isProcessing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty || _isProcessing) return;

    final message = AgentMessage.user(text.trim());

    setState(() {
      _messages.add(message);
      _isProcessing = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Send to message system for processing
    MessageSystem.instance.sendMessage(message);

    // Notify callback
    widget.onMessageSent?.call(text.trim());
  }

  void _handleVoiceInput(String text) {
    _messageController.text = text;
    _sendMessage(text);
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

  void _showAgentDetails() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _AgentDetailsSheet(),
    );
  }
}

/// Sheet for displaying agent details
class _AgentDetailsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final agents = AgentRegistry.instance.getAllAgents();

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Agents',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          ...agents.map((agent) => ListTile(
            leading: CircleAvatar(
              child: Icon(Icons.smart_toy),
            ),
            title: Text(agent.name),
            subtitle: Text('${agent.capabilities.length} capabilities'),
            trailing: Chip(
              label: Text(agent.status.name),
              backgroundColor: _getStatusColor(agent.status),
            ),
          )),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Color _getStatusColor(AgentStatus status) {
    switch (status) {
      case AgentStatus.active:
        return Colors.green[100]!;
      case AgentStatus.busy:
        return Colors.orange[100]!;
      case AgentStatus.error:
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }
}

/// UI customizations for the agent chat interface
class AgentUICustomizations {
  final AgentTheme theme;
  final AgentFeatures features;

  const AgentUICustomizations({
    this.theme = const AgentTheme(),
    this.features = const AgentFeatures(),
  });
}