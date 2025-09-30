import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'voice_input_widget.dart';
import 'voice_input_service.dart';
import '../ai_assistant_home.dart';

class VoiceChatWidget extends StatefulWidget {
  final Function(String) onMessageSent;
  final Function(String)? onVoiceCommand;
  final bool showVoiceButton;
  final bool autoSendVoiceInput;
  final bool enableWakeWord;
  final String? wakeWord;
  final VoiceInputConfig? voiceConfig;

  const VoiceChatWidget({
    Key? key,
    required this.onMessageSent,
    this.onVoiceCommand,
    this.showVoiceButton = true,
    this.autoSendVoiceInput = true,
    this.enableWakeWord = false,
    this.wakeWord = 'hey assistant',
    this.voiceConfig,
  }) : super(key: key);

  @override
  State<VoiceChatWidget> createState() => _VoiceChatWidgetState();
}

class _VoiceChatWidgetState extends State<VoiceChatWidget>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isVoiceMode = false;
  bool _isListening = false;
  String _voiceText = '';
  String _partialText = '';

  late AnimationController _voiceButtonController;
  late AnimationController _chatBubbleController;
  late Animation<double> _voiceButtonAnimation;
  late Animation<Offset> _chatBubbleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _voiceButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _chatBubbleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _voiceButtonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _voiceButtonController,
      curve: Curves.elasticOut,
    ));

    _chatBubbleAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _chatBubbleController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _toggleVoiceMode() {
    setState(() {
      _isVoiceMode = !_isVoiceMode;
    });

    if (_isVoiceMode) {
      _voiceButtonController.forward();
      _chatBubbleController.forward();
      _focusNode.unfocus();
    } else {
      _voiceButtonController.reverse();
      _chatBubbleController.reverse();
    }
  }

  void _handleVoiceInput(String text) {
    setState(() {
      _voiceText = text;
      _partialText = '';
      _isListening = false;
    });

    if (widget.autoSendVoiceInput && text.isNotEmpty) {
      _sendMessage(text);
    } else {
      // Show confirmation dialog
      _showVoiceConfirmationDialog(text);
    }
  }

  void _handlePartialInput(String text) {
    setState(() {
      _partialText = text;
    });
  }

  void _handleVoiceCommand(String command) {
    widget.onVoiceCommand?.call(command);

    // Handle built-in voice commands
    final lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('send message') ||
        lowerCommand.contains('text message')) {
      _toggleVoiceMode();
    } else if (lowerCommand.contains('clear chat') ||
               lowerCommand.contains('clear conversation')) {
      // Clear chat functionality would be handled by parent
    } else if (lowerCommand.contains('stop listening') ||
               lowerCommand.contains('cancel')) {
      _toggleVoiceMode();
    }
  }

  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;

    widget.onMessageSent(message);
    _textController.clear();
    setState(() {
      _voiceText = '';
      _partialText = '';
    });

    if (_isVoiceMode) {
      _toggleVoiceMode();
    }
  }

  void _showVoiceConfirmationDialog(String text) {
    showDialog(
      context: context,
      builder: (context) => VoiceConfirmationDialog(
        voiceText: text,
        onConfirm: () {
          Navigator.of(context).pop();
          _sendMessage(text);
        },
        onEdit: () {
          Navigator.of(context).pop();
          _textController.text = text;
          setState(() {
            _isVoiceMode = false;
          });
          _voiceButtonController.reverse();
          _chatBubbleController.reverse();
          _focusNode.requestFocus();
        },
        onCancel: () {
          Navigator.of(context).pop();
          setState(() {
            _voiceText = '';
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voice input area (when in voice mode)
          if (_isVoiceMode) ...[
            SlideTransition(
              position: _chatBubbleAnimation,
              child: _buildVoiceInputArea(theme),
            ),
            const SizedBox(height: 16),
          ],

          // Text input area
          if (!_isVoiceMode || !widget.autoSendVoiceInput)
            _buildTextInputArea(theme),

          // Voice button and controls
          if (widget.showVoiceButton) ...[
            const SizedBox(height: 12),
            _buildVoiceControls(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceInputArea(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: VoiceInputWidget(
        onVoiceInput: _handleVoiceInput,
        onPartialInput: _handlePartialInput,
        onListeningStart: () {
          setState(() {
            _isListening = true;
          });
        },
        onListeningStop: () {
          setState(() {
            _isListening = false;
          });
        },
        showWaveform: true,
        showTranscription: true,
        primaryColor: theme.colorScheme.primary,
        secondaryColor: theme.colorScheme.secondary,
      ),
    );
  }

  Widget _buildTextInputArea(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: _voiceText.isNotEmpty
                    ? 'Voice input: ${_voiceText}'
                    : 'Type your message...',
                hintStyle: TextStyle(
                  color: _voiceText.isNotEmpty
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                  fontStyle: _voiceText.isNotEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: _sendMessage,
            ),
          ),
          IconButton(
            onPressed: () {
              final text = _textController.text.trim();
              if (text.isNotEmpty) {
                _sendMessage(text);
              } else if (_voiceText.isNotEmpty) {
                _sendMessage(_voiceText);
              }
            },
            icon: Icon(
              Icons.send,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceControls(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Voice mode toggle button
        ScaleTransition(
          scale: _voiceButtonAnimation,
          child: FloatingActionButton(
            onPressed: _toggleVoiceMode,
            backgroundColor: _isVoiceMode
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            foregroundColor: _isVoiceMode
                ? Colors.white
                : theme.colorScheme.onSurface,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isVoiceMode ? Icons.keyboard : Icons.mic,
                key: ValueKey(_isVoiceMode),
              ),
            ),
          ),
        ),

        if (_isVoiceMode) ...[
          const SizedBox(width: 16),
          // Voice status indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: _isListening
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isListening
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isListening) ...[
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  _isListening
                      ? 'Listening...'
                      : _partialText.isNotEmpty
                          ? 'Processing...'
                          : 'Voice Ready',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _isListening
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _voiceButtonController.dispose();
    _chatBubbleController.dispose();
    super.dispose();
  }
}

class VoiceConfirmationDialog extends StatelessWidget {
  final String voiceText;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  const VoiceConfirmationDialog({
    Key? key,
    required this.voiceText,
    required this.onConfirm,
    required this.onEdit,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        'Voice Input',
        style: theme.textTheme.headlineSmall,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'I heard:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              voiceText,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Would you like to send this message?',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(
            'Cancel',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        TextButton(
          onPressed: onEdit,
          child: Text(
            'Edit',
            style: TextStyle(
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
        FilledButton(
          onPressed: onConfirm,
          child: const Text('Send'),
        ),
      ],
    );
  }
}