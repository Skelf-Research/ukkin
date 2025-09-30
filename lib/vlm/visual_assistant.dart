import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'vlm_service.dart';
import 'screen_understanding_widget.dart';

class VisualAssistant extends StatefulWidget {
  final Function(String)? onTaskComplete;
  final Function(String)? onError;
  final bool enableProactiveHelp;
  final bool enableAccessibilityAssist;
  final bool enableContextAwareness;

  const VisualAssistant({
    Key? key,
    this.onTaskComplete,
    this.onError,
    this.enableProactiveHelp = true,
    this.enableAccessibilityAssist = true,
    this.enableContextAwareness = true,
  }) : super(key: key);

  @override
  State<VisualAssistant> createState() => _VisualAssistantState();
}

class _VisualAssistantState extends State<VisualAssistant> {
  final VLMService _vlmService = VLMService();
  final TextEditingController _taskController = TextEditingController();

  VLMScreenAnalysis? _currentScreenAnalysis;
  List<VLMAction> _suggestedActions = [];
  List<String> _contextHistory = [];
  bool _isProcessing = false;
  String? _currentTask;
  Timer? _contextTimer;

  @override
  void initState() {
    super.initState();
    _initializeAssistant();
  }

  Future<void> _initializeAssistant() async {
    try {
      await _vlmService.initialize();

      if (widget.enableContextAwareness) {
        _startContextMonitoring();
      }
    } catch (e) {
      widget.onError?.call('Failed to initialize visual assistant: $e');
    }
  }

  void _startContextMonitoring() {
    _contextTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _updateContext();
    });
  }

  Future<void> _updateContext() async {
    try {
      final screenshotPath = await _captureScreen();
      if (screenshotPath != null) {
        final analysis = await _vlmService.analyzeScreen(screenshotPath);

        setState(() {
          _currentScreenAnalysis = analysis;
        });

        // Update context history
        final contextEntry = '${analysis.appName}: ${analysis.screenType}';
        if (_contextHistory.isEmpty || _contextHistory.last != contextEntry) {
          _contextHistory.add(contextEntry);

          // Keep only recent context (last 10 entries)
          if (_contextHistory.length > 10) {
            _contextHistory.removeAt(0);
          }
        }

        // Proactive help
        if (widget.enableProactiveHelp) {
          await _checkForProactiveHelp(analysis);
        }
      }
    } catch (e) {
      debugPrint('Context update failed: $e');
    }
  }

  Future<void> _checkForProactiveHelp(VLMScreenAnalysis analysis) async {
    // Check for common user frustrations or opportunities to help
    final helpReasons = <String>[];

    // Check for accessibility issues
    if (widget.enableAccessibilityAssist) {
      if (analysis.accessibility.overallScore < 0.7) {
        helpReasons.add('accessibility issues detected');
      }
    }

    // Check for error states
    if (analysis.extractedText.toLowerCase().contains('error') ||
        analysis.extractedText.toLowerCase().contains('failed') ||
        analysis.extractedText.toLowerCase().contains('problem')) {
      helpReasons.add('error state detected');
    }

    // Check for form completion opportunities
    final textFields = analysis.uiElements
        .where((element) => element.type.toLowerCase().contains('textfield'))
        .length;

    if (textFields > 2) {
      helpReasons.add('multiple form fields detected');
    }

    // Offer help if reasons found
    if (helpReasons.isNotEmpty) {
      _showProactiveHelp(helpReasons);
    }
  }

  void _showProactiveHelp(List<String> reasons) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🤖 Visual Assistant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('I noticed I might be able to help with:'),
            const SizedBox(height: 8),
            ...reasons.map((reason) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Text('• '),
                  Expanded(child: Text(reason)),
                ],
              ),
            )),
            const SizedBox(height: 16),
            const Text('Would you like me to assist you?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No Thanks'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showAssistanceOptions();
            },
            child: const Text('Help Me'),
          ),
        ],
      ),
    );
  }

  void _showAssistanceOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'How can I help?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildAssistanceOption(
                      icon: Icons.auto_fix_high,
                      title: 'Complete This Form',
                      description: 'I can help fill out forms automatically',
                      onTap: () => _handleFormCompletion(),
                    ),
                    _buildAssistanceOption(
                      icon: Icons.accessibility,
                      title: 'Improve Accessibility',
                      description: 'Make this screen more accessible',
                      onTap: () => _handleAccessibilityImprovement(),
                    ),
                    _buildAssistanceOption(
                      icon: Icons.text_fields,
                      title: 'Read Screen Content',
                      description: 'I can read all text on this screen',
                      onTap: () => _handleScreenReading(),
                    ),
                    _buildAssistanceOption(
                      icon: Icons.touch_app,
                      title: 'Suggest Actions',
                      description: 'Show what you can do on this screen',
                      onTap: () => _handleActionSuggestions(),
                    ),
                    _buildAssistanceOption(
                      icon: Icons.help_outline,
                      title: 'Explain This Screen',
                      description: 'Tell me what this screen is for',
                      onTap: () => _handleScreenExplanation(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssistanceOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(description),
        onTap: () {
          Navigator.of(context).pop();
          onTap();
        },
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }

  Future<void> _handleFormCompletion() async {
    if (_currentScreenAnalysis == null) return;

    final textFields = _currentScreenAnalysis!.uiElements
        .where((element) => element.type.toLowerCase().contains('textfield'))
        .toList();

    if (textFields.isEmpty) {
      _showMessage('No form fields detected on this screen.');
      return;
    }

    // Show form completion dialog
    _showFormCompletionDialog(textFields);
  }

  void _showFormCompletionDialog(List<VLMUIElement> textFields) {
    showDialog(
      context: context,
      builder: (context) => FormCompletionDialog(
        textFields: textFields,
        onComplete: (completionData) {
          Navigator.of(context).pop();
          _executeFormCompletion(completionData);
        },
      ),
    );
  }

  Future<void> _executeFormCompletion(Map<String, String> completionData) async {
    setState(() {
      _isProcessing = true;
      _currentTask = 'Completing form...';
    });

    try {
      // Execute form completion actions
      for (final entry in completionData.entries) {
        final fieldId = entry.key;
        final value = entry.value;

        // Find the field and fill it
        await _fillTextField(fieldId, value);
        await Future.delayed(const Duration(milliseconds: 500));
      }

      widget.onTaskComplete?.call('Form completed successfully');
    } catch (e) {
      widget.onError?.call('Form completion failed: $e');
    } finally {
      setState(() {
        _isProcessing = false;
        _currentTask = null;
      });
    }
  }

  Future<void> _fillTextField(String fieldId, String value) async {
    // Use platform channel to interact with the field
    try {
      await SystemChannels.platform.invokeMethod('fillTextField', {
        'fieldId': fieldId,
        'value': value,
      });
    } catch (e) {
      debugPrint('Failed to fill text field: $e');
    }
  }

  Future<void> _handleAccessibilityImprovement() async {
    if (_currentScreenAnalysis == null) return;

    final accessibility = _currentScreenAnalysis!.accessibility;

    if (accessibility.issues.isEmpty) {
      _showMessage('No accessibility issues detected on this screen.');
      return;
    }

    _showAccessibilityReport(accessibility);
  }

  void _showAccessibilityReport(VLMAccessibilityAnalysis accessibility) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accessibility Report'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Score: ${(accessibility.overallScore * 100).toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Issues Found:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: accessibility.issues.length,
                  itemBuilder: (context, index) {
                    final issue = accessibility.issues[index];
                    return ListTile(
                      leading: Icon(
                        _getSeverityIcon(issue.severity),
                        color: _getSeverityColor(issue.severity),
                      ),
                      title: Text(issue.type),
                      subtitle: Text(issue.description),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyAccessibilityFixes(accessibility);
            },
            child: const Text('Apply Fixes'),
          ),
        ],
      ),
    );
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Icons.error;
      case 'medium':
        return Icons.warning;
      case 'low':
        return Icons.info;
      default:
        return Icons.help;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _applyAccessibilityFixes(VLMAccessibilityAnalysis accessibility) async {
    setState(() {
      _isProcessing = true;
      _currentTask = 'Applying accessibility fixes...';
    });

    try {
      // Apply accessibility improvements
      for (final issue in accessibility.issues) {
        await _applyAccessibilityFix(issue);
        await Future.delayed(const Duration(milliseconds: 300));
      }

      widget.onTaskComplete?.call('Accessibility improvements applied');
    } catch (e) {
      widget.onError?.call('Failed to apply accessibility fixes: $e');
    } finally {
      setState(() {
        _isProcessing = false;
        _currentTask = null;
      });
    }
  }

  Future<void> _applyAccessibilityFix(VLMAccessibilityIssue issue) async {
    // Apply specific accessibility fixes based on issue type
    try {
      await SystemChannels.platform.invokeMethod('applyAccessibilityFix', {
        'issueType': issue.type,
        'location': issue.location?.toMap(),
        'description': issue.description,
      });
    } catch (e) {
      debugPrint('Failed to apply accessibility fix: $e');
    }
  }

  Future<void> _handleScreenReading() async {
    if (_currentScreenAnalysis == null) return;

    final extractedText = _currentScreenAnalysis!.extractedText;

    if (extractedText.isEmpty) {
      _showMessage('No text detected on this screen.');
      return;
    }

    _showScreenTextDialog(extractedText);
  }

  void _showScreenTextDialog(String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Screen Content'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Text(text),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.of(context).pop();
              _showMessage('Text copied to clipboard');
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleActionSuggestions() async {
    if (_currentScreenAnalysis == null) return;

    final actions = _currentScreenAnalysis!.suggestedActions;

    if (actions.isEmpty) {
      _showMessage('No actions suggested for this screen.');
      return;
    }

    setState(() {
      _suggestedActions = actions;
    });

    _showActionSuggestionsDialog(actions);
  }

  void _showActionSuggestionsDialog(List<VLMAction> actions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suggested Actions'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: VLMActionExecutor(
            actions: actions,
            onActionExecute: (action) {
              Navigator.of(context).pop();
              _executeAction(action);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeAction(VLMAction action) async {
    setState(() {
      _isProcessing = true;
      _currentTask = 'Executing ${action.type}...';
    });

    try {
      await SystemChannels.platform.invokeMethod('executeAction', {
        'type': action.type,
        'targetArea': action.targetArea?.toMap(),
        'parameters': action.parameters,
      });

      widget.onTaskComplete?.call('Action executed: ${action.description}');
    } catch (e) {
      widget.onError?.call('Action execution failed: $e');
    } finally {
      setState(() {
        _isProcessing = false;
        _currentTask = null;
      });
    }
  }

  Future<void> _handleScreenExplanation() async {
    if (_currentScreenAnalysis == null) return;

    setState(() {
      _isProcessing = true;
      _currentTask = 'Analyzing screen...';
    });

    try {
      final explanation = await _vlmService.analyzeImage(
        '', // Screenshot path would be provided
        prompt: 'Explain what this screen is for, what the user can do here, and provide helpful context about the app functionality.',
      );

      _showScreenExplanationDialog(explanation);
    } catch (e) {
      widget.onError?.call('Screen explanation failed: $e');
    } finally {
      setState(() {
        _isProcessing = false;
        _currentTask = null;
      });
    }
  }

  void _showScreenExplanationDialog(String explanation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Screen Explanation'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Text(explanation),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<String?> _captureScreen() async {
    try {
      final result = await SystemChannels.platform.invokeMethod('captureScreen');
      return result as String?;
    } catch (e) {
      debugPrint('Screen capture failed: $e');
      return null;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Processing indicator
          if (_isProcessing) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _currentTask ?? 'Processing...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Quick actions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleScreenReading,
                icon: const Icon(Icons.text_fields),
                label: const Text('Read Screen'),
              ),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleActionSuggestions,
                icon: const Icon(Icons.touch_app),
                label: const Text('Suggest Actions'),
              ),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleScreenExplanation,
                icon: const Icon(Icons.help_outline),
                label: const Text('Explain'),
              ),
            ],
          ),

          // Context information
          if (_currentScreenAnalysis != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Context',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'App: ${_currentScreenAnalysis!.appName}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Screen: ${_currentScreenAnalysis!.screenType}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Elements: ${_currentScreenAnalysis!.uiElements.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _contextTimer?.cancel();
    _taskController.dispose();
    _vlmService.dispose();
    super.dispose();
  }
}

class FormCompletionDialog extends StatefulWidget {
  final List<VLMUIElement> textFields;
  final Function(Map<String, String>) onComplete;

  const FormCompletionDialog({
    Key? key,
    required this.textFields,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<FormCompletionDialog> createState() => _FormCompletionDialogState();
}

class _FormCompletionDialogState extends State<FormCompletionDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _fieldTypes = {};

  @override
  void initState() {
    super.initState();

    for (final field in widget.textFields) {
      _controllers[field.text] = TextEditingController();
      _fieldTypes[field.text] = _guessFieldType(field.text);
    }
  }

  String _guessFieldType(String fieldText) {
    final text = fieldText.toLowerCase();

    if (text.contains('email')) return 'email';
    if (text.contains('name')) return 'name';
    if (text.contains('phone')) return 'phone';
    if (text.contains('address')) return 'address';
    if (text.contains('city')) return 'city';
    if (text.contains('password')) return 'password';

    return 'text';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Complete Form'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: widget.textFields.length,
          itemBuilder: (context, index) {
            final field = widget.textFields[index];
            final controller = _controllers[field.text]!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: field.text,
                  border: const OutlineInputBorder(),
                ),
                obscureText: _fieldTypes[field.text] == 'password',
                keyboardType: _getKeyboardType(_fieldTypes[field.text]!),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final data = <String, String>{};
            for (final entry in _controllers.entries) {
              data[entry.key] = entry.value.text;
            }
            widget.onComplete(data);
          },
          child: const Text('Complete'),
        ),
      ],
    );
  }

  TextInputType _getKeyboardType(String fieldType) {
    switch (fieldType) {
      case 'email':
        return TextInputType.emailAddress;
      case 'phone':
        return TextInputType.phone;
      case 'number':
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}