import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as flutter show TimeOfDay;
import 'package:agentlib/agentlib.dart';
import 'package:agentlib/src/mobile/real_automation.dart';

// Custom automation agent for conversational flows
class CustomAutomationAgent extends RepetitiveTaskAgent {
  final String _id;
  final String _name;
  final String description;
  final List<String> targetApps;
  final AgentSchedule agentSchedule;
  final List<FlowStep> customSteps;
  final Map<String, dynamic> agentSettings;

  CustomAutomationAgent({
    required String id,
    required String name,
    required this.description,
    required this.targetApps,
    required this.agentSchedule,
    required this.customSteps,
    required this.agentSettings,
  }) : _id = id, _name = name;

  @override
  String get id => _id;

  @override
  String get name => _name;

  @override
  List<String> get capabilities => ['custom_automation', 'conversational_flow'];

  @override
  Duration get interval => agentSchedule.interval;

  @override
  TimeOfDay? get preferredTime => agentSchedule.preferredTime;

  @override
  List<String> get requiredApps => targetApps;

  @override
  Future<RepetitiveTaskResult> executeRoutine() async {
    try {
      final automation = RealAutomation();

      // Check if accessibility service is enabled
      if (!await automation.isEnabled()) {
        return RepetitiveTaskResult.failure('Accessibility service not enabled. Please enable it in Settings.');
      }

      final results = <String>[];
      int stepsExecuted = 0;

      // Execute each custom step
      for (final step in customSteps) {
        try {
          // Launch target app if specified
          if (step.app != null && step.app!.isNotEmpty) {
            if (!await automation.launchApp(step.app!)) {
              results.add('Failed to launch ${step.app}');
              continue;
            }
            await Future.delayed(const Duration(seconds: 2));
          }

          // Execute based on step type
          switch (step.type.toLowerCase()) {
            case 'open':
            case 'launch':
              // Already launched above
              results.add('Opened ${step.app ?? step.target}');
              break;

            case 'tap':
            case 'click':
              if (step.target != null) {
                final success = await automation.tapOnText(step.target!);
                results.add(success ? 'Tapped on "${step.target}"' : 'Could not find "${step.target}"');
              }
              break;

            case 'type':
            case 'input':
              if (step.value != null) {
                final success = await automation.typeText(step.value!);
                results.add(success ? 'Typed text' : 'Failed to type');
              }
              break;

            case 'scroll':
              final direction = step.value ?? 'down';
              await automation.scroll(direction);
              results.add('Scrolled $direction');
              break;

            case 'wait':
              final ms = int.tryParse(step.value ?? '1000') ?? 1000;
              await Future.delayed(Duration(milliseconds: ms));
              results.add('Waited ${ms}ms');
              break;

            case 'wait_for':
              if (step.target != null) {
                final found = await automation.waitForElement(step.target!, timeoutMs: 5000);
                results.add(found ? 'Found "${step.target}"' : 'Timeout waiting for "${step.target}"');
              }
              break;

            case 'extract':
            case 'read':
              final texts = await automation.extractAllText();
              final combinedText = texts.join(' ');

              // Check for keywords if specified
              if (step.value != null && step.value!.isNotEmpty) {
                final keywords = step.value!.split(',').map((k) => k.trim().toLowerCase()).toList();
                for (final keyword in keywords) {
                  if (combinedText.toLowerCase().contains(keyword)) {
                    results.add('Found keyword: $keyword');
                  }
                }
              } else {
                results.add('Extracted ${texts.length} text elements');
              }
              break;

            case 'back':
              await automation.pressBack();
              results.add('Pressed back');
              break;

            case 'home':
              await automation.pressHome();
              results.add('Pressed home');
              break;

            case 'save':
            case 'bookmark':
              // Try common save/bookmark patterns
              final saved = await automation.tapOnText('Save') ||
                           await automation.tapOnText('Bookmark');
              results.add(saved ? 'Saved item' : 'Could not find save button');
              break;

            default:
              results.add('Unknown step type: ${step.type}');
          }

          stepsExecuted++;

          // Small delay between steps
          await Future.delayed(const Duration(milliseconds: 500));

        } catch (e) {
          results.add('Step "${step.name}" failed: $e');
        }
      }

      // Return home when done
      await automation.pressHome();

      return RepetitiveTaskResult.success('Custom automation completed', {
        'steps_executed': stepsExecuted,
        'total_steps': customSteps.length,
        'results': results,
      });
    } catch (e) {
      return RepetitiveTaskResult.failure('Custom automation failed: $e');
    }
  }

  @override
  Future<bool> shouldRun() async {
    // Custom logic to determine if the agent should run
    return true;
  }

  @override
  Future<void> handleFailure(String error) async {
    // Handle custom automation failures
    debugPrint('Custom automation failed: $error');
  }
}

/// Conversational interface for building custom agents through chat
class ConversationalAgentBuilder extends StatefulWidget {
  const ConversationalAgentBuilder({Key? key}) : super(key: key);

  @override
  State<ConversationalAgentBuilder> createState() => _ConversationalAgentBuilderState();
}

class _ConversationalAgentBuilderState extends State<ConversationalAgentBuilder> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  AgentFlowBuilder? _currentFlow;
  BuilderStage _stage = BuilderStage.introduction;

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  void _startConversation() {
    _addBotMessage(
      "Hi! I'm your Agent Builder assistant 🤖\n\n"
      "I'll help you create a custom automation agent by chatting about what you need. "
      "You can:\n\n"
      "• Describe a repetitive task you do\n"
      "• Tell me about apps you want automated\n"
      "• Explain a workflow you want to set up\n\n"
      "Or try one of these examples:",
      showQuickReplies: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Create Custom Agent'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_currentFlow != null)
            IconButton(
              onPressed: _showFlowPreview,
              icon: const Icon(Icons.preview),
              tooltip: 'Preview Flow',
            ),
        ],
      ),
      body: Column(
        children: [
          if (_stage == BuilderStage.confirmation)
            _buildFlowPreviewCard(),
          Expanded(child: _buildChatArea()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildFlowPreviewCard() {
    if (_currentFlow == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: const Color(0xFF6366F1), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Generated Agent Flow',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _editFlow,
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentFlow!.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currentFlow!.description,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          _buildFlowSteps(),
        ],
      ),
    );
  }

  Widget _buildFlowSteps() {
    return Column(
      children: _currentFlow!.steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == _currentFlow!.steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 32,
                    color: Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (step.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        step.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildChatArea() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _buildBotAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF6366F1) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 16,
                      color: isUser ? Colors.white : const Color(0xFF1F2937),
                      height: 1.4,
                    ),
                  ),
                ),
                if (message.quickReplies.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildQuickReplies(message.quickReplies),
                ],
                if (message.actionButtons.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildActionButtons(message.actionButtons),
                ],
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 40),
          if (!isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildBotAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
    );
  }

  Widget _buildQuickReplies(List<String> quickReplies) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: quickReplies.map((reply) =>
        GestureDetector(
          onTap: () => _sendMessage(reply),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
            ),
            child: Text(
              reply,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildActionButtons(List<ActionButton> buttons) {
    return Column(
      children: buttons.map((button) =>
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          child: ElevatedButton.icon(
            onPressed: button.onPressed,
            icon: Icon(button.icon, size: 18),
            label: Text(button.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: button.isPrimary ? const Color(0xFF6366F1) : Colors.white,
              foregroundColor: button.isPrimary ? Colors.white : const Color(0xFF6366F1),
              side: button.isPrimary ? null : const BorderSide(color: Color(0xFF6366F1)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _buildBotAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: _getInputHint(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            onPressed: () => _sendMessage(_messageController.text),
            backgroundColor: const Color(0xFF6366F1),
            mini: true,
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();
    _processUserMessage(text.trim());
  }

  Future<void> _processUserMessage(String message) async {
    // Simulate AI processing delay
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() => _isTyping = false);

    // Process message based on current stage
    switch (_stage) {
      case BuilderStage.introduction:
        await _handleIntroduction(message);
        break;
      case BuilderStage.gatheringRequirements:
        await _handleRequirements(message);
        break;
      case BuilderStage.clarification:
        await _handleClarification(message);
        break;
      case BuilderStage.confirmation:
        await _handleConfirmation(message);
        break;
    }
  }

  Future<void> _handleIntroduction(String message) async {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('instagram') || lowerMessage.contains('social')) {
      _startSocialMediaFlow(message);
    } else if (lowerMessage.contains('email') || lowerMessage.contains('whatsapp') || lowerMessage.contains('message')) {
      _startCommunicationFlow(message);
    } else if (lowerMessage.contains('price') || lowerMessage.contains('shop') || lowerMessage.contains('deal')) {
      _startShoppingFlow(message);
    } else {
      _startCustomFlow(message);
    }
  }

  void _startSocialMediaFlow(String message) {
    _addBotMessage(
      "Great! I can help you set up social media monitoring. 📱\n\n"
      "I understand you want to track social media activity. Let me ask a few questions:\n\n"
      "• Which platforms? (Instagram, Twitter, LinkedIn, etc.)\n"
      "• What accounts or hashtags should I monitor?\n"
      "• How often should I check for updates?",
      quickReplies: ['Instagram competitors', 'Twitter mentions', 'LinkedIn job posts', 'Custom setup'],
    );
    _stage = BuilderStage.gatheringRequirements;
  }

  void _startCommunicationFlow(String message) {
    _addBotMessage(
      "Perfect! I can automate your communication apps. 📧\n\n"
      "I can help with:\n"
      "• Email organization and filtering\n"
      "• WhatsApp auto-replies\n"
      "• SMS management\n"
      "• Calendar event creation\n\n"
      "What specific communication task would you like to automate?",
      quickReplies: ['Organize emails', 'WhatsApp auto-reply', 'Delete spam SMS', 'Custom setup'],
    );
    _stage = BuilderStage.gatheringRequirements;
  }

  void _startShoppingFlow(String message) {
    _addBotMessage(
      "Excellent! I can help you never miss a deal. 🛒\n\n"
      "I can set up:\n"
      "• Price tracking on products you want\n"
      "• Deal alerts in categories you like\n"
      "• Budget monitoring\n"
      "• Wishlist price drops\n\n"
      "What shopping automation would be most helpful?",
      quickReplies: ['Track iPhone price', 'Find electronics deals', 'Monitor my budget', 'Custom setup'],
    );
    _stage = BuilderStage.gatheringRequirements;
  }

  void _startCustomFlow(String message) {
    _addBotMessage(
      "I'd love to help you create a custom automation! 🎯\n\n"
      "Tell me more about what you want to automate:\n\n"
      "• What apps do you use regularly?\n"
      "• What repetitive tasks annoy you?\n"
      "• What notifications do you want?\n"
      "• How often should it run?\n\n"
      "The more details you give me, the better I can help!",
    );
    _stage = BuilderStage.gatheringRequirements;
  }

  Future<void> _handleRequirements(String message) async {
    // Simulate AI analysis of requirements
    _addBotMessage("Let me analyze that... 🤔");

    await Future.delayed(const Duration(milliseconds: 1000));

    // Generate a flow based on the conversation
    _currentFlow = _generateFlowFromConversation();

    _addBotMessage(
      "Perfect! Based on our conversation, I've created a custom agent flow for you. ✨\n\n"
      "**${_currentFlow!.name}**\n"
      "${_currentFlow!.description}\n\n"
      "Quick overview:\n"
      "${_currentFlow!.steps.take(3).map((s) => '• ${s.title}').join('\n')}"
      "${_currentFlow!.steps.length > 3 ? '\n• ... and ${_currentFlow!.steps.length - 3} more steps' : ''}\n\n"
      "Does this look good, or would you like me to adjust anything?",
      actionButtons: [
        ActionButton('Preview Full Flow', Icons.visibility, false, _showFlowPreview),
        ActionButton('Create Agent', Icons.check, true, _createAgent),
        ActionButton('Make Changes', Icons.edit, false, _editFlow),
        ActionButton('Start Over', Icons.refresh, false, _startOver),
      ],
    );

    _stage = BuilderStage.confirmation;
  }

  Future<void> _handleClarification(String message) async {
    if (_currentFlow == null) return;

    final lowerMessage = message.toLowerCase();
    bool flowUpdated = false;

    // Handle schedule changes
    if (lowerMessage.contains('daily') || lowerMessage.contains('every day')) {
      _currentFlow = _currentFlow!.copyWith(
        schedule: AgentSchedule(
          interval: const Duration(days: 1),
          preferredTime: _currentFlow!.schedule.preferredTime,
        ),
      );
      flowUpdated = true;
      _addBotMessage("✅ Updated schedule to run daily.");
    } else if (lowerMessage.contains('hourly') || lowerMessage.contains('every hour')) {
      _currentFlow = _currentFlow!.copyWith(
        schedule: AgentSchedule(
          interval: const Duration(hours: 1),
          preferredTime: _currentFlow!.schedule.preferredTime,
        ),
      );
      flowUpdated = true;
      _addBotMessage("✅ Updated schedule to run every hour.");
    } else if (lowerMessage.contains('weekly') || lowerMessage.contains('every week')) {
      _currentFlow = _currentFlow!.copyWith(
        schedule: AgentSchedule(
          interval: const Duration(days: 7),
          preferredTime: _currentFlow!.schedule.preferredTime,
        ),
      );
      flowUpdated = true;
      _addBotMessage("✅ Updated schedule to run weekly.");
    }

    // Handle app additions
    else if (lowerMessage.contains('add') && (lowerMessage.contains('app') || lowerMessage.contains('twitter') || lowerMessage.contains('linkedin'))) {
      List<String> newApps = List.from(_currentFlow!.apps);
      if (lowerMessage.contains('twitter') && !newApps.contains('com.twitter.android')) {
        newApps.add('com.twitter.android');
      }
      if (lowerMessage.contains('linkedin') && !newApps.contains('com.linkedin.android')) {
        newApps.add('com.linkedin.android');
      }
      if (lowerMessage.contains('whatsapp') && !newApps.contains('com.whatsapp')) {
        newApps.add('com.whatsapp');
      }

      if (newApps.length > _currentFlow!.apps.length) {
        _currentFlow = _currentFlow!.copyWith(apps: newApps);
        flowUpdated = true;
        _addBotMessage("✅ Added ${newApps.length - _currentFlow!.apps.length} new app(s) to monitor.");
      }
    }

    // Handle notification changes
    else if (lowerMessage.contains('reduce') && lowerMessage.contains('notification')) {
      Map<String, dynamic> newSettings = Map.from(_currentFlow!.settings);
      newSettings['notify_immediately'] = false;
      newSettings['notification_threshold'] = 'important_only';

      _currentFlow = _currentFlow!.copyWith(settings: newSettings);
      flowUpdated = true;
      _addBotMessage("✅ Reduced notifications to important updates only.");
    }

    // Handle keywords/targets changes
    else if (lowerMessage.contains('keyword') || lowerMessage.contains('target')) {
      // Extract new keywords from the message
      final words = message.split(' ');
      List<String> newKeywords = [];
      for (int i = 0; i < words.length; i++) {
        if ((words[i].toLowerCase() == 'track' || words[i].toLowerCase() == 'watch') && i + 1 < words.length) {
          newKeywords.add(words[i + 1]);
        } else if (words[i].startsWith('@') || words[i].startsWith('#')) {
          newKeywords.add(words[i]);
        }
      }

      if (newKeywords.isNotEmpty) {
        Map<String, dynamic> newSettings = Map.from(_currentFlow!.settings);
        if (newSettings.containsKey('keywords')) {
          List<String> existingKeywords = List<String>.from(newSettings['keywords'] ?? []);
          existingKeywords.addAll(newKeywords);
          newSettings['keywords'] = existingKeywords;
        } else if (newSettings.containsKey('accounts')) {
          List<String> existingAccounts = List<String>.from(newSettings['accounts'] ?? []);
          existingAccounts.addAll(newKeywords);
          newSettings['accounts'] = existingAccounts;
        }

        _currentFlow = _currentFlow!.copyWith(settings: newSettings);
        flowUpdated = true;
        _addBotMessage("✅ Added new targets: ${newKeywords.join(', ')}");
      }
    }

    if (!flowUpdated) {
      _addBotMessage(
        "I'm not sure exactly how to make that change. Could you be more specific? For example:\n\n"
        "• 'Change schedule to daily'\n"
        "• 'Add Twitter to the apps'\n"
        "• 'Track @newcompetitor'\n"
        "• 'Reduce notifications'\n\n"
        "Or try one of the quick options below:",
        quickReplies: [
          'Change schedule to daily',
          'Add Twitter app',
          'Reduce notifications',
          'Track different keywords',
        ],
      );
      return;
    }

    // Show updated flow
    await Future.delayed(const Duration(milliseconds: 500));
    _addBotMessage(
      "Here's your updated agent flow:\n\n"
      "**${_currentFlow!.name}**\n"
      "${_currentFlow!.description}\n\n"
      "• Runs every ${_formatDuration(_currentFlow!.schedule.interval)}\n"
      "• Monitors ${_currentFlow!.apps.length} app(s)\n"
      "• Has ${_currentFlow!.steps.length} action steps\n\n"
      "Want to make more changes or create this agent?",
      actionButtons: [
        ActionButton('Preview Full Flow', Icons.visibility, false, _showFlowPreview),
        ActionButton('Create Agent', Icons.check, true, _createAgent),
        ActionButton('More Changes', Icons.edit, false, _editFlow),
      ],
    );

    _stage = BuilderStage.confirmation;
  }

  Future<void> _handleConfirmation(String message) async {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('yes') || lowerMessage.contains('create') || lowerMessage.contains('good')) {
      _createAgent();
    } else if (lowerMessage.contains('change') || lowerMessage.contains('edit') || lowerMessage.contains('modify')) {
      _editFlow();
    } else {
      _addBotMessage(
        "I'm not sure what you'd like to do. Would you like to:\n"
        "• Create the agent as shown\n"
        "• Make changes to the flow\n"
        "• Start over with a different idea",
        actionButtons: [
          ActionButton('Create Agent', Icons.check, true, _createAgent),
          ActionButton('Make Changes', Icons.edit, false, _editFlow),
          ActionButton('Start Over', Icons.refresh, false, _startOver),
        ],
      );
    }
  }

  AgentFlowBuilder _generateFlowFromConversation() {
    // Analyze conversation to extract intent and requirements
    final conversationText = _messages.where((m) => m.isUser).map((m) => m.text).join(' ').toLowerCase();

    // Determine agent type based on keywords
    if (conversationText.contains('instagram') || conversationText.contains('social')) {
      return _generateSocialMediaFlow(conversationText);
    } else if (conversationText.contains('email') || conversationText.contains('whatsapp') || conversationText.contains('communication')) {
      return _generateCommunicationFlow(conversationText);
    } else if (conversationText.contains('price') || conversationText.contains('shop') || conversationText.contains('deal')) {
      return _generateShoppingFlow(conversationText);
    } else {
      return _generateCustomFlow(conversationText);
    }
  }

  AgentFlowBuilder _generateSocialMediaFlow(String conversationText) {
    // Extract specific details from conversation
    List<String> platforms = [];
    List<String> accounts = [];
    List<String> keywords = [];
    Duration interval = const Duration(hours: 2);

    if (conversationText.contains('instagram')) platforms.add('com.instagram.android');
    if (conversationText.contains('twitter')) platforms.add('com.twitter.android');
    if (conversationText.contains('linkedin')) platforms.add('com.linkedin.android');

    // Extract frequency
    if (conversationText.contains('every hour') || conversationText.contains('hourly')) {
      interval = const Duration(hours: 1);
    } else if (conversationText.contains('daily') || conversationText.contains('every day')) {
      interval = const Duration(hours: 24);
    }

    // Extract account names and keywords from conversation
    final words = conversationText.split(' ');
    for (int i = 0; i < words.length; i++) {
      if (words[i].startsWith('@')) {
        accounts.add(words[i]);
      }
      if (words[i] == 'track' && i + 1 < words.length) {
        keywords.add(words[i + 1]);
      }
    }

    if (accounts.isEmpty) accounts = ['@competitor1', '@competitor2'];
    if (keywords.isEmpty) keywords = ['product launch', 'sale', 'discount'];

    final mainApp = platforms.isNotEmpty ? platforms.first : 'com.instagram.android';

    return AgentFlowBuilder(
      name: 'Social Media Monitor',
      description: 'Monitors ${platforms.length} social media platforms for competitor activity',
      category: 'Social Media',
      steps: [
        FlowStep('Open app', 'Launch ${platforms.join(", ")}',
          type: 'open', app: mainApp),
        FlowStep('Search accounts', 'Find target accounts',
          type: 'tap', target: 'Search'),
        FlowStep('Enter account name', 'Type account to find',
          type: 'type', value: accounts.isNotEmpty ? accounts.first : '@competitor'),
        FlowStep('Wait for results', 'Let search complete',
          type: 'wait', value: '2000'),
        FlowStep('Open profile', 'Tap on account result',
          type: 'tap', target: accounts.isNotEmpty ? accounts.first : 'competitor'),
        FlowStep('Check posts', 'Scroll through recent posts',
          type: 'scroll', value: 'down'),
        FlowStep('Extract content', 'Read post content for keywords',
          type: 'extract', value: keywords.join(',')),
        FlowStep('Save interesting', 'Bookmark posts with keywords',
          type: 'save'),
        FlowStep('Return home', 'Close app',
          type: 'home'),
      ],
      schedule: AgentSchedule(
        interval: interval,
        preferredTime: const TimeOfDay(hour: 9, minute: 0),
      ),
      apps: platforms.isEmpty ? ['com.instagram.android'] : platforms,
      settings: {
        'accounts': accounts,
        'keywords': keywords,
        'notify_immediately': conversationText.contains('notify') || conversationText.contains('alert'),
        'save_screenshots': conversationText.contains('screenshot') || conversationText.contains('save'),
      },
    );
  }

  AgentFlowBuilder _generateCommunicationFlow(String conversationText) {
    List<String> apps = [];
    List<String> actions = [];
    Duration interval = const Duration(hours: 1);

    if (conversationText.contains('email') || conversationText.contains('gmail')) {
      apps.add('com.google.android.gm');
      actions.add('Organize emails by importance');
    }
    if (conversationText.contains('whatsapp')) {
      apps.add('com.whatsapp');
      actions.add('Set up auto-replies');
    }
    if (conversationText.contains('sms') || conversationText.contains('text')) {
      apps.add('com.google.android.apps.messaging');
      actions.add('Filter spam messages');
    }

    if (actions.isEmpty) actions = ['Organize communications', 'Filter important messages'];

    return AgentFlowBuilder(
      name: 'Communication Assistant',
      description: 'Manages and organizes your messages and emails automatically',
      category: 'Communication',
      steps: [
        FlowStep('Open email app', 'Launch Gmail',
          type: 'open', app: apps.isNotEmpty ? apps.first : 'com.google.android.gm'),
        FlowStep('Check inbox', 'Navigate to inbox',
          type: 'tap', target: 'Inbox'),
        FlowStep('Wait for load', 'Let emails load',
          type: 'wait', value: '2000'),
        FlowStep('Read emails', 'Extract email content',
          type: 'extract', value: 'unread,important,urgent'),
        FlowStep('Scroll for more', 'Check more emails',
          type: 'scroll', value: 'down'),
        FlowStep('Return home', 'Close app',
          type: 'home'),
      ],
      schedule: AgentSchedule(
        interval: interval,
        preferredTime: const TimeOfDay(hour: 8, minute: 0),
      ),
      apps: apps.isEmpty ? ['com.google.android.gm'] : apps,
      settings: {
        'important_senders': ['boss@company.com', 'family@gmail.com'],
        'auto_reply_enabled': conversationText.contains('auto') || conversationText.contains('reply'),
        'spam_filter_enabled': conversationText.contains('spam') || conversationText.contains('filter'),
        'notification_threshold': 'high_priority_only',
      },
    );
  }

  AgentFlowBuilder _generateShoppingFlow(String conversationText) {
    List<String> apps = [];
    List<String> products = [];
    double budget = 1000.0;

    if (conversationText.contains('amazon')) apps.add('com.amazon.mShop.android.shopping');
    if (conversationText.contains('flipkart')) apps.add('com.flipkart.android');
    if (conversationText.contains('myntra')) apps.add('com.myntra.android');

    // Extract budget if mentioned
    final budgetMatch = RegExp(r'\$(\d+)').firstMatch(conversationText);
    if (budgetMatch != null) {
      budget = double.tryParse(budgetMatch.group(1)!) ?? 1000.0;
    }

    // Extract product categories
    if (conversationText.contains('phone') || conversationText.contains('iphone')) products.add('smartphones');
    if (conversationText.contains('laptop') || conversationText.contains('computer')) products.add('laptops');
    if (conversationText.contains('electronics')) products.add('electronics');

    if (products.isEmpty) products = ['electronics', 'deals'];

    final mainApp = apps.isNotEmpty ? apps.first : 'com.amazon.mShop.android.shopping';
    final firstProduct = products.isNotEmpty ? products.first : 'product';

    return AgentFlowBuilder(
      name: 'Smart Shopping Assistant',
      description: 'Tracks prices and finds deals for products you want',
      category: 'Shopping',
      steps: [
        FlowStep('Open shopping app', 'Launch ${apps.isEmpty ? "Amazon" : apps.join(", ")}',
          type: 'open', app: mainApp),
        FlowStep('Search for product', 'Find tracked item',
          type: 'tap', target: 'Search'),
        FlowStep('Enter product name', 'Type product to find',
          type: 'type', value: firstProduct),
        FlowStep('Wait for results', 'Let search complete',
          type: 'wait', value: '2000'),
        FlowStep('View product', 'Scroll to see details',
          type: 'scroll', value: 'down'),
        FlowStep('Extract price', 'Read current price',
          type: 'extract', value: '₹,\$,price,stock,available'),
        FlowStep('Return home', 'Close app',
          type: 'home'),
      ],
      schedule: AgentSchedule(
        interval: const Duration(hours: 6),
        preferredTime: const TimeOfDay(hour: 10, minute: 0),
      ),
      apps: apps.isEmpty ? ['com.amazon.mShop.android.shopping'] : apps,
      settings: {
        'tracked_products': products,
        'max_budget': budget,
        'price_drop_threshold': 10.0,
        'deal_categories': products,
        'notify_on_deals': true,
      },
    );
  }

  AgentFlowBuilder _generateCustomFlow(String conversationText) {
    // Fallback for custom requests
    return AgentFlowBuilder(
      name: 'Custom Automation',
      description: 'Custom agent based on your specific requirements',
      category: 'Custom',
      steps: [
        FlowStep('Start automation', 'Initialize custom workflow',
          type: 'wait', value: '1000'),
        FlowStep('Execute main task', 'Perform the primary automation',
          type: 'extract', value: 'status,result,complete'),
        FlowStep('Complete', 'Finish automation',
          type: 'home'),
      ],
      schedule: AgentSchedule(
        interval: const Duration(hours: 4),
        preferredTime: const TimeOfDay(hour: 12, minute: 0),
      ),
      apps: ['com.android.chrome'],
      settings: {
        'custom_requirements': conversationText,
        'user_defined': true,
      },
    );
  }

  void _addBotMessage(String text, {
    List<String> quickReplies = const [],
    List<ActionButton> actionButtons = const [],
    bool showQuickReplies = false,
  }) {
    final message = ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      quickReplies: showQuickReplies ? _getDefaultQuickReplies() : quickReplies,
      actionButtons: actionButtons,
    );

    setState(() {
      _messages.add(message);
    });

    _scrollToBottom();
  }

  List<String> _getDefaultQuickReplies() {
    return [
      'Monitor Instagram competitors',
      'Organize my emails automatically',
      'Track prices on Amazon',
      'WhatsApp auto-replies',
      'Something else...',
    ];
  }

  String _getInputHint() {
    switch (_stage) {
      case BuilderStage.introduction:
        return 'Describe what you want to automate...';
      case BuilderStage.gatheringRequirements:
        return 'Tell me more details...';
      case BuilderStage.clarification:
        return 'Clarify your requirements...';
      case BuilderStage.confirmation:
        return 'Any changes or shall I create it?';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showFlowPreview() {
    if (_currentFlow == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(_currentFlow!.category),
                          color: const Color(0xFF6366F1),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentFlow!.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentFlow!.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Schedule info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, size: 20, color: Color(0xFF6366F1)),
                        const SizedBox(width: 12),
                        Text(
                          'Runs every ${_formatDuration(_currentFlow!.schedule.interval)} starting at ${_formatTimeOfDay(_currentFlow!.schedule.preferredTime) ?? "any time"}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Steps
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _currentFlow!.steps.length,
                itemBuilder: (context, index) {
                  final step = _currentFlow!.steps[index];
                  final isLast = index == _currentFlow!.steps.length - 1;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step indicator
                        Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 40,
                                color: Colors.grey[300],
                                margin: const EdgeInsets.symmetric(vertical: 8),
                              ),
                          ],
                        ),

                        const SizedBox(width: 16),

                        // Step content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                step.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _editFlow();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Edit Flow'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _createAgent();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Create Agent'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'social media':
        return Icons.social_distance;
      case 'communication':
        return Icons.email;
      case 'shopping':
        return Icons.shopping_cart;
      default:
        return Icons.smart_toy;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours >= 24) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours >= 1) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }

  String? _formatTimeOfDay(TimeOfDay? timeOfDay) {
    if (timeOfDay == null) return null;
    return '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}';
  }

  void _editFlow() {
    _addBotMessage(
      "What would you like to change about the agent flow? I can adjust:\n\n"
      "• **Schedule**: Currently runs every ${_formatDuration(_currentFlow!.schedule.interval)}\n"
      "• **Apps**: Currently monitors ${_currentFlow!.apps.length} app(s)\n"
      "• **Actions**: Currently has ${_currentFlow!.steps.length} steps\n"
      "• **Notifications**: When and how you get notified\n"
      "• **Settings**: Specific targets, keywords, or thresholds\n\n"
      "Tell me specifically what you'd like to change, or use the quick options below:",
      quickReplies: [
        'Change schedule to daily',
        'Add more apps',
        'Reduce notifications',
        'Add more steps',
        'Change targets/keywords',
      ],
    );
    _stage = BuilderStage.clarification;
  }

  void _createAgent() async {
    if (_currentFlow == null) return;

    _addBotMessage("Creating your agent... ⚡");

    try {
      // Create the actual agent using AgentLib based on the flow
      await _createActualAgent(_currentFlow!);

      await Future.delayed(const Duration(milliseconds: 1500));

      _addBotMessage(
        "🎉 Your agent has been created successfully!\n\n"
        "✅ **${_currentFlow!.name}**\n"
        "${_currentFlow!.description}\n\n"
        "**Next steps:**\n"
        "• Your agent is now active and will start working in the background\n"
        "• Check the Agents dashboard to monitor its progress\n"
        "• You'll receive notifications when it finds something interesting\n"
        "• You can pause, edit, or delete the agent anytime\n\n"
        "Need another agent? Just start a new conversation!",
        actionButtons: [
          ActionButton('View in Dashboard', Icons.dashboard, true, () {
            Navigator.pop(context);
          }),
          ActionButton('Create Another', Icons.add, false, _startOver),
        ],
      );
    } catch (e) {
      _addBotMessage(
        "❌ There was an error creating your agent: ${e.toString()}\n\n"
        "Don't worry! You can try again or contact support if the problem persists.",
        actionButtons: [
          ActionButton('Try Again', Icons.refresh, true, () => _createAgent()),
          ActionButton('Start Over', Icons.restart_alt, false, _startOver),
        ],
      );
    }
  }

  Future<void> _createActualAgent(AgentFlowBuilder flow) async {
    try {
      // Convert conversation flow to actual AgentLib agent
      switch (flow.category.toLowerCase()) {
        case 'social media':
          await _createSocialMediaAgent(flow);
          break;
        case 'communication':
          await _createCommunicationAgent(flow);
          break;
        case 'shopping':
          await _createShoppingAgent(flow);
          break;
        default:
          await _createCustomAgent(flow);
          break;
      }
    } catch (e) {
      debugPrint('Error creating agent: $e');
      rethrow; // Re-throw to be handled by calling method
    }
  }

  Future<void> _createSocialMediaAgent(AgentFlowBuilder flow) async {
    try {
      // Create appropriate social media agent based on the flow
      if (flow.apps.contains('com.instagram.android')) {
        // Create Instagram monitoring agent
        final agent = InstagramWatcherAgent(
          accountsToWatch: List<String>.from(flow.settings['accounts'] ?? ['@competitor']),
          interestKeywords: List<String>.from(flow.settings['keywords'] ?? ['product']),
          saveStories: flow.settings['save_screenshots'] ?? true,
          trackFollowers: flow.settings['track_followers'] ?? false,
        );
        await agent.initialize();
        await TaskScheduler.instance.registerAgent(agent);
        debugPrint('✅ Created Instagram monitoring agent successfully');
      }

      if (flow.apps.contains('com.twitter.android')) {
        // Create Twitter monitoring agent
        final agent = TwitterMonitorAgent(
          hashtagsToWatch: List<String>.from(flow.settings['keywords'] ?? ['#flutter', '#AI']),
          accountsToWatch: List<String>.from(flow.settings['accounts'] ?? []),
          keywordsToTrack: List<String>.from(flow.settings['keywords'] ?? ['flutter', 'AI']),
        );
        await agent.initialize();
        await TaskScheduler.instance.registerAgent(agent);
        debugPrint('✅ Created Twitter monitoring agent successfully');
      }
    } catch (e) {
      debugPrint('❌ Error creating social media agent: $e');
      rethrow;
    }
  }

  Future<void> _createCommunicationAgent(AgentFlowBuilder flow) async {
    try {
      if (flow.apps.contains('com.google.android.gm')) {
        // Create email triage agent
        final agent = EmailTriageAgent(
          importantSenders: List<String>.from(flow.settings['important_senders'] ?? ['boss@company.com']),
          spamKeywords: List<String>.from(flow.settings['spam_keywords'] ?? ['spam', 'promotion']),
          newsletterSenders: List<String>.from(flow.settings['newsletter_senders'] ?? []),
          autoArchiveOld: flow.settings['auto_archive_enabled'] ?? true,
          createCalendarEvents: flow.settings['create_calendar_events'] ?? false,
        );
        await agent.initialize();
        await TaskScheduler.instance.registerAgent(agent);
        debugPrint('✅ Created email triage agent successfully');
      }

      if (flow.apps.contains('com.whatsapp')) {
        // Create WhatsApp management agent
        final agent = WhatsAppManagerAgent(
          importantContacts: List<String>.from(flow.settings['vip_contacts'] ?? ['Family', 'Work']),
          autoReplies: Map<String, String>.from(flow.settings['auto_replies'] ?? {'default': 'I\'ll get back to you soon!'}),
        );
        await agent.initialize();
        await TaskScheduler.instance.registerAgent(agent);
        debugPrint('✅ Created WhatsApp management agent successfully');
      }
    } catch (e) {
      debugPrint('❌ Error creating communication agent: $e');
      rethrow;
    }
  }

  Future<void> _createShoppingAgent(AgentFlowBuilder flow) async {
    try {
      if (flow.apps.contains('com.amazon.mShop.android.shopping') ||
          flow.apps.contains('com.flipkart.android') ||
          flow.apps.isNotEmpty) {
        // Create price watching agent
        final Map<String, List<String>> productsMap = {};
        final trackedProducts = List<String>.from(flow.settings['tracked_products'] ?? ['iPhone', 'laptop']);

        // Map products to apps
        for (final app in flow.apps) {
          productsMap[app] = trackedProducts;
        }

        final agent = PriceWatcherAgent(
          productsToWatch: productsMap,
          maxPriceDropPercent: flow.settings['price_drop_threshold']?.toDouble() ?? 10.0,
          notifyOnStockAvailable: flow.settings['notify_on_stock'] ?? true,
          trackPriceHistory: flow.settings['track_history'] ?? true,
        );
        await agent.initialize();
        await TaskScheduler.instance.registerAgent(agent);
        debugPrint('✅ Created price watching agent successfully');
      }
    } catch (e) {
      debugPrint('❌ Error creating shopping agent: $e');
      rethrow;
    }
  }

  Future<void> _createCustomAgent(AgentFlowBuilder flow) async {
    try {
      // Create a generic custom agent
      final agent = CustomAutomationAgent(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: flow.name,
        description: flow.description,
        targetApps: flow.apps,
        agentSchedule: flow.schedule,
        customSteps: flow.steps,
        agentSettings: flow.settings,
      );
      await agent.initialize();
      await TaskScheduler.instance.registerAgent(agent);
      debugPrint('✅ Created custom automation agent successfully');
    } catch (e) {
      debugPrint('❌ Error creating custom agent: $e');
      rethrow;
    }
  }

  void _startOver() {
    setState(() {
      _messages.clear();
      _currentFlow = null;
      _stage = BuilderStage.introduction;
    });
    _startConversation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}

// Data models
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> quickReplies;
  final List<ActionButton> actionButtons;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.quickReplies = const [],
    this.actionButtons = const [],
  });
}

class ActionButton {
  final String text;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onPressed;

  ActionButton(this.text, this.icon, this.isPrimary, this.onPressed);
}

class AgentFlowBuilder {
  final String name;
  final String description;
  final String category;
  final List<FlowStep> steps;
  final AgentSchedule schedule;
  final List<String> apps;
  final Map<String, dynamic> settings;

  AgentFlowBuilder({
    required this.name,
    required this.description,
    required this.category,
    required this.steps,
    required this.schedule,
    required this.apps,
    required this.settings,
  });

  AgentFlowBuilder copyWith({
    String? name,
    String? description,
    String? category,
    List<FlowStep>? steps,
    AgentSchedule? schedule,
    List<String>? apps,
    Map<String, dynamic>? settings,
  }) {
    return AgentFlowBuilder(
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      steps: steps ?? this.steps,
      schedule: schedule ?? this.schedule,
      apps: apps ?? this.apps,
      settings: settings ?? this.settings,
    );
  }
}

class FlowStep {
  final String title;
  final String description;
  final String type; // open, tap, type, scroll, wait, wait_for, extract, back, home, save
  final String? app; // Package name of target app
  final String? target; // Element to find/tap (text or description)
  final String? value; // Value for type actions or keywords for extract

  FlowStep(
    this.title,
    this.description, {
    this.type = 'tap',
    this.app,
    this.target,
    this.value,
  });

  String get name => title;
}

class AgentSchedule {
  final Duration interval;
  final TimeOfDay? preferredTime;

  const AgentSchedule({
    required this.interval,
    this.preferredTime,
  });
}

enum BuilderStage {
  introduction,
  gatheringRequirements,
  clarification,
  confirmation,
}