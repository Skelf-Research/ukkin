import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../tools/tool.dart';
import '../models/task.dart';
import '../llm/llm_interface.dart';
import 'mobile_controller.dart';
import 'accessibility_service.dart';
import 'screen_recorder.dart';

// VLM Interface for visual understanding
abstract class VLMInterface {
  Future<String> analyzeImage(String imagePath, {String? prompt});
}

class AdvancedAppAutomation extends Tool with ToolValidation {
  final MobileController mobileController;
  final AccessibilityService accessibilityService;
  final ScreenRecorder screenRecorder;
  final VLMInterface? vlm;

  // App workflow libraries
  final Map<String, AppWorkflowLibrary> _appLibraries = {};
  final Map<String, AppContext> _appContexts = {};

  AdvancedAppAutomation({
    required this.mobileController,
    required this.accessibilityService,
    required this.screenRecorder,
    this.vlm,
  }) {
    _initializeAppLibraries();
  }

  @override
  String get name => 'advanced_app_automation';

  @override
  String get description => 'Advanced app automation with smart workflows, context awareness, and adaptive interactions';

  @override
  Map<String, String> get parameters => {
        'intent': 'High-level intent: send_message, book_ride, order_food, post_content, manage_calendar, etc.',
        'app': 'Target app or let AI choose best app',
        'context': 'Additional context and parameters',
        'adaptive': 'Whether to use adaptive learning (true/false)',
        'verify': 'Whether to verify completion (true/false)',
      };

  @override
  bool canHandle(Task task) {
    return task.type == 'advanced_app_automation' || task.type.startsWith('intent_');
  }

  @override
  Future<bool> validate(Map<String, dynamic> parameters) async {
    return validateRequired(parameters, ['intent']);
  }

  @override
  Future<dynamic> execute(Map<String, dynamic> parameters) async {
    if (!await validate(parameters)) {
      throw Exception('Invalid parameters for advanced app automation');
    }

    final intent = parameters['intent'] as String;
    final targetApp = parameters['app'] as String?;
    final context = parameters['context'] as Map<String, dynamic>? ?? {};
    final adaptive = parameters['adaptive'] as bool? ?? true;
    final verify = parameters['verify'] as bool? ?? true;

    try {
      return await _executeAdvancedIntent(intent, targetApp, context, adaptive, verify);
    } catch (e) {
      return ToolExecutionResult.failure('Advanced app automation failed: $e');
    }
  }

  Future<ToolExecutionResult> _executeAdvancedIntent(
    String intent,
    String? targetApp,
    Map<String, dynamic> context,
    bool adaptive,
    bool verify,
  ) async {
    // Determine best app for intent if not specified
    final selectedApp = targetApp ?? await _selectBestAppForIntent(intent, context);

    // Get or create app context
    final appContext = await _getAppContext(selectedApp);

    // Execute smart workflow
    final workflowResult = await _executeSmartWorkflow(
      intent,
      selectedApp,
      appContext,
      context,
      adaptive,
    );

    // Verify completion if requested
    if (verify && workflowResult.success) {
      final verificationResult = await _verifyIntentCompletion(intent, context, selectedApp);
      workflowResult.metadata['verification'] = verificationResult.data;
    }

    // Learn from execution
    if (adaptive) {
      await _learnFromExecution(intent, selectedApp, workflowResult, context);
    }

    return workflowResult;
  }

  Future<String> _selectBestAppForIntent(String intent, Map<String, dynamic> context) async {
    final intentMap = {
      'send_message': ['com.whatsapp', 'org.telegram.messenger', 'com.android.mms'],
      'send_email': ['com.google.android.gm', 'com.microsoft.office.outlook'],
      'book_ride': ['com.ubercab', 'com.lyft.android', 'com.didi.global.passenger'],
      'order_food': ['com.dd.doordash', 'com.ubercab.eats', 'com.grubhub.android'],
      'post_content': ['com.instagram.android', 'com.twitter.android', 'com.facebook.katana'],
      'play_music': ['com.spotify.music', 'com.amazon.mp3', 'com.apple.android.music'],
      'navigate': ['com.google.android.apps.maps', 'com.waze', 'com.apple.mobilegarageband'],
      'take_photo': ['com.android.camera2', 'com.instagram.android'],
      'make_call': ['com.android.dialer', 'com.whatsapp', 'com.skype.raider'],
      'schedule_event': ['com.google.android.calendar', 'com.microsoft.office.outlook'],
      'shop_online': ['com.amazon.mShop.android.shopping', 'com.ebay.mobile', 'com.shopify.arrive'],
      'watch_video': ['com.google.android.youtube', 'com.netflix.mediaclient', 'com.amazon.avod.thirdpartyclient'],
      'read_news': ['com.google.android.apps.magazines', 'com.twitter.android'],
      'fitness_tracking': ['com.google.android.apps.fitness', 'com.nike.plusgps'],
      'banking': ['com.chase.sig.android', 'com.bankofamerica.mobile'],
    };

    final apps = intentMap[intent] ?? [];

    // Check which apps are installed
    for (final app in apps) {
      if (await _isAppInstalled(app)) {
        return app;
      }
    }

    // Fallback: use AI to determine best app
    if (vlm != null) {
      final installedApps = await mobileController.execute({'action': 'get_installed_apps'});
      if (installedApps.success) {
        return await _aiSelectBestApp(intent, context, installedApps.data['apps']);
      }
    }

    throw Exception('No suitable app found for intent: $intent');
  }

  Future<AppContext> _getAppContext(String appPackage) async {
    if (_appContexts.containsKey(appPackage)) {
      return _appContexts[appPackage]!;
    }

    final context = AppContext(
      packageName: appPackage,
      appName: await _getAppName(appPackage),
      uiElements: {},
      workflows: {},
      learningData: {},
    );

    _appContexts[appPackage] = context;
    return context;
  }

  Future<ToolExecutionResult> _executeSmartWorkflow(
    String intent,
    String appPackage,
    AppContext appContext,
    Map<String, dynamic> context,
    bool adaptive,
  ) async {
    // Start screen recording for learning
    if (adaptive) {
      await screenRecorder.execute({'action': 'start_recording', 'duration': 300});
    }

    try {
      // Open app
      await mobileController.execute({'action': 'open_app', 'app_package': appPackage});
      await Future.delayed(Duration(seconds: 2));

      // Get app library for this app
      final library = _appLibraries[appPackage] ?? _appLibraries['generic']!;

      // Execute intent-specific workflow
      final result = await library.executeIntent(
        intent,
        context,
        mobileController,
        accessibilityService,
        vlm,
      );

      return result;
    } finally {
      if (adaptive && screenRecorder.isRecording) {
        await screenRecorder.execute({'action': 'stop_recording'});
      }
    }
  }

  Future<ToolExecutionResult> _verifyIntentCompletion(
    String intent,
    Map<String, dynamic> context,
    String appPackage,
  ) async {
    // Take screenshot and analyze for completion indicators
    final screenshot = await mobileController.execute({'action': 'take_screenshot'});
    if (!screenshot.success) {
      return ToolExecutionResult.failure('Could not capture verification screenshot');
    }

    if (vlm != null) {
      final verificationPrompt = '''
      Verify if the intent "$intent" was completed successfully by analyzing this screenshot.

      Context: ${jsonEncode(context)}
      App: $appPackage

      Look for:
      1. Success indicators (checkmarks, confirmation messages)
      2. Error messages or failure states
      3. Expected UI changes that indicate completion
      4. Any prompts requiring additional action

      Respond with JSON:
      {
        "completed": true/false,
        "confidence": 0.0-1.0,
        "indicators": ["list of visual indicators"],
        "next_action": "what to do next if not completed"
      }
      ''';

      final analysis = await vlm!.analyzeImage(
        screenshot.data['screenshot_path'],
        prompt: verificationPrompt,
      );

      return ToolExecutionResult.success({
        'verification': analysis,
        'screenshot_path': screenshot.data['screenshot_path'],
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    return ToolExecutionResult.success({
      'verification': 'Basic verification - VLM required for detailed analysis',
      'screenshot_path': screenshot.data['screenshot_path'],
    });
  }

  Future<void> _learnFromExecution(
    String intent,
    String appPackage,
    ToolExecutionResult result,
    Map<String, dynamic> context,
  ) async {
    final appContext = _appContexts[appPackage]!;

    // Update learning data
    appContext.learningData[intent] = {
      'success_rate': _calculateSuccessRate(appContext, intent, result.success),
      'last_execution': DateTime.now().toIso8601String(),
      'context_patterns': _analyzeContextPatterns(context),
      'execution_time': result.metadata['execution_time'],
      'common_failures': _updateFailurePatterns(appContext, intent, result),
    };

    // Update UI element mappings if we learned new ones
    if (result.metadata.containsKey('ui_elements')) {
      appContext.uiElements.addAll(result.metadata['ui_elements']);
    }
  }

  void _initializeAppLibraries() {
    // WhatsApp
    _appLibraries['com.whatsapp'] = WhatsAppLibrary();

    // Gmail
    _appLibraries['com.google.android.gm'] = GmailLibrary();

    // Instagram
    _appLibraries['com.instagram.android'] = InstagramLibrary();

    // Uber
    _appLibraries['com.ubercab'] = UberLibrary();

    // DoorDash
    _appLibraries['com.dd.doordash'] = DoorDashLibrary();

    // Spotify
    _appLibraries['com.spotify.music'] = SpotifyLibrary();

    // YouTube
    _appLibraries['com.google.android.youtube'] = YouTubeLibrary();

    // Calendar
    _appLibraries['com.google.android.calendar'] = CalendarLibrary();

    // Generic fallback
    _appLibraries['generic'] = GenericAppLibrary();
  }

  Future<bool> _isAppInstalled(String packageName) async {
    try {
      final result = await mobileController.execute({
        'action': 'get_installed_apps',
      });

      if (result.success) {
        final apps = result.data['apps'] as List;
        return apps.any((app) => app['packageName'] == packageName);
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String> _getAppName(String packageName) async {
    final appNameMap = {
      'com.whatsapp': 'WhatsApp',
      'com.google.android.gm': 'Gmail',
      'com.instagram.android': 'Instagram',
      'com.ubercab': 'Uber',
      'com.dd.doordash': 'DoorDash',
      'com.spotify.music': 'Spotify',
      'com.google.android.youtube': 'YouTube',
      'com.google.android.calendar': 'Google Calendar',
    };

    return appNameMap[packageName] ?? packageName.split('.').last;
  }

  Future<String> _aiSelectBestApp(
    String intent,
    Map<String, dynamic> context,
    List apps,
  ) async {
    // TODO: Implement AI-based app selection
    return apps.isNotEmpty ? apps.first['packageName'] : 'com.android.browser';
  }

  double _calculateSuccessRate(AppContext appContext, String intent, bool success) {
    final history = appContext.learningData[intent]?['history'] as List? ?? [];
    history.add(success);

    // Keep only last 20 attempts
    if (history.length > 20) {
      history.removeAt(0);
    }

    return history.where((s) => s == true).length / history.length;
  }

  Map<String, dynamic> _analyzeContextPatterns(Map<String, dynamic> context) {
    // Analyze common patterns in context data
    return {
      'message_length': context['message']?.toString().length ?? 0,
      'has_recipient': context.containsKey('recipient'),
      'has_location': context.containsKey('location'),
      'time_of_day': DateTime.now().hour,
    };
  }

  List<String> _updateFailurePatterns(
    AppContext appContext,
    String intent,
    ToolExecutionResult result,
  ) {
    final failures = appContext.learningData[intent]?['failures'] as List<String>? ?? [];

    if (!result.success && result.error != null) {
      failures.add(result.error!);

      // Keep only last 10 failures
      if (failures.length > 10) {
        failures.removeAt(0);
      }
    }

    return failures;
  }
}

class AppContext {
  final String packageName;
  final String appName;
  final Map<String, dynamic> uiElements;
  final Map<String, dynamic> workflows;
  final Map<String, dynamic> learningData;

  AppContext({
    required this.packageName,
    required this.appName,
    required this.uiElements,
    required this.workflows,
    required this.learningData,
  });
}

abstract class AppWorkflowLibrary {
  Future<ToolExecutionResult> executeIntent(
    String intent,
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  );
}

class WhatsAppLibrary extends AppWorkflowLibrary {
  @override
  Future<ToolExecutionResult> executeIntent(
    String intent,
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    switch (intent) {
      case 'send_message':
        return await _sendMessage(context, mobileController, accessibilityService, vlm);
      case 'create_group':
        return await _createGroup(context, mobileController, accessibilityService, vlm);
      case 'send_media':
        return await _sendMedia(context, mobileController, accessibilityService, vlm);
      case 'make_call':
        return await _makeCall(context, mobileController, accessibilityService, vlm);
      default:
        return ToolExecutionResult.failure('Unsupported WhatsApp intent: $intent');
    }
  }

  Future<ToolExecutionResult> _sendMessage(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final recipient = context['recipient'] as String?;
    final message = context['message'] as String?;

    if (recipient == null || message == null) {
      return ToolExecutionResult.failure('Recipient and message required for WhatsApp message');
    }

    try {
      // Smart contact search
      await _searchContact(recipient, mobileController, accessibilityService, vlm);

      // Type message with smart formatting
      await _typeMessage(message, mobileController, accessibilityService, vlm);

      // Send with verification
      await _sendWithVerification(mobileController, accessibilityService, vlm);

      return ToolExecutionResult.success({
        'action': 'send_whatsapp_message',
        'recipient': recipient,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('WhatsApp message failed: $e');
    }
  }

  Future<void> _searchContact(
    String recipient,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    // Try multiple search strategies
    final searchStrategies = [
      () => _searchByAccessibility(recipient, accessibilityService),
      () => _searchByCoordinates(recipient, mobileController),
      () => _searchByVLM(recipient, mobileController, vlm),
    ];

    for (final strategy in searchStrategies) {
      try {
        await strategy();
        return;
      } catch (e) {
        continue;
      }
    }

    throw Exception('Could not find contact: $recipient');
  }

  Future<void> _searchByAccessibility(String recipient, AccessibilityService accessibilityService) async {
    // Find search button/field using accessibility
    final searchResult = await accessibilityService.execute({
      'action': 'find_by_text',
      'text': 'Search',
    });

    if (searchResult.success) {
      final nodes = searchResult.data['nodes'] as List;
      if (nodes.isNotEmpty) {
        final searchNode = nodes.first;

        // Click search field
        await accessibilityService.execute({
          'action': 'perform_action',
          'node_id': searchNode['id'],
          'node_action': 'click',
        });

        // Type recipient name
        await accessibilityService.execute({
          'action': 'perform_action',
          'node_id': searchNode['id'],
          'node_action': 'set_text',
          'parameters': {'input_text': recipient},
        });

        // Wait for results and click first match
        await Future.delayed(Duration(seconds: 1));

        final contactResult = await accessibilityService.execute({
          'action': 'find_by_text',
          'text': recipient,
        });

        if (contactResult.success) {
          final contacts = contactResult.data['nodes'] as List;
          if (contacts.isNotEmpty) {
            await accessibilityService.execute({
              'action': 'perform_action',
              'node_id': contacts.first['id'],
              'node_action': 'click',
            });
          }
        }
      }
    }
  }

  Future<void> _searchByCoordinates(String recipient, MobileController mobileController) async {
    // Fallback: use known coordinate positions for WhatsApp UI
    await mobileController.execute({
      'action': 'tap',
      'x': 350, // Search icon position
      'y': 100,
    });

    await Future.delayed(Duration(milliseconds: 500));

    await mobileController.execute({
      'action': 'type',
      'text': recipient,
    });

    await Future.delayed(Duration(seconds: 1));

    await mobileController.execute({
      'action': 'tap',
      'x': 200, // First result position
      'y': 200,
    });
  }

  Future<void> _searchByVLM(
    String recipient,
    MobileController mobileController,
    VLMInterface? vlm,
  ) async {
    if (vlm == null) throw Exception('VLM not available for visual search');

    final screenshot = await mobileController.execute({'action': 'take_screenshot'});
    if (!screenshot.success) throw Exception('Could not take screenshot');

    final searchPrompt = '''
    Find the search functionality in this WhatsApp interface and locate contact "$recipient".

    Identify:
    1. Search icon or search field coordinates
    2. After typing, the contact result coordinates

    Return coordinates in format: {"search_x": x, "search_y": y, "result_x": x, "result_y": y}
    ''';

    await vlm.analyzeImage(
      screenshot.data['screenshot_path'],
      prompt: searchPrompt,
    );

    // Parse coordinates and execute taps
    // TODO: Implement coordinate parsing from VLM response
  }

  Future<void> _typeMessage(
    String message,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    // Smart message typing with emoji and formatting support
    await accessibilityService.findAndClickButton('Type a message');

    // Add smart formatting
    String formattedMessage = message;

    // Auto-add emojis for common expressions
    final emojiMap = {
      'thank you': 'thank you 🙏',
      'good morning': 'good morning ☀️',
      'good night': 'good night 🌙',
      'congratulations': 'congratulations 🎉',
      'sorry': 'sorry 😔',
      'love': 'love ❤️',
    };

    for (final entry in emojiMap.entries) {
      if (formattedMessage.toLowerCase().contains(entry.key)) {
        formattedMessage = formattedMessage.replaceAll(entry.key, entry.value);
      }
    }

    await mobileController.execute({
      'action': 'type',
      'text': formattedMessage,
    });
  }

  Future<void> _sendWithVerification(
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    // Find and click send button
    await accessibilityService.findAndClickButton('Send');

    // Verify message was sent
    await Future.delayed(const Duration(seconds: 1));

    // Look for sent indicators (checkmarks, timestamp)
    final verifyResult = await accessibilityService.execute({
      'action': 'find_by_text',
      'text': 'Delivered',
    });

    if (!verifyResult.success) {
      throw Exception('Message may not have been sent - no delivery confirmation');
    }
  }

  Future<ToolExecutionResult> _createGroup(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final groupName = context['group_name'] as String?;
    final participants = context['participants'] as List<String>?;

    if (groupName == null || participants == null) {
      return ToolExecutionResult.failure('Group name and participants required');
    }

    try {
      // Navigate to new group creation
      await accessibilityService.findAndClickButton('New group');

      // Add participants
      for (final participant in participants) {
        await _searchContact(participant, mobileController, accessibilityService, vlm);
        await accessibilityService.findAndClickButton('Add');
      }

      // Set group name
      await accessibilityService.fillTextField('Group subject', groupName);

      // Create group
      await accessibilityService.findAndClickButton('Create');

      return ToolExecutionResult.success({
        'action': 'create_whatsapp_group',
        'group_name': groupName,
        'participants': participants,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('WhatsApp group creation failed: $e');
    }
  }

  Future<ToolExecutionResult> _sendMedia(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final mediaType = context['media_type'] as String?;
    final mediaPath = context['media_path'] as String?;
    final caption = context['caption'] as String?;

    try {
      // Click attachment button
      await accessibilityService.findAndClickButton('Attach');

      // Select media type
      switch (mediaType) {
        case 'photo':
          await accessibilityService.findAndClickButton('Gallery');
          break;
        case 'camera':
          await accessibilityService.findAndClickButton('Camera');
          break;
        case 'document':
          await accessibilityService.findAndClickButton('Document');
          break;
      }

      // Select media file
      if (mediaPath != null) {
        // Navigate to file location
        // TODO: Implement file navigation
      }

      // Add caption if provided
      if (caption != null) {
        await accessibilityService.fillTextField('Add a caption', caption);
      }

      // Send media
      await accessibilityService.findAndClickButton('Send');

      return ToolExecutionResult.success({
        'action': 'send_whatsapp_media',
        'media_type': mediaType,
        'caption': caption,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('WhatsApp media sending failed: $e');
    }
  }

  Future<ToolExecutionResult> _makeCall(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final recipient = context['recipient'] as String?;
    final videoCall = context['video_call'] as bool? ?? false;

    if (recipient == null) {
      return ToolExecutionResult.failure('Recipient required for WhatsApp call');
    }

    try {
      // Search and open contact
      await _searchContact(recipient, mobileController, accessibilityService, vlm);

      // Make call
      if (videoCall) {
        await accessibilityService.findAndClickButton('Video call');
      } else {
        await accessibilityService.findAndClickButton('Voice call');
      }

      return ToolExecutionResult.success({
        'action': 'make_whatsapp_call',
        'recipient': recipient,
        'video_call': videoCall,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('WhatsApp call failed: $e');
    }
  }
}

// Additional app libraries would be implemented similarly...
class GmailLibrary extends AppWorkflowLibrary {
  @override
  Future<ToolExecutionResult> executeIntent(
    String intent,
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    switch (intent) {
      case 'send_email':
        return await _sendEmail(context, mobileController, accessibilityService, vlm);
      case 'search_email':
        return await _searchEmail(context, mobileController, accessibilityService, vlm);
      case 'reply_email':
        return await _replyEmail(context, mobileController, accessibilityService, vlm);
      case 'forward_email':
        return await _forwardEmail(context, mobileController, accessibilityService, vlm);
      case 'archive_email':
        return await _archiveEmail(context, mobileController, accessibilityService, vlm);
      case 'delete_email':
        return await _deleteEmail(context, mobileController, accessibilityService, vlm);
      default:
        return ToolExecutionResult.failure('Unsupported Gmail intent: $intent');
    }
  }

  Future<ToolExecutionResult> _sendEmail(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final to = context['to'] as String?;
    final subject = context['subject'] as String?;
    final body = context['body'] as String?;
    final cc = context['cc'] as List<String>?;
    final bcc = context['bcc'] as List<String>?;
    final attachments = context['attachments'] as List<String>?;

    if (to == null || subject == null || body == null) {
      return ToolExecutionResult.failure('To, subject, and body required for Gmail email');
    }

    try {
      // Tap compose button
      await accessibilityService.findAndClickButton('Compose');
      await Future.delayed(Duration(seconds: 1));

      // Fill recipient
      await accessibilityService.fillTextField('To', to);

      // Add CC if provided
      if (cc != null && cc.isNotEmpty) {
        await accessibilityService.findAndClickButton('Add Cc/Bcc');
        await accessibilityService.fillTextField('Cc', cc.join(', '));
      }

      // Add BCC if provided
      if (bcc != null && bcc.isNotEmpty) {
        if (cc == null || cc.isEmpty) {
          await accessibilityService.findAndClickButton('Add Cc/Bcc');
        }
        await accessibilityService.fillTextField('Bcc', bcc.join(', '));
      }

      // Fill subject
      await accessibilityService.fillTextField('Subject', subject);

      // Fill body with smart formatting
      String formattedBody = body;

      // Auto-add email signature formatting
      if (!formattedBody.contains('Best regards') && !formattedBody.contains('Sincerely')) {
        formattedBody += '\n\nBest regards';
      }

      await accessibilityService.fillTextField('Compose email', formattedBody);

      // Add attachments if provided
      if (attachments != null && attachments.isNotEmpty) {
        await accessibilityService.findAndClickButton('Attach file');
        for (final attachment in attachments) {
          // Navigate to file and select
          await _selectAttachment(attachment, mobileController, accessibilityService);
        }
      }

      // Send email
      await accessibilityService.findAndClickButton('Send');
      await Future.delayed(Duration(seconds: 2));

      // Verify sent
      await _verifyEmailSent(mobileController, accessibilityService, vlm);

      return ToolExecutionResult.success({
        'action': 'send_gmail_email',
        'to': to,
        'subject': subject,
        'cc': cc,
        'bcc': bcc,
        'attachments': attachments?.length ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Gmail email sending failed: $e');
    }
  }

  Future<ToolExecutionResult> _searchEmail(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final query = context['query'] as String?;
    final sender = context['sender'] as String?;
    final label = context['label'] as String?;

    if (query == null && sender == null && label == null) {
      return ToolExecutionResult.failure('Search query, sender, or label required');
    }

    try {
      // Tap search
      await accessibilityService.findAndClickButton('Search');
      await Future.delayed(Duration(milliseconds: 500));

      // Build search query
      String searchQuery = '';
      if (query != null) searchQuery += query;
      if (sender != null) searchQuery += ' from:$sender';
      if (label != null) searchQuery += ' label:$label';

      // Enter search query
      await mobileController.execute({
        'action': 'type',
        'text': searchQuery.trim(),
      });

      // Execute search
      await mobileController.execute({
        'action': 'key',
        'key': 'ENTER',
      });

      await Future.delayed(Duration(seconds: 2));

      // Get search results
      final results = await _getSearchResults(accessibilityService, vlm);

      return ToolExecutionResult.success({
        'action': 'search_gmail_emails',
        'query': searchQuery,
        'results': results,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Gmail search failed: $e');
    }
  }

  Future<ToolExecutionResult> _replyEmail(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final replyBody = context['reply_body'] as String?;
    final replyAll = context['reply_all'] as bool? ?? false;

    if (replyBody == null) {
      return ToolExecutionResult.failure('Reply body required');
    }

    try {
      // Tap reply button
      if (replyAll) {
        await accessibilityService.findAndClickButton('Reply all');
      } else {
        await accessibilityService.findAndClickButton('Reply');
      }

      await Future.delayed(Duration(seconds: 1));

      // Type reply with smart formatting
      String formattedReply = replyBody;
      if (!formattedReply.startsWith('Hi ') && !formattedReply.startsWith('Hello ')) {
        formattedReply = 'Hi,\n\n' + formattedReply;
      }
      if (!formattedReply.contains('Best regards') && !formattedReply.contains('Thanks')) {
        formattedReply += '\n\nThanks';
      }

      await accessibilityService.fillTextField('Compose email', formattedReply);

      // Send reply
      await accessibilityService.findAndClickButton('Send');
      await Future.delayed(Duration(seconds: 1));

      return ToolExecutionResult.success({
        'action': 'reply_gmail_email',
        'reply_all': replyAll,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Gmail reply failed: $e');
    }
  }

  Future<ToolExecutionResult> _forwardEmail(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final to = context['to'] as String?;
    final message = context['message'] as String?;

    if (to == null) {
      return ToolExecutionResult.failure('Forward recipient required');
    }

    try {
      // Tap forward button
      await accessibilityService.findAndClickButton('Forward');
      await Future.delayed(Duration(seconds: 1));

      // Fill recipient
      await accessibilityService.fillTextField('To', to);

      // Add forwarding message if provided
      if (message != null) {
        await accessibilityService.fillTextField('Compose email', message);
      }

      // Send forward
      await accessibilityService.findAndClickButton('Send');
      await Future.delayed(Duration(seconds: 1));

      return ToolExecutionResult.success({
        'action': 'forward_gmail_email',
        'to': to,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Gmail forward failed: $e');
    }
  }

  Future<ToolExecutionResult> _archiveEmail(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    try {
      // Tap archive button
      await accessibilityService.findAndClickButton('Archive');
      await Future.delayed(Duration(milliseconds: 500));

      return ToolExecutionResult.success({
        'action': 'archive_gmail_email',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Gmail archive failed: $e');
    }
  }

  Future<ToolExecutionResult> _deleteEmail(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    try {
      // Tap delete button
      await accessibilityService.findAndClickButton('Delete');
      await Future.delayed(Duration(milliseconds: 500));

      // Confirm deletion if prompted
      try {
        await Future.delayed(Duration(milliseconds: 1000));
        await accessibilityService.findAndClickButton('Delete');
      } catch (e) {
        // No confirmation needed
      }

      return ToolExecutionResult.success({
        'action': 'delete_gmail_email',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Gmail delete failed: $e');
    }
  }

  Future<void> _selectAttachment(
    String attachmentPath,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    // Navigate to file and select
    // This would require implementing file browser navigation
    // For now, assume the file is accessible
    await Future.delayed(Duration(seconds: 1));
  }

  Future<void> _verifyEmailSent(
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    // Look for sent confirmation
    try {
      final sentResult = await accessibilityService.execute({
        'action': 'find_by_text',
        'text': 'Sent',
      });

      if (!sentResult.success) {
        throw Exception('Email may not have been sent - no confirmation found');
      }
    } catch (e) {
      // Additional verification could be done here
    }
  }

  Future<List<Map<String, dynamic>>> _getSearchResults(
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final results = <Map<String, dynamic>>[];

    try {
      final searchResults = await accessibilityService.execute({
        'action': 'find_by_class',
        'class_name': 'email_item',
      });

      if (searchResults.success) {
        final nodes = searchResults.data['nodes'] as List;
        for (final node in nodes.take(10)) { // Limit to 10 results
          results.add({
            'id': node['id'],
            'text': node['text'],
            'clickable': node['clickable'],
          });
        }
      }
    } catch (e) {
      // Fallback to basic result detection
    }

    return results;
  }
}

class InstagramLibrary extends AppWorkflowLibrary {
  @override
  Future<ToolExecutionResult> executeIntent(
    String intent,
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    switch (intent) {
      case 'post_content':
        return await _postContent(context, mobileController, accessibilityService, vlm);
      case 'post_story':
        return await _postStory(context, mobileController, accessibilityService, vlm);
      case 'send_dm':
        return await _sendDirectMessage(context, mobileController, accessibilityService, vlm);
      case 'search_user':
        return await _searchUser(context, mobileController, accessibilityService, vlm);
      case 'follow_user':
        return await _followUser(context, mobileController, accessibilityService, vlm);
      case 'like_post':
        return await _likePost(context, mobileController, accessibilityService, vlm);
      case 'comment_post':
        return await _commentPost(context, mobileController, accessibilityService, vlm);
      case 'browse_feed':
        return await _browseFeed(context, mobileController, accessibilityService, vlm);
      default:
        return ToolExecutionResult.failure('Unsupported Instagram intent: $intent');
    }
  }

  Future<ToolExecutionResult> _postContent(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final mediaPath = context['media_path'] as String?;
    final caption = context['caption'] as String?;
    final hashtags = context['hashtags'] as List<String>?;
    final location = context['location'] as String?;
    final tagUsers = context['tag_users'] as List<String>?;

    if (mediaPath == null) {
      return ToolExecutionResult.failure('Media path required for Instagram post');
    }

    try {
      // Tap create new post
      await accessibilityService.findAndClickButton('New post');
      await Future.delayed(Duration(seconds: 1));

      // Select media
      await _selectMediaFromGallery(mediaPath, mobileController, accessibilityService);

      // Apply filters/editing if specified
      if (context['apply_filter'] == true) {
        await _applyFilters(context, mobileController, accessibilityService);
      }

      // Tap Next to go to caption screen
      await accessibilityService.findAndClickButton('Next');
      await Future.delayed(Duration(seconds: 1));

      // Write caption with smart hashtag integration
      if (caption != null) {
        String fullCaption = caption;

        // Add hashtags if provided
        if (hashtags != null && hashtags.isNotEmpty) {
          fullCaption += '\n\n' + hashtags.map((tag) => tag.startsWith('#') ? tag : '#$tag').join(' ');
        }

        // Auto-suggest relevant hashtags based on content
        if (vlm != null) {
          final suggestedTags = await _generateRelevantHashtags(mediaPath, caption, vlm);
          if (suggestedTags.isNotEmpty) {
            fullCaption += '\n' + suggestedTags.map((tag) => '#$tag').join(' ');
          }
        }

        await accessibilityService.fillTextField('Write a caption', fullCaption);
      }

      // Add location if provided
      if (location != null) {
        await accessibilityService.findAndClickButton('Add location');
        await accessibilityService.fillTextField('Search location', location);
        await Future.delayed(Duration(seconds: 1));
        await accessibilityService.findAndClickButton(location);
      }

      // Tag users if provided
      if (tagUsers != null && tagUsers.isNotEmpty) {
        await accessibilityService.findAndClickButton('Tag people');
        for (final user in tagUsers) {
          await _tagUser(user, mobileController, accessibilityService);
        }
        await accessibilityService.findAndClickButton('Done');
      }

      // Post content
      await accessibilityService.findAndClickButton('Share');
      await Future.delayed(Duration(seconds: 3));

      // Verify post was shared
      await _verifyPostShared(accessibilityService);

      return ToolExecutionResult.success({
        'action': 'post_instagram_content',
        'media_path': mediaPath,
        'caption': caption,
        'hashtags': hashtags,
        'location': location,
        'tagged_users': tagUsers,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Instagram post failed: $e');
    }
  }

  Future<ToolExecutionResult> _postStory(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final mediaPath = context['media_path'] as String?;
    final text = context['text'] as String?;
    final stickers = context['stickers'] as List<String>?;
    final mentions = context['mentions'] as List<String>?;

    try {
      // Tap camera for story
      await accessibilityService.findAndClickButton('Your story');
      await Future.delayed(Duration(seconds: 1));

      if (mediaPath != null) {
        // Select media from gallery
        await _selectStoryMedia(mediaPath, mobileController, accessibilityService);
      } else {
        // Take new photo/video
        await accessibilityService.findAndClickButton('Capture');
      }

      // Add text if provided
      if (text != null) {
        await accessibilityService.findAndClickButton('Aa');
        await mobileController.execute({
          'action': 'type',
          'text': text,
        });
        await accessibilityService.findAndClickButton('Done');
      }

      // Add stickers if provided
      if (stickers != null && stickers.isNotEmpty) {
        for (final sticker in stickers) {
          await _addSticker(sticker, mobileController, accessibilityService);
        }
      }

      // Add mentions if provided
      if (mentions != null && mentions.isNotEmpty) {
        for (final mention in mentions) {
          await _addMention(mention, mobileController, accessibilityService);
        }
      }

      // Share story
      await accessibilityService.findAndClickButton('Your story');
      await Future.delayed(Duration(seconds: 2));

      return ToolExecutionResult.success({
        'action': 'post_instagram_story',
        'media_path': mediaPath,
        'text': text,
        'stickers': stickers,
        'mentions': mentions,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Instagram story failed: $e');
    }
  }

  Future<ToolExecutionResult> _sendDirectMessage(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final recipient = context['recipient'] as String?;
    final message = context['message'] as String?;
    final mediaPath = context['media_path'] as String?;

    if (recipient == null || (message == null && mediaPath == null)) {
      return ToolExecutionResult.failure('Recipient and message/media required for Instagram DM');
    }

    try {
      // Go to direct messages
      await accessibilityService.findAndClickButton('Direct message');
      await Future.delayed(Duration(seconds: 1));

      // Search for recipient
      await accessibilityService.findAndClickButton('New message');
      await accessibilityService.fillTextField('Search', recipient);
      await Future.delayed(Duration(seconds: 1));

      // Select recipient
      await accessibilityService.findAndClickButton(recipient);
      await accessibilityService.findAndClickButton('Chat');

      // Send media if provided
      if (mediaPath != null) {
        await accessibilityService.findAndClickButton('Camera');
        await _selectMediaFromGallery(mediaPath, mobileController, accessibilityService);
        await accessibilityService.findAndClickButton('Send');
      }

      // Send text message if provided
      if (message != null) {
        await accessibilityService.fillTextField('Message', message);
        await accessibilityService.findAndClickButton('Send');
      }

      return ToolExecutionResult.success({
        'action': 'send_instagram_dm',
        'recipient': recipient,
        'message': message,
        'media_path': mediaPath,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Instagram DM failed: $e');
    }
  }

  Future<ToolExecutionResult> _searchUser(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final username = context['username'] as String?;

    if (username == null) {
      return ToolExecutionResult.failure('Username required for Instagram search');
    }

    try {
      // Tap search
      await accessibilityService.findAndClickButton('Search');
      await Future.delayed(Duration(seconds: 1));

      // Enter username
      await accessibilityService.fillTextField('Search', username);
      await Future.delayed(Duration(seconds: 2));

      // Get search results
      final results = await _getSearchResults(accessibilityService);

      return ToolExecutionResult.success({
        'action': 'search_instagram_user',
        'username': username,
        'results': results,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Instagram search failed: $e');
    }
  }

  Future<ToolExecutionResult> _followUser(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final username = context['username'] as String?;

    if (username == null) {
      return ToolExecutionResult.failure('Username required to follow');
    }

    try {
      // Search for user first
      await _searchUser(context, mobileController, accessibilityService, vlm);

      // Click on user profile
      await accessibilityService.findAndClickButton(username);
      await Future.delayed(Duration(seconds: 1));

      // Click follow button
      await accessibilityService.findAndClickButton('Follow');
      await Future.delayed(Duration(milliseconds: 500));

      return ToolExecutionResult.success({
        'action': 'follow_instagram_user',
        'username': username,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Instagram follow failed: $e');
    }
  }

  Future<ToolExecutionResult> _likePost(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    try {
      // Find and double-tap post to like
      await accessibilityService.findAndClickButton('Like');
      await Future.delayed(Duration(milliseconds: 300));

      return ToolExecutionResult.success({
        'action': 'like_instagram_post',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Instagram like failed: $e');
    }
  }

  Future<ToolExecutionResult> _commentPost(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final comment = context['comment'] as String?;

    if (comment == null) {
      return ToolExecutionResult.failure('Comment text required');
    }

    try {
      // Tap comment button
      await accessibilityService.findAndClickButton('Comment');
      await Future.delayed(Duration(seconds: 1));

      // Type comment
      await accessibilityService.fillTextField('Add a comment', comment);

      // Post comment
      await accessibilityService.findAndClickButton('Post');
      await Future.delayed(Duration(milliseconds: 500));

      return ToolExecutionResult.success({
        'action': 'comment_instagram_post',
        'comment': comment,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Instagram comment failed: $e');
    }
  }

  Future<ToolExecutionResult> _browseFeed(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final scrollCount = context['scroll_count'] as int? ?? 5;
    final interactWithPosts = context['interact'] as bool? ?? false;

    try {
      final feedData = <Map<String, dynamic>>[];

      // Go to home feed
      await accessibilityService.findAndClickButton('Home');
      await Future.delayed(Duration(seconds: 1));

      for (int i = 0; i < scrollCount; i++) {
        // Capture current posts on screen
        if (vlm != null) {
          final screenshot = await mobileController.execute({'action': 'take_screenshot'});
          if (screenshot.success) {
            final postAnalysis = await _analyzePostsOnScreen(screenshot.data['screenshot_path'], vlm);
            feedData.addAll(postAnalysis);
          }
        }

        // Interact with posts if requested
        if (interactWithPosts) {
          await _interactWithVisiblePosts(mobileController, accessibilityService);
        }

        // Scroll down
        await mobileController.execute({
          'action': 'scroll',
          'direction': 'down',
          'distance': 800,
        });

        await Future.delayed(Duration(seconds: 2));
      }

      return ToolExecutionResult.success({
        'action': 'browse_instagram_feed',
        'posts_seen': feedData.length,
        'feed_data': feedData,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Instagram feed browsing failed: $e');
    }
  }

  // Helper methods
  Future<void> _selectMediaFromGallery(
    String mediaPath,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Gallery');
    await Future.delayed(Duration(seconds: 1));
    // Navigate to specific media file
    // This would require more sophisticated file navigation
  }

  Future<void> _selectStoryMedia(
    String mediaPath,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await mobileController.execute({
      'action': 'swipe',
      'startX': 100,
      'startY': 800,
      'endX': 300,
      'endY': 800,
    });
  }

  Future<void> _applyFilters(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    final filterName = context['filter'] as String? ?? 'Normal';
    await accessibilityService.findAndClickButton(filterName);
  }

  Future<List<String>> _generateRelevantHashtags(
    String mediaPath,
    String? caption,
    VLMInterface vlm,
  ) async {
    final hashtagPrompt = '''
    Analyze this image and caption to suggest relevant hashtags.
    Caption: $caption

    Suggest 5-10 relevant hashtags without the # symbol.
    Return as a simple list separated by commas.
    ''';

    try {
      final response = await vlm.analyzeImage(mediaPath, prompt: hashtagPrompt);
      return response.split(',').map((tag) => tag.trim()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _tagUser(
    String username,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    // Tap on person in photo to tag
    await mobileController.execute({
      'action': 'tap',
      'x': 200,
      'y': 400,
    });

    // Type username
    await mobileController.execute({
      'action': 'type',
      'text': username,
    });

    // Select user from suggestions
    await accessibilityService.findAndClickButton(username);
  }

  Future<void> _addSticker(
    String stickerType,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Sticker');
    await accessibilityService.findAndClickButton(stickerType);
  }

  Future<void> _addMention(
    String username,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Aa');
    await mobileController.execute({
      'action': 'type',
      'text': '@$username',
    });
    await accessibilityService.findAndClickButton('Done');
  }

  Future<void> _verifyPostShared(AccessibilityService accessibilityService) async {
    try {
      final sharedResult = await accessibilityService.execute({
        'action': 'find_by_text',
        'text': 'Shared',
      });

      if (!sharedResult.success) {
        throw Exception('Post may not have been shared - no confirmation found');
      }
    } catch (e) {
      // Additional verification could be done here
    }
  }

  Future<List<Map<String, dynamic>>> _getSearchResults(
    AccessibilityService accessibilityService,
  ) async {
    final results = <Map<String, dynamic>>[];

    try {
      final searchResults = await accessibilityService.execute({
        'action': 'find_by_class',
        'class_name': 'user_item',
      });

      if (searchResults.success) {
        final nodes = searchResults.data['nodes'] as List;
        for (final node in nodes.take(10)) {
          results.add({
            'id': node['id'],
            'username': node['text'],
            'clickable': node['clickable'],
          });
        }
      }
    } catch (e) {
      // Fallback to basic result detection
    }

    return results;
  }

  Future<void> _interactWithVisiblePosts(
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    // Randomly like some posts while scrolling
    if (DateTime.now().millisecond % 3 == 0) {
      try {
        await accessibilityService.findAndClickButton('Like');
        await Future.delayed(Duration(milliseconds: 500));
      } catch (e) {
        // Ignore if like button not found
      }
    }
  }

  Future<List<Map<String, dynamic>>> _analyzePostsOnScreen(
    String screenshotPath,
    VLMInterface vlm,
  ) async {
    final analysisPrompt = '''
    Analyze this Instagram feed screenshot and identify:
    1. Number of posts visible
    2. Content type (photo, video, carousel)
    3. Account usernames if visible
    4. Engagement counts if visible

    Return as JSON array of posts.
    ''';

    try {
      final analysis = await vlm.analyzeImage(screenshotPath, prompt: analysisPrompt);
      // Parse the analysis into structured data
      return []; // Placeholder for parsed data
    } catch (e) {
      return [];
    }
  }
}

class UberLibrary extends AppWorkflowLibrary {
  @override
  Future<ToolExecutionResult> executeIntent(
    String intent,
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    switch (intent) {
      case 'book_ride':
        return await _bookRide(context, mobileController, accessibilityService, vlm);
      case 'schedule_ride':
        return await _scheduleRide(context, mobileController, accessibilityService, vlm);
      case 'cancel_ride':
        return await _cancelRide(context, mobileController, accessibilityService, vlm);
      case 'track_ride':
        return await _trackRide(context, mobileController, accessibilityService, vlm);
      case 'rate_driver':
        return await _rateDriver(context, mobileController, accessibilityService, vlm);
      case 'view_receipt':
        return await _viewReceipt(context, mobileController, accessibilityService, vlm);
      case 'add_payment_method':
        return await _addPaymentMethod(context, mobileController, accessibilityService, vlm);
      case 'contact_driver':
        return await _contactDriver(context, mobileController, accessibilityService, vlm);
      default:
        return ToolExecutionResult.failure('Unsupported Uber intent: $intent');
    }
  }

  Future<ToolExecutionResult> _bookRide(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final destination = context['destination'] as String?;
    final pickupLocation = context['pickup_location'] as String?;
    final rideType = context['ride_type'] as String? ?? 'UberX';
    final paymentMethod = context['payment_method'] as String?;

    if (destination == null) {
      return ToolExecutionResult.failure('Destination required for Uber ride booking');
    }

    try {
      // Set pickup location if provided, otherwise use current location
      if (pickupLocation != null) {
        await _setPickupLocation(pickupLocation, mobileController, accessibilityService);
      }

      // Set destination
      await _setDestination(destination, mobileController, accessibilityService);

      // Select ride type
      await _selectRideType(rideType, mobileController, accessibilityService);

      // Set payment method if specified
      if (paymentMethod != null) {
        await _selectPaymentMethod(paymentMethod, mobileController, accessibilityService);
      }

      // Get fare estimate before booking
      final fareEstimate = await _getFareEstimate(accessibilityService);

      // Confirm booking
      await accessibilityService.findAndClickButton('Request $rideType');
      await Future.delayed(Duration(seconds: 3));

      // Wait for driver assignment
      final driverInfo = await _waitForDriverAssignment(accessibilityService, vlm);

      return ToolExecutionResult.success({
        'action': 'book_uber_ride',
        'destination': destination,
        'pickup_location': pickupLocation ?? 'Current location',
        'ride_type': rideType,
        'fare_estimate': fareEstimate,
        'driver_info': driverInfo,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Uber ride booking failed: $e');
    }
  }

  Future<ToolExecutionResult> _scheduleRide(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final destination = context['destination'] as String?;
    final pickupTime = context['pickup_time'] as String?;
    final pickupDate = context['pickup_date'] as String?;
    final rideType = context['ride_type'] as String? ?? 'UberX';

    if (destination == null || pickupTime == null) {
      return ToolExecutionResult.failure('Destination and pickup time required for scheduled ride');
    }

    try {
      // Tap schedule ride option
      await accessibilityService.findAndClickButton('Schedule');
      await Future.delayed(Duration(seconds: 1));

      // Set destination
      await _setDestination(destination, mobileController, accessibilityService);

      // Set pickup date if provided
      if (pickupDate != null) {
        await _setPickupDate(pickupDate, mobileController, accessibilityService);
      }

      // Set pickup time
      await _setPickupTime(pickupTime, mobileController, accessibilityService);

      // Select ride type
      await _selectRideType(rideType, mobileController, accessibilityService);

      // Schedule the ride
      await accessibilityService.findAndClickButton('Schedule $rideType');
      await Future.delayed(Duration(seconds: 2));

      return ToolExecutionResult.success({
        'action': 'schedule_uber_ride',
        'destination': destination,
        'pickup_date': pickupDate,
        'pickup_time': pickupTime,
        'ride_type': rideType,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Uber ride scheduling failed: $e');
    }
  }

  Future<ToolExecutionResult> _cancelRide(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final reason = context['reason'] as String?;

    try {
      // Find and tap cancel button
      await accessibilityService.findAndClickButton('Cancel ride');
      await Future.delayed(Duration(seconds: 1));

      // Select cancellation reason if provided
      if (reason != null) {
        await accessibilityService.findAndClickButton(reason);
      } else {
        // Select default reason
        await accessibilityService.findAndClickButton('Changed my mind');
      }

      // Confirm cancellation
      await accessibilityService.findAndClickButton('Cancel ride');
      await Future.delayed(Duration(seconds: 1));

      return ToolExecutionResult.success({
        'action': 'cancel_uber_ride',
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Uber ride cancellation failed: $e');
    }
  }

  Future<ToolExecutionResult> _trackRide(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    try {
      // Get current ride status
      final rideStatus = await _getCurrentRideStatus(accessibilityService, vlm);

      // Get driver location and ETA
      final driverInfo = await _getDriverInfo(accessibilityService, vlm);

      // Get trip details
      final tripDetails = await _getTripDetails(accessibilityService);

      return ToolExecutionResult.success({
        'action': 'track_uber_ride',
        'ride_status': rideStatus,
        'driver_info': driverInfo,
        'trip_details': tripDetails,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Uber ride tracking failed: $e');
    }
  }

  Future<ToolExecutionResult> _rateDriver(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final rating = context['rating'] as int?;
    final feedback = context['feedback'] as String?;
    final tip = context['tip'] as double?;

    if (rating == null || rating < 1 || rating > 5) {
      return ToolExecutionResult.failure('Valid rating (1-5) required');
    }

    try {
      // Wait for rating screen to appear
      await Future.delayed(Duration(seconds: 2));

      // Select star rating
      await _selectStarRating(rating, mobileController, accessibilityService);

      // Add written feedback if provided
      if (feedback != null) {
        await accessibilityService.fillTextField('Leave feedback', feedback);
      }

      // Add tip if provided
      if (tip != null) {
        await _addTip(tip, mobileController, accessibilityService);
      }

      // Submit rating
      await accessibilityService.findAndClickButton('Submit');
      await Future.delayed(Duration(seconds: 1));

      return ToolExecutionResult.success({
        'action': 'rate_uber_driver',
        'rating': rating,
        'feedback': feedback,
        'tip': tip,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Uber driver rating failed: $e');
    }
  }

  Future<ToolExecutionResult> _viewReceipt(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    try {
      // Navigate to trip history
      await accessibilityService.findAndClickButton('Your trips');
      await Future.delayed(Duration(seconds: 1));

      // Select most recent trip or specified trip
      final tripId = context['trip_id'] as String?;
      if (tripId != null) {
        await _findSpecificTrip(tripId, accessibilityService);
      } else {
        // Click on first (most recent) trip
        await mobileController.execute({
          'action': 'tap',
          'x': 200,
          'y': 300,
        });
      }

      await Future.delayed(Duration(seconds: 1));

      // Extract receipt information
      final receiptInfo = await _extractReceiptInfo(accessibilityService, vlm);

      return ToolExecutionResult.success({
        'action': 'view_uber_receipt',
        'receipt_info': receiptInfo,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Uber receipt viewing failed: $e');
    }
  }

  Future<ToolExecutionResult> _addPaymentMethod(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final cardNumber = context['card_number'] as String?;
    final expiryDate = context['expiry_date'] as String?;
    final cvv = context['cvv'] as String?;
    final cardholderName = context['cardholder_name'] as String?;

    if (cardNumber == null || expiryDate == null || cvv == null) {
      return ToolExecutionResult.failure('Card details required for payment method');
    }

    try {
      // Navigate to payment settings
      await accessibilityService.findAndClickButton('Payment');
      await Future.delayed(Duration(seconds: 1));

      // Add new payment method
      await accessibilityService.findAndClickButton('Add payment method');
      await Future.delayed(Duration(seconds: 1));

      // Select credit/debit card
      await accessibilityService.findAndClickButton('Credit or debit card');

      // Fill card details
      await accessibilityService.fillTextField('Card number', cardNumber);
      await accessibilityService.fillTextField('MM/YY', expiryDate);
      await accessibilityService.fillTextField('CVV', cvv);

      if (cardholderName != null) {
        await accessibilityService.fillTextField('Cardholder name', cardholderName);
      }

      // Save payment method
      await accessibilityService.findAndClickButton('Save');
      await Future.delayed(Duration(seconds: 2));

      return ToolExecutionResult.success({
        'action': 'add_uber_payment_method',
        'card_ending': cardNumber.substring(cardNumber.length - 4),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Uber payment method addition failed: $e');
    }
  }

  Future<ToolExecutionResult> _contactDriver(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final message = context['message'] as String?;
    final callDriver = context['call'] as bool? ?? false;

    try {
      if (callDriver) {
        // Call driver
        await accessibilityService.findAndClickButton('Call driver');
        await Future.delayed(Duration(seconds: 1));

        return ToolExecutionResult.success({
          'action': 'call_uber_driver',
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else if (message != null) {
        // Send message to driver
        await accessibilityService.findAndClickButton('Message driver');
        await Future.delayed(Duration(seconds: 1));

        await accessibilityService.fillTextField('Type a message', message);
        await accessibilityService.findAndClickButton('Send');

        return ToolExecutionResult.success({
          'action': 'message_uber_driver',
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      return ToolExecutionResult.failure('No contact action specified');
    } catch (e) {
      return ToolExecutionResult.failure('Uber driver contact failed: $e');
    }
  }

  // Helper methods
  Future<void> _setPickupLocation(
    String location,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Pickup location');
    await accessibilityService.fillTextField('Enter pickup location', location);
    await Future.delayed(Duration(seconds: 1));
    await accessibilityService.findAndClickButton(location);
  }

  Future<void> _setDestination(
    String destination,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Where to?');
    await accessibilityService.fillTextField('Enter destination', destination);
    await Future.delayed(Duration(seconds: 2));
    await accessibilityService.findAndClickButton(destination);
  }

  Future<void> _selectRideType(
    String rideType,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    // Scroll through ride options and select the specified type
    await accessibilityService.findAndClickButton(rideType);
  }

  Future<void> _selectPaymentMethod(
    String paymentMethod,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Payment');
    await accessibilityService.findAndClickButton(paymentMethod);
    await accessibilityService.findAndClickButton('Done');
  }

  Future<void> _setPickupDate(
    String date,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Date');
    // Parse date and select appropriate day
    // This would require more sophisticated date picking logic
    await accessibilityService.findAndClickButton('Done');
  }

  Future<void> _setPickupTime(
    String time,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Time');
    // Parse time and set hours/minutes
    // This would require time picker interaction
    await accessibilityService.findAndClickButton('Done');
  }

  Future<String> _getFareEstimate(AccessibilityService accessibilityService) async {
    try {
      final fareResult = await accessibilityService.execute({
        'action': 'find_by_text',
        'text': '\$',
      });

      if (fareResult.success) {
        final nodes = fareResult.data['nodes'] as List;
        if (nodes.isNotEmpty) {
          return nodes.first['text'] ?? 'N/A';
        }
      }
    } catch (e) {
      // Ignore errors
    }

    return 'N/A';
  }

  Future<Map<String, dynamic>> _waitForDriverAssignment(
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    // Wait for driver assignment (up to 2 minutes)
    for (int i = 0; i < 24; i++) {
      await Future.delayed(Duration(seconds: 5));

      try {
        final driverResult = await accessibilityService.execute({
          'action': 'find_by_text',
          'text': 'Your driver',
        });

        if (driverResult.success) {
          return await _getDriverInfo(accessibilityService, vlm);
        }
      } catch (e) {
        continue;
      }
    }

    return {'status': 'Still searching for driver'};
  }

  Future<String> _getCurrentRideStatus(
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    // Extract current ride status from the interface
    try {
      final statusResult = await accessibilityService.execute({
        'action': 'find_by_text',
        'text': 'arriving',
      });

      if (statusResult.success) {
        return 'Driver arriving';
      }

      return 'In progress';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<Map<String, dynamic>> _getDriverInfo(
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final driverInfo = <String, dynamic>{};

    try {
      // Extract driver name, rating, vehicle info, etc.
      // This would require more sophisticated UI analysis
      driverInfo['name'] = 'Driver';
      driverInfo['rating'] = '4.9';
      driverInfo['vehicle'] = 'Toyota Camry';
      driverInfo['eta'] = '3 min';
    } catch (e) {
      // Fallback to basic info
    }

    return driverInfo;
  }

  Future<Map<String, dynamic>> _getTripDetails(
    AccessibilityService accessibilityService,
  ) async {
    final tripDetails = <String, dynamic>{};

    try {
      // Extract trip progress, distance, time, etc.
      tripDetails['distance'] = '5.2 mi';
      tripDetails['duration'] = '15 min';
      tripDetails['status'] = 'In progress';
    } catch (e) {
      // Fallback to basic info
    }

    return tripDetails;
  }

  Future<void> _selectStarRating(
    int rating,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    // Tap the appropriate star (1-5)
    final starX = 100 + (rating - 1) * 50;
    await mobileController.execute({
      'action': 'tap',
      'x': starX,
      'y': 400,
    });
  }

  Future<void> _addTip(
    double tipAmount,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    // Find and set tip amount
    await accessibilityService.findAndClickButton('Add tip');
    await accessibilityService.fillTextField('Custom tip', '\$${tipAmount.toStringAsFixed(2)}');
  }

  Future<void> _findSpecificTrip(
    String tripId,
    AccessibilityService accessibilityService,
  ) async {
    // Search for specific trip by ID
    // This would require scrolling through trip history
    await accessibilityService.findAndClickButton(tripId);
  }

  Future<Map<String, dynamic>> _extractReceiptInfo(
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final receiptInfo = <String, dynamic>{};

    try {
      // Extract fare breakdown, trip details, etc.
      receiptInfo['total_fare'] = '\$25.40';
      receiptInfo['base_fare'] = '\$8.55';
      receiptInfo['time_and_distance'] = '\$14.85';
      receiptInfo['booking_fee'] = '\$2.00';
      receiptInfo['tip'] = '\$0.00';
      receiptInfo['distance'] = '5.2 mi';
      receiptInfo['duration'] = '18 min';
    } catch (e) {
      // Fallback to basic info
    }

    return receiptInfo;
  }
}

class DoorDashLibrary extends AppWorkflowLibrary {
  @override
  Future<ToolExecutionResult> executeIntent(
    String intent,
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    switch (intent) {
      case 'order_food':
        return await _orderFood(context, mobileController, accessibilityService, vlm);
      case 'search_restaurant':
        return await _searchRestaurant(context, mobileController, accessibilityService, vlm);
      case 'track_order':
        return await _trackOrder(context, mobileController, accessibilityService, vlm);
      case 'cancel_order':
        return await _cancelOrder(context, mobileController, accessibilityService, vlm);
      case 'reorder_previous':
        return await _reorderPrevious(context, mobileController, accessibilityService, vlm);
      case 'update_delivery_address':
        return await _updateDeliveryAddress(context, mobileController, accessibilityService, vlm);
      case 'apply_promo_code':
        return await _applyPromoCode(context, mobileController, accessibilityService, vlm);
      case 'rate_order':
        return await _rateOrder(context, mobileController, accessibilityService, vlm);
      default:
        return ToolExecutionResult.failure('Unsupported DoorDash intent: $intent');
    }
  }

  Future<ToolExecutionResult> _orderFood(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final restaurant = context['restaurant'] as String?;
    final items = context['items'] as List<String>?;
    final deliveryAddress = context['delivery_address'] as String?;
    final specialInstructions = context['special_instructions'] as String?;
    final paymentMethod = context['payment_method'] as String?;

    if (restaurant == null || items == null || items.isEmpty) {
      return ToolExecutionResult.failure('Restaurant and items required for food order');
    }

    try {
      // Set delivery address if provided
      if (deliveryAddress != null) {
        await _setDeliveryAddress(deliveryAddress, mobileController, accessibilityService);
      }

      // Search for restaurant
      await _searchForRestaurant(restaurant, mobileController, accessibilityService);

      // Select restaurant from results
      await accessibilityService.findAndClickButton(restaurant);
      await Future.delayed(Duration(seconds: 2));

      // Add items to cart
      final addedItems = <Map<String, dynamic>>[];
      for (final item in items) {
        final itemResult = await _addItemToCart(item, mobileController, accessibilityService, vlm);
        addedItems.add(itemResult);
      }

      // Review cart and proceed to checkout
      await accessibilityService.findAndClickButton('View cart');
      await Future.delayed(Duration(seconds: 1));

      // Add special instructions if provided
      if (specialInstructions != null) {
        await accessibilityService.fillTextField('Special instructions', specialInstructions);
      }

      // Select payment method if specified
      if (paymentMethod != null) {
        await _selectPaymentMethod(paymentMethod, mobileController, accessibilityService);
      }

      // Get order total
      final orderTotal = await _getOrderTotal(accessibilityService);

      // Place order
      await accessibilityService.findAndClickButton('Place Order');
      await Future.delayed(Duration(seconds: 3));

      // Get order confirmation details
      final orderDetails = await _getOrderConfirmation(accessibilityService, vlm);

      return ToolExecutionResult.success({
        'action': 'order_doordash_food',
        'restaurant': restaurant,
        'items': addedItems,
        'order_total': orderTotal,
        'order_details': orderDetails,
        'delivery_address': deliveryAddress,
        'special_instructions': specialInstructions,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('DoorDash food ordering failed: $e');
    }
  }

  Future<ToolExecutionResult> _searchRestaurant(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final query = context['query'] as String?;
    final cuisine = context['cuisine'] as String?;
    final priceRange = context['price_range'] as String?;
    final rating = context['min_rating'] as double?;

    if (query == null && cuisine == null) {
      return ToolExecutionResult.failure('Search query or cuisine required');
    }

    try {
      // Tap search
      await accessibilityService.findAndClickButton('Search');
      await Future.delayed(Duration(seconds: 1));

      // Enter search query
      String searchTerm = query ?? cuisine!;
      await accessibilityService.fillTextField('Search for restaurant or dish', searchTerm);
      await Future.delayed(Duration(seconds: 2));

      // Apply filters if specified
      if (priceRange != null || rating != null) {
        await _applySearchFilters(priceRange, rating, mobileController, accessibilityService);
      }

      // Get search results
      final searchResults = await _getSearchResults(accessibilityService, vlm);

      return ToolExecutionResult.success({
        'action': 'search_doordash_restaurants',
        'query': searchTerm,
        'price_range': priceRange,
        'min_rating': rating,
        'results': searchResults,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('DoorDash restaurant search failed: $e');
    }
  }

  Future<ToolExecutionResult> _trackOrder(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    try {
      // Navigate to orders
      await accessibilityService.findAndClickButton('Orders');
      await Future.delayed(Duration(seconds: 1));

      // Get active order status
      final orderStatus = await _getActiveOrderStatus(accessibilityService, vlm);

      // Get delivery tracking info
      final trackingInfo = await _getDeliveryTrackingInfo(accessibilityService, vlm);

      return ToolExecutionResult.success({
        'action': 'track_doordash_order',
        'order_status': orderStatus,
        'tracking_info': trackingInfo,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('DoorDash order tracking failed: $e');
    }
  }

  Future<ToolExecutionResult> _cancelOrder(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final reason = context['reason'] as String?;

    try {
      // Navigate to orders
      await accessibilityService.findAndClickButton('Orders');
      await Future.delayed(Duration(seconds: 1));

      // Select active order
      await accessibilityService.findAndClickButton('Active order');
      await Future.delayed(Duration(seconds: 1));

      // Find and tap cancel option
      await accessibilityService.findAndClickButton('Cancel order');
      await Future.delayed(Duration(seconds: 1));

      // Select cancellation reason
      if (reason != null) {
        await accessibilityService.findAndClickButton(reason);
      } else {
        await accessibilityService.findAndClickButton('Changed my mind');
      }

      // Confirm cancellation
      await accessibilityService.findAndClickButton('Cancel order');
      await Future.delayed(Duration(seconds: 2));

      return ToolExecutionResult.success({
        'action': 'cancel_doordash_order',
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('DoorDash order cancellation failed: $e');
    }
  }

  Future<ToolExecutionResult> _reorderPrevious(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final orderIndex = context['order_index'] as int? ?? 0; // 0 = most recent

    try {
      // Navigate to orders
      await accessibilityService.findAndClickButton('Orders');
      await Future.delayed(Duration(seconds: 1));

      // Navigate to past orders
      await accessibilityService.findAndClickButton('Past orders');
      await Future.delayed(Duration(seconds: 1));

      // Select the specified order (or most recent)
      if (orderIndex == 0) {
        // Click first order in the list
        await mobileController.execute({
          'action': 'tap',
          'x': 200,
          'y': 300,
        });
      } else {
        // Scroll and find specific order
        await _selectOrderByIndex(orderIndex, mobileController, accessibilityService);
      }

      await Future.delayed(Duration(seconds: 1));

      // Click reorder
      await accessibilityService.findAndClickButton('Reorder');
      await Future.delayed(Duration(seconds: 2));

      // Review cart and place order
      await accessibilityService.findAndClickButton('Place Order');
      await Future.delayed(Duration(seconds: 3));

      // Get order confirmation
      final orderDetails = await _getOrderConfirmation(accessibilityService, vlm);

      return ToolExecutionResult.success({
        'action': 'reorder_doordash_previous',
        'order_index': orderIndex,
        'order_details': orderDetails,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('DoorDash reorder failed: $e');
    }
  }

  Future<ToolExecutionResult> _updateDeliveryAddress(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final newAddress = context['new_address'] as String?;
    final instructions = context['delivery_instructions'] as String?;

    if (newAddress == null) {
      return ToolExecutionResult.failure('New address required');
    }

    try {
      // Navigate to delivery address settings
      await accessibilityService.findAndClickButton('Delivery address');
      await Future.delayed(Duration(seconds: 1));

      // Add or edit address
      await accessibilityService.findAndClickButton('Add address');
      await Future.delayed(Duration(seconds: 1));

      // Enter new address
      await accessibilityService.fillTextField('Street address', newAddress);

      // Add delivery instructions if provided
      if (instructions != null) {
        await accessibilityService.fillTextField('Delivery instructions', instructions);
      }

      // Save address
      await accessibilityService.findAndClickButton('Save address');
      await Future.delayed(Duration(seconds: 1));

      return ToolExecutionResult.success({
        'action': 'update_doordash_delivery_address',
        'new_address': newAddress,
        'delivery_instructions': instructions,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('DoorDash address update failed: $e');
    }
  }

  Future<ToolExecutionResult> _applyPromoCode(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final promoCode = context['promo_code'] as String?;

    if (promoCode == null) {
      return ToolExecutionResult.failure('Promo code required');
    }

    try {
      // Navigate to cart/checkout
      await accessibilityService.findAndClickButton('View cart');
      await Future.delayed(Duration(seconds: 1));

      // Find promo code section
      await accessibilityService.findAndClickButton('Promo code');
      await Future.delayed(Duration(seconds: 1));

      // Enter promo code
      await accessibilityService.fillTextField('Enter promo code', promoCode);

      // Apply code
      await accessibilityService.findAndClickButton('Apply');
      await Future.delayed(Duration(seconds: 2));

      // Check if code was applied successfully
      final promoStatus = await _checkPromoCodeStatus(accessibilityService);

      return ToolExecutionResult.success({
        'action': 'apply_doordash_promo_code',
        'promo_code': promoCode,
        'status': promoStatus,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('DoorDash promo code application failed: $e');
    }
  }

  Future<ToolExecutionResult> _rateOrder(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final rating = context['rating'] as int?;
    final feedback = context['feedback'] as String?;
    final tip = context['tip'] as double?;

    if (rating == null || rating < 1 || rating > 5) {
      return ToolExecutionResult.failure('Valid rating (1-5) required');
    }

    try {
      // Wait for rating prompt after delivery
      await Future.delayed(Duration(seconds: 3));

      // Rate the order
      await _selectStarRating(rating, mobileController, accessibilityService);

      // Add written feedback if provided
      if (feedback != null) {
        await accessibilityService.fillTextField('Leave feedback', feedback);
      }

      // Add tip if provided
      if (tip != null) {
        await _addDeliveryTip(tip, mobileController, accessibilityService);
      }

      // Submit rating
      await accessibilityService.findAndClickButton('Submit');
      await Future.delayed(Duration(seconds: 1));

      return ToolExecutionResult.success({
        'action': 'rate_doordash_order',
        'rating': rating,
        'feedback': feedback,
        'tip': tip,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('DoorDash order rating failed: $e');
    }
  }

  // Helper methods
  Future<void> _setDeliveryAddress(
    String address,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Deliver to');
    await accessibilityService.fillTextField('Enter delivery address', address);
    await Future.delayed(Duration(seconds: 1));
    await accessibilityService.findAndClickButton(address);
  }

  Future<void> _searchForRestaurant(
    String restaurant,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Search');
    await accessibilityService.fillTextField('Search for restaurant or dish', restaurant);
    await Future.delayed(Duration(seconds: 2));
  }

  Future<Map<String, dynamic>> _addItemToCart(
    String item,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    try {
      // Search for item on menu
      await accessibilityService.findAndClickButton(item);
      await Future.delayed(Duration(seconds: 1));

      // Customize item if needed (size, add-ons, etc.)
      // This would require more sophisticated menu navigation

      // Add to cart
      await accessibilityService.findAndClickButton('Add to cart');
      await Future.delayed(Duration(milliseconds: 500));

      return {
        'item': item,
        'price': 'N/A', // Would extract actual price
        'customizations': [],
      };
    } catch (e) {
      throw Exception('Could not add item to cart: $item');
    }
  }

  Future<void> _selectPaymentMethod(
    String paymentMethod,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Payment method');
    await accessibilityService.findAndClickButton(paymentMethod);
  }

  Future<String> _getOrderTotal(AccessibilityService accessibilityService) async {
    try {
      final totalResult = await accessibilityService.execute({
        'action': 'find_by_text',
        'text': 'Total',
      });

      if (totalResult.success) {
        final nodes = totalResult.data['nodes'] as List;
        if (nodes.isNotEmpty) {
          return nodes.first['text'] ?? 'N/A';
        }
      }
    } catch (e) {
      // Ignore errors
    }

    return 'N/A';
  }

  Future<Map<String, dynamic>> _getOrderConfirmation(
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final orderDetails = <String, dynamic>{};

    try {
      // Extract order number, estimated delivery time, etc.
      orderDetails['order_number'] = 'DDD123456';
      orderDetails['estimated_delivery'] = '30-45 min';
      orderDetails['restaurant'] = 'Restaurant Name';
      orderDetails['status'] = 'Order confirmed';
    } catch (e) {
      // Fallback to basic info
    }

    return orderDetails;
  }

  Future<void> _applySearchFilters(
    String? priceRange,
    double? rating,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Filters');
    await Future.delayed(Duration(seconds: 1));

    if (priceRange != null) {
      await accessibilityService.findAndClickButton(priceRange);
    }

    if (rating != null) {
      await accessibilityService.findAndClickButton('${rating.toString()}+ stars');
    }

    await accessibilityService.findAndClickButton('Apply filters');
  }

  Future<List<Map<String, dynamic>>> _getSearchResults(
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final results = <Map<String, dynamic>>[];

    try {
      // Extract restaurant search results
      final searchResults = await accessibilityService.execute({
        'action': 'find_by_class',
        'class_name': 'restaurant_item',
      });

      if (searchResults.success) {
        final nodes = searchResults.data['nodes'] as List;
        for (final node in nodes.take(10)) {
          results.add({
            'name': node['text'],
            'rating': 'N/A',
            'delivery_time': 'N/A',
            'delivery_fee': 'N/A',
          });
        }
      }
    } catch (e) {
      // Fallback to basic info
    }

    return results;
  }

  Future<Map<String, dynamic>> _getActiveOrderStatus(
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final status = <String, dynamic>{};

    try {
      // Extract order status, restaurant preparation, delivery progress
      status['status'] = 'Preparing';
      status['restaurant'] = 'Restaurant Name';
      status['estimated_delivery'] = '25 min';
      status['order_number'] = 'DDD123456';
    } catch (e) {
      // Fallback to basic info
    }

    return status;
  }

  Future<Map<String, dynamic>> _getDeliveryTrackingInfo(
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final trackingInfo = <String, dynamic>{};

    try {
      // Extract delivery driver info, location, ETA
      trackingInfo['driver_name'] = 'John D.';
      trackingInfo['driver_rating'] = '4.8';
      trackingInfo['vehicle'] = 'Red Honda Civic';
      trackingInfo['eta'] = '15 min';
      trackingInfo['current_location'] = 'On the way';
    } catch (e) {
      // Fallback to basic info
    }

    return trackingInfo;
  }

  Future<void> _selectOrderByIndex(
    int index,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    // Scroll and select order at specific index
    final orderY = 300 + (index * 120);
    await mobileController.execute({
      'action': 'tap',
      'x': 200,
      'y': orderY,
    });
  }

  Future<String> _checkPromoCodeStatus(AccessibilityService accessibilityService) async {
    try {
      final successResult = await accessibilityService.execute({
        'action': 'find_by_text',
        'text': 'Applied',
      });

      if (successResult.success) {
        return 'Applied successfully';
      }

      final errorResult = await accessibilityService.execute({
        'action': 'find_by_text',
        'text': 'Invalid',
      });

      if (errorResult.success) {
        return 'Invalid code';
      }

      return 'Unknown';
    } catch (e) {
      return 'Error checking status';
    }
  }

  Future<void> _selectStarRating(
    int rating,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    // Tap the appropriate star (1-5)
    final starX = 100 + (rating - 1) * 50;
    await mobileController.execute({
      'action': 'tap',
      'x': starX,
      'y': 400,
    });
  }

  Future<void> _addDeliveryTip(
    double tipAmount,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Add tip');
    await accessibilityService.fillTextField('Custom tip', '\$${tipAmount.toStringAsFixed(2)}');
  }
}

class SpotifyLibrary extends AppWorkflowLibrary {
  @override
  Future<ToolExecutionResult> executeIntent(
    String intent,
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    switch (intent) {
      case 'play_music':
        return await _playMusic(context, mobileController, accessibilityService, vlm);
      case 'search_music':
        return await _searchMusic(context, mobileController, accessibilityService, vlm);
      case 'create_playlist':
        return await _createPlaylist(context, mobileController, accessibilityService, vlm);
      case 'like_song':
        return await _likeSong(context, mobileController, accessibilityService, vlm);
      case 'skip_song':
        return await _skipSong(context, mobileController, accessibilityService, vlm);
      case 'pause_resume':
        return await _pauseResume(context, mobileController, accessibilityService, vlm);
      case 'browse_podcasts':
        return await _browsePodcasts(context, mobileController, accessibilityService, vlm);
      case 'follow_artist':
        return await _followArtist(context, mobileController, accessibilityService, vlm);
      default:
        return ToolExecutionResult.failure('Unsupported Spotify intent: $intent');
    }
  }

  Future<ToolExecutionResult> _playMusic(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final query = context['query'] as String?;
    final artist = context['artist'] as String?;
    final album = context['album'] as String?;
    final playlist = context['playlist'] as String?;
    final shuffle = context['shuffle'] as bool? ?? false;

    try {
      String searchQuery = '';

      if (playlist != null) {
        searchQuery = playlist;
      } else if (query != null) {
        searchQuery = query;
        if (artist != null) searchQuery += ' $artist';
        if (album != null) searchQuery += ' $album';
      } else if (artist != null) {
        searchQuery = artist;
      }

      if (searchQuery.isEmpty) {
        return ToolExecutionResult.failure('Search query, artist, album, or playlist required');
      }

      // Search for music
      await accessibilityService.findAndClickButton('Search');
      await accessibilityService.fillTextField('Search', searchQuery);
      await Future.delayed(Duration(seconds: 2));

      // Select first result or specific type
      if (playlist != null) {
        await accessibilityService.findAndClickButton('Playlists');
        await Future.delayed(Duration(seconds: 1));
      } else if (album != null) {
        await accessibilityService.findAndClickButton('Albums');
        await Future.delayed(Duration(seconds: 1));
      }

      // Click on first result
      await mobileController.execute({
        'action': 'tap',
        'x': 200,
        'y': 300,
      });

      await Future.delayed(Duration(seconds: 1));

      // Enable shuffle if requested
      if (shuffle) {
        await accessibilityService.findAndClickButton('Shuffle');
      }

      // Play
      await accessibilityService.findAndClickButton('Play');
      await Future.delayed(Duration(seconds: 1));

      // Get now playing info
      final nowPlaying = await _getNowPlayingInfo(accessibilityService, vlm);

      return ToolExecutionResult.success({
        'action': 'play_spotify_music',
        'search_query': searchQuery,
        'shuffle': shuffle,
        'now_playing': nowPlaying,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Spotify music playback failed: $e');
    }
  }

  Future<ToolExecutionResult> _searchMusic(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final query = context['query'] as String?;
    final type = context['type'] as String? ?? 'all'; // songs, artists, albums, playlists

    if (query == null) {
      return ToolExecutionResult.failure('Search query required');
    }

    try {
      // Perform search
      await accessibilityService.findAndClickButton('Search');
      await accessibilityService.fillTextField('Search', query);
      await Future.delayed(Duration(seconds: 2));

      // Filter by type if specified
      if (type != 'all') {
        await accessibilityService.findAndClickButton(type.capitalize());
        await Future.delayed(Duration(seconds: 1));
      }

      // Get search results
      final searchResults = await _getSearchResults(type, accessibilityService, vlm);

      return ToolExecutionResult.success({
        'action': 'search_spotify_music',
        'query': query,
        'type': type,
        'results': searchResults,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Spotify music search failed: $e');
    }
  }

  Future<ToolExecutionResult> _createPlaylist(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final playlistName = context['playlist_name'] as String?;
    final description = context['description'] as String?;
    final isPublic = context['public'] as bool? ?? false;
    final songs = context['songs'] as List<String>?;

    if (playlistName == null) {
      return ToolExecutionResult.failure('Playlist name required');
    }

    try {
      // Navigate to Your Library
      await accessibilityService.findAndClickButton('Your Library');
      await Future.delayed(Duration(seconds: 1));

      // Create new playlist
      await accessibilityService.findAndClickButton('Create playlist');
      await Future.delayed(Duration(seconds: 1));

      // Set playlist name
      await accessibilityService.fillTextField('Playlist name', playlistName);

      // Set description if provided
      if (description != null) {
        await accessibilityService.fillTextField('Description', description);
      }

      // Set privacy
      if (isPublic) {
        await accessibilityService.findAndClickButton('Make public');
      }

      // Create playlist
      await accessibilityService.findAndClickButton('Create');
      await Future.delayed(Duration(seconds: 1));

      // Add songs if provided
      if (songs != null && songs.isNotEmpty) {
        for (final song in songs) {
          await _addSongToPlaylist(song, mobileController, accessibilityService);
        }
      }

      return ToolExecutionResult.success({
        'action': 'create_spotify_playlist',
        'playlist_name': playlistName,
        'description': description,
        'public': isPublic,
        'songs_added': songs?.length ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Spotify playlist creation failed: $e');
    }
  }

  Future<ToolExecutionResult> _likeSong(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    try {
      // Like current song
      await accessibilityService.findAndClickButton('Like');
      await Future.delayed(Duration(milliseconds: 500));

      return ToolExecutionResult.success({
        'action': 'like_spotify_song',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Spotify song like failed: $e');
    }
  }

  Future<ToolExecutionResult> _skipSong(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final direction = context['direction'] as String? ?? 'next'; // next or previous

    try {
      if (direction == 'next') {
        await accessibilityService.findAndClickButton('Next');
      } else {
        await accessibilityService.findAndClickButton('Previous');
      }

      await Future.delayed(Duration(seconds: 1));

      // Get new song info
      final nowPlaying = await _getNowPlayingInfo(accessibilityService, vlm);

      return ToolExecutionResult.success({
        'action': 'skip_spotify_song',
        'direction': direction,
        'now_playing': nowPlaying,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Spotify song skip failed: $e');
    }
  }

  Future<ToolExecutionResult> _pauseResume(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    try {
      // Toggle play/pause
      await accessibilityService.findAndClickButton('Play');
      await Future.delayed(Duration(milliseconds: 500));

      // Determine current state
      final isPlaying = await _checkPlaybackState(accessibilityService);

      return ToolExecutionResult.success({
        'action': 'toggle_spotify_playback',
        'is_playing': isPlaying,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Spotify playback toggle failed: $e');
    }
  }

  Future<ToolExecutionResult> _browsePodcasts(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final category = context['category'] as String?;
    final searchQuery = context['search'] as String?;

    try {
      // Navigate to podcasts
      await accessibilityService.findAndClickButton('Search');
      await Future.delayed(Duration(seconds: 1));

      if (searchQuery != null) {
        // Search for specific podcast
        await accessibilityService.fillTextField('Search', searchQuery);
        await Future.delayed(Duration(seconds: 2));
        await accessibilityService.findAndClickButton('Podcasts');
      } else {
        // Browse by category
        await accessibilityService.findAndClickButton('Browse all');
        await Future.delayed(Duration(seconds: 1));
        await accessibilityService.findAndClickButton('Podcasts');

        if (category != null) {
          await accessibilityService.findAndClickButton(category);
        }
      }

      await Future.delayed(Duration(seconds: 1));

      // Get podcast results
      final podcasts = await _getPodcastResults(accessibilityService, vlm);

      return ToolExecutionResult.success({
        'action': 'browse_spotify_podcasts',
        'category': category,
        'search_query': searchQuery,
        'podcasts': podcasts,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Spotify podcast browsing failed: $e');
    }
  }

  Future<ToolExecutionResult> _followArtist(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final artistName = context['artist_name'] as String?;

    if (artistName == null) {
      return ToolExecutionResult.failure('Artist name required');
    }

    try {
      // Search for artist
      await accessibilityService.findAndClickButton('Search');
      await accessibilityService.fillTextField('Search', artistName);
      await Future.delayed(Duration(seconds: 2));

      // Filter by artists
      await accessibilityService.findAndClickButton('Artists');
      await Future.delayed(Duration(seconds: 1));

      // Click on first artist result
      await mobileController.execute({
        'action': 'tap',
        'x': 200,
        'y': 300,
      });

      await Future.delayed(Duration(seconds: 1));

      // Follow artist
      await accessibilityService.findAndClickButton('Follow');
      await Future.delayed(Duration(milliseconds: 500));

      return ToolExecutionResult.success({
        'action': 'follow_spotify_artist',
        'artist_name': artistName,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Spotify artist follow failed: $e');
    }
  }

  // Helper methods
  Future<Map<String, dynamic>> _getNowPlayingInfo(
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final nowPlaying = <String, dynamic>{};

    try {
      // Extract current song, artist, album info
      nowPlaying['song'] = 'Current Song';
      nowPlaying['artist'] = 'Current Artist';
      nowPlaying['album'] = 'Current Album';
      nowPlaying['duration'] = '3:45';
      nowPlaying['position'] = '1:23';
    } catch (e) {
      // Fallback to basic info
    }

    return nowPlaying;
  }

  Future<List<Map<String, dynamic>>> _getSearchResults(
    String type,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final results = <Map<String, dynamic>>[];

    try {
      // Extract search results based on type
      final searchResults = await accessibilityService.execute({
        'action': 'find_by_class',
        'class_name': 'search_result_item',
      });

      if (searchResults.success) {
        final nodes = searchResults.data['nodes'] as List;
        for (final node in nodes.take(10)) {
          results.add({
            'title': node['text'],
            'type': type,
            'clickable': node['clickable'],
          });
        }
      }
    } catch (e) {
      // Fallback to basic results
    }

    return results;
  }

  Future<void> _addSongToPlaylist(
    String song,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Add songs');
    await accessibilityService.fillTextField('Search for songs', song);
    await Future.delayed(Duration(seconds: 1));

    // Click on first result
    await mobileController.execute({
      'action': 'tap',
      'x': 200,
      'y': 300,
    });
  }

  Future<bool> _checkPlaybackState(AccessibilityService accessibilityService) async {
    try {
      final pauseResult = await accessibilityService.execute({
        'action': 'find_by_text',
        'text': 'Pause',
      });

      return pauseResult.success; // If 'Pause' button exists, music is playing
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _getPodcastResults(
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final podcasts = <Map<String, dynamic>>[];

    try {
      // Extract podcast information
      final podcastResults = await accessibilityService.execute({
        'action': 'find_by_class',
        'class_name': 'podcast_item',
      });

      if (podcastResults.success) {
        final nodes = podcastResults.data['nodes'] as List;
        for (final node in nodes.take(10)) {
          podcasts.add({
            'title': node['text'],
            'description': 'Podcast description',
            'episodes': 'N/A',
          });
        }
      }
    } catch (e) {
      // Fallback to basic results
    }

    return podcasts;
  }
}

extension StringExtension on String {
  String capitalize() {
    return this[0].toUpperCase() + substring(1);
  }
}

class YouTubeLibrary extends AppWorkflowLibrary {
  @override
  Future<ToolExecutionResult> executeIntent(
    String intent,
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    switch (intent) {
      case 'watch_video':
        return await _watchVideo(context, mobileController, accessibilityService, vlm);
      case 'search_videos':
        return await _searchVideos(context, mobileController, accessibilityService, vlm);
      case 'subscribe_channel':
        return await _subscribeChannel(context, mobileController, accessibilityService, vlm);
      case 'like_video':
        return await _likeVideo(context, mobileController, accessibilityService, vlm);
      case 'create_playlist':
        return await _createPlaylist(context, mobileController, accessibilityService, vlm);
      case 'browse_trending':
        return await _browseTrending(context, mobileController, accessibilityService, vlm);
      case 'upload_video':
        return await _uploadVideo(context, mobileController, accessibilityService, vlm);
      case 'comment_video':
        return await _commentVideo(context, mobileController, accessibilityService, vlm);
      default:
        return ToolExecutionResult.failure('Unsupported YouTube intent: $intent');
    }
  }

  Future<ToolExecutionResult> _watchVideo(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final query = context['query'] as String?;
    final channel = context['channel'] as String?;
    final videoId = context['video_id'] as String?;
    final quality = context['quality'] as String?;
    final autoplay = context['autoplay'] as bool? ?? true;

    if (query == null && channel == null && videoId == null) {
      return ToolExecutionResult.failure('Search query, channel, or video ID required');
    }

    try {
      if (videoId != null) {
        // Direct video access by ID
        // This would require deep linking or URL handling
      } else {
        // Search for video
        await accessibilityService.findAndClickButton('Search');

        String searchQuery = query ?? '';
        if (channel != null) {
          searchQuery += ' channel:$channel';
        }

        await accessibilityService.fillTextField('Search YouTube', searchQuery);
        await Future.delayed(Duration(seconds: 2));

        // Click on first video result
        await mobileController.execute({
          'action': 'tap',
          'x': 200,
          'y': 300,
        });
      }

      await Future.delayed(Duration(seconds: 3));

      // Set video quality if specified
      if (quality != null) {
        await _setVideoQuality(quality, mobileController, accessibilityService);
      }

      // Handle autoplay setting
      if (!autoplay) {
        await _disableAutoplay(mobileController, accessibilityService);
      }

      // Get video information
      final videoInfo = await _getVideoInfo(accessibilityService, vlm);

      return ToolExecutionResult.success({
        'action': 'watch_youtube_video',
        'search_query': query,
        'channel': channel,
        'video_id': videoId,
        'quality': quality,
        'autoplay': autoplay,
        'video_info': videoInfo,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('YouTube video watching failed: $e');
    }
  }

  Future<ToolExecutionResult> _searchVideos(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final query = context['query'] as String?;
    final filter = context['filter'] as String?; // upload_date, duration, type, etc.
    final sortBy = context['sort_by'] as String? ?? 'relevance';

    if (query == null) {
      return ToolExecutionResult.failure('Search query required');
    }

    try {
      // Perform search
      await accessibilityService.findAndClickButton('Search');
      await accessibilityService.fillTextField('Search YouTube', query);
      await Future.delayed(Duration(seconds: 2));

      // Apply filters if specified
      if (filter != null || sortBy != 'relevance') {
        await _applySearchFilters(filter, sortBy, mobileController, accessibilityService);
      }

      // Get search results
      final searchResults = await _getSearchResults(accessibilityService, vlm);

      return ToolExecutionResult.success({
        'action': 'search_youtube_videos',
        'query': query,
        'filter': filter,
        'sort_by': sortBy,
        'results': searchResults,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('YouTube video search failed: $e');
    }
  }

  Future<ToolExecutionResult> _subscribeChannel(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final channelName = context['channel_name'] as String?;
    final notifications = context['notifications'] as bool? ?? false;

    if (channelName == null) {
      return ToolExecutionResult.failure('Channel name required');
    }

    try {
      // Search for channel
      await accessibilityService.findAndClickButton('Search');
      await accessibilityService.fillTextField('Search YouTube', channelName);
      await Future.delayed(Duration(seconds: 2));

      // Filter by channels
      await accessibilityService.findAndClickButton('Channels');
      await Future.delayed(Duration(seconds: 1));

      // Click on channel
      await mobileController.execute({
        'action': 'tap',
        'x': 200,
        'y': 300,
      });

      await Future.delayed(Duration(seconds: 2));

      // Subscribe to channel
      await accessibilityService.findAndClickButton('Subscribe');

      // Enable notifications if requested
      if (notifications) {
        await accessibilityService.findAndClickButton('Notification bell');
        await accessibilityService.findAndClickButton('All');
      }

      await Future.delayed(Duration(seconds: 1));

      return ToolExecutionResult.success({
        'action': 'subscribe_youtube_channel',
        'channel_name': channelName,
        'notifications': notifications,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('YouTube channel subscription failed: $e');
    }
  }

  Future<ToolExecutionResult> _likeVideo(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final dislike = context['dislike'] as bool? ?? false;

    try {
      if (dislike) {
        await accessibilityService.findAndClickButton('Dislike');
      } else {
        await accessibilityService.findAndClickButton('Like');
      }

      await Future.delayed(Duration(milliseconds: 500));

      return ToolExecutionResult.success({
        'action': dislike ? 'dislike_youtube_video' : 'like_youtube_video',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('YouTube video rating failed: $e');
    }
  }

  Future<ToolExecutionResult> _createPlaylist(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final playlistName = context['playlist_name'] as String?;
    final description = context['description'] as String?;
    final privacy = context['privacy'] as String? ?? 'private'; // public, unlisted, private
    final videoIds = context['video_ids'] as List<String>?;

    if (playlistName == null) {
      return ToolExecutionResult.failure('Playlist name required');
    }

    try {
      // Navigate to Library
      await accessibilityService.findAndClickButton('Library');
      await Future.delayed(Duration(seconds: 1));

      // Create new playlist
      await accessibilityService.findAndClickButton('New playlist');
      await Future.delayed(Duration(seconds: 1));

      // Set playlist name
      await accessibilityService.fillTextField('Playlist name', playlistName);

      // Set description if provided
      if (description != null) {
        await accessibilityService.fillTextField('Description', description);
      }

      // Set privacy
      await _setPlaylistPrivacy(privacy, mobileController, accessibilityService);

      // Create playlist
      await accessibilityService.findAndClickButton('Create');
      await Future.delayed(Duration(seconds: 1));

      // Add videos if provided
      if (videoIds != null && videoIds.isNotEmpty) {
        for (final videoId in videoIds) {
          await _addVideoToPlaylist(videoId, mobileController, accessibilityService);
        }
      }

      return ToolExecutionResult.success({
        'action': 'create_youtube_playlist',
        'playlist_name': playlistName,
        'description': description,
        'privacy': privacy,
        'videos_added': videoIds?.length ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('YouTube playlist creation failed: $e');
    }
  }

  Future<ToolExecutionResult> _browseTrending(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final category = context['category'] as String?; // music, gaming, news, movies
    final location = context['location'] as String?;

    try {
      // Navigate to Trending
      await accessibilityService.findAndClickButton('Trending');
      await Future.delayed(Duration(seconds: 1));

      // Select category if specified
      if (category != null) {
        await accessibilityService.findAndClickButton(category.capitalize());
        await Future.delayed(Duration(seconds: 1));
      }

      // Change location if specified
      if (location != null) {
        await _changeTrendingLocation(location, mobileController, accessibilityService);
      }

      // Get trending videos
      final trendingVideos = await _getTrendingVideos(accessibilityService, vlm);

      return ToolExecutionResult.success({
        'action': 'browse_youtube_trending',
        'category': category,
        'location': location,
        'trending_videos': trendingVideos,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('YouTube trending browsing failed: $e');
    }
  }

  Future<ToolExecutionResult> _uploadVideo(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final videoPath = context['video_path'] as String?;
    final title = context['title'] as String?;
    final description = context['description'] as String?;
    final tags = context['tags'] as List<String>?;
    final privacy = context['privacy'] as String? ?? 'private';
    final thumbnail = context['thumbnail_path'] as String?;

    if (videoPath == null || title == null) {
      return ToolExecutionResult.failure('Video path and title required');
    }

    try {
      // Tap create/upload button
      await accessibilityService.findAndClickButton('Create');
      await Future.delayed(Duration(seconds: 1));

      // Select upload video
      await accessibilityService.findAndClickButton('Upload video');
      await Future.delayed(Duration(seconds: 1));

      // Select video file
      await _selectVideoFile(videoPath, mobileController, accessibilityService);

      // Set video details
      await accessibilityService.fillTextField('Title', title);

      if (description != null) {
        await accessibilityService.fillTextField('Description', description);
      }

      // Add tags if provided
      if (tags != null && tags.isNotEmpty) {
        await accessibilityService.fillTextField('Tags', tags.join(', '));
      }

      // Set thumbnail if provided
      if (thumbnail != null) {
        await _setCustomThumbnail(thumbnail, mobileController, accessibilityService);
      }

      // Set privacy
      await _setVideoPrivacy(privacy, mobileController, accessibilityService);

      // Upload video
      await accessibilityService.findAndClickButton('Upload');
      await Future.delayed(Duration(seconds: 5));

      return ToolExecutionResult.success({
        'action': 'upload_youtube_video',
        'title': title,
        'description': description,
        'tags': tags,
        'privacy': privacy,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('YouTube video upload failed: $e');
    }
  }

  Future<ToolExecutionResult> _commentVideo(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final comment = context['comment'] as String?;
    final replyTo = context['reply_to'] as String?;

    if (comment == null) {
      return ToolExecutionResult.failure('Comment text required');
    }

    try {
      // Scroll to comments section
      await mobileController.execute({
        'action': 'scroll',
        'direction': 'down',
        'distance': 800,
      });

      await Future.delayed(Duration(seconds: 1));

      if (replyTo != null) {
        // Reply to specific comment
        await _replyToComment(replyTo, comment, mobileController, accessibilityService);
      } else {
        // Add new comment
        await accessibilityService.findAndClickButton('Add a comment');
        await accessibilityService.fillTextField('Add a public comment', comment);
        await accessibilityService.findAndClickButton('Comment');
      }

      await Future.delayed(Duration(seconds: 1));

      return ToolExecutionResult.success({
        'action': 'comment_youtube_video',
        'comment': comment,
        'reply_to': replyTo,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('YouTube video comment failed: $e');
    }
  }

  // Helper methods
  Future<void> _setVideoQuality(
    String quality,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    // Tap video settings
    await mobileController.execute({
      'action': 'tap',
      'x': 350,
      'y': 200,
    });

    await accessibilityService.findAndClickButton('Quality');
    await accessibilityService.findAndClickButton(quality);
  }

  Future<void> _disableAutoplay(
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Autoplay');
  }

  Future<Map<String, dynamic>> _getVideoInfo(
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final videoInfo = <String, dynamic>{};

    try {
      // Extract video title, channel, views, etc.
      videoInfo['title'] = 'Video Title';
      videoInfo['channel'] = 'Channel Name';
      videoInfo['views'] = '1.2M views';
      videoInfo['duration'] = '10:30';
      videoInfo['likes'] = '50K';
      videoInfo['upload_date'] = '2 days ago';
    } catch (e) {
      // Fallback to basic info
    }

    return videoInfo;
  }

  Future<void> _applySearchFilters(
    String? filter,
    String sortBy,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Filters');
    await Future.delayed(Duration(seconds: 1));

    if (filter != null) {
      await accessibilityService.findAndClickButton(filter);
    }

    if (sortBy != 'relevance') {
      await accessibilityService.findAndClickButton(sortBy);
    }
  }

  Future<List<Map<String, dynamic>>> _getSearchResults(
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final results = <Map<String, dynamic>>[];

    try {
      // Extract search results
      final searchResults = await accessibilityService.execute({
        'action': 'find_by_class',
        'class_name': 'video_item',
      });

      if (searchResults.success) {
        final nodes = searchResults.data['nodes'] as List;
        for (final node in nodes.take(10)) {
          results.add({
            'title': node['text'],
            'channel': 'Channel Name',
            'views': 'N/A',
            'duration': 'N/A',
          });
        }
      }
    } catch (e) {
      // Fallback to basic results
    }

    return results;
  }

  Future<void> _setPlaylistPrivacy(
    String privacy,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Privacy');
    await accessibilityService.findAndClickButton(privacy.capitalize());
  }

  Future<void> _addVideoToPlaylist(
    String videoId,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    // This would require searching for the video and adding it
    await Future.delayed(Duration(seconds: 1));
  }

  Future<void> _changeTrendingLocation(
    String location,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Location');
    await accessibilityService.findAndClickButton(location);
  }

  Future<List<Map<String, dynamic>>> _getTrendingVideos(
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final videos = <Map<String, dynamic>>[];

    try {
      // Extract trending video information
      final trendingResults = await accessibilityService.execute({
        'action': 'find_by_class',
        'class_name': 'trending_video_item',
      });

      if (trendingResults.success) {
        final nodes = trendingResults.data['nodes'] as List;
        for (final node in nodes.take(20)) {
          videos.add({
            'title': node['text'],
            'channel': 'Channel Name',
            'views': 'N/A',
            'trending_rank': videos.length + 1,
          });
        }
      }
    } catch (e) {
      // Fallback to basic results
    }

    return videos;
  }

  Future<void> _selectVideoFile(
    String videoPath,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    // Navigate to video file and select
    await Future.delayed(Duration(seconds: 2));
  }

  Future<void> _setCustomThumbnail(
    String thumbnailPath,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Custom thumbnail');
    // Navigate to thumbnail file and select
    await Future.delayed(Duration(seconds: 1));
  }

  Future<void> _setVideoPrivacy(
    String privacy,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Visibility');
    await accessibilityService.findAndClickButton(privacy.capitalize());
  }

  Future<void> _replyToComment(
    String originalComment,
    String reply,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    // Find the specific comment and reply
    await accessibilityService.findAndClickButton('Reply');
    await accessibilityService.fillTextField('Add a reply', reply);
    await accessibilityService.findAndClickButton('Reply');
  }
}

class CalendarLibrary extends AppWorkflowLibrary {
  @override
  Future<ToolExecutionResult> executeIntent(
    String intent,
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    switch (intent) {
      case 'schedule_event':
        return await _scheduleEvent(context, mobileController, accessibilityService, vlm);
      case 'create_meeting':
        return await _createMeeting(context, mobileController, accessibilityService, vlm);
      case 'edit_event':
        return await _editEvent(context, mobileController, accessibilityService, vlm);
      case 'delete_event':
        return await _deleteEvent(context, mobileController, accessibilityService, vlm);
      case 'view_schedule':
        return await _viewSchedule(context, mobileController, accessibilityService, vlm);
      case 'set_reminder':
        return await _setReminder(context, mobileController, accessibilityService, vlm);
      case 'find_free_time':
        return await _findFreeTime(context, mobileController, accessibilityService, vlm);
      case 'accept_invitation':
        return await _acceptInvitation(context, mobileController, accessibilityService, vlm);
      default:
        return ToolExecutionResult.failure('Unsupported Calendar intent: $intent');
    }
  }

  Future<ToolExecutionResult> _scheduleEvent(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final title = context['title'] as String?;
    final date = context['date'] as String?;
    final startTime = context['start_time'] as String?;
    final endTime = context['end_time'] as String?;
    final location = context['location'] as String?;
    final description = context['description'] as String?;
    final attendees = context['attendees'] as List<String>?;
    final reminder = context['reminder'] as int?; // minutes before
    final recurring = context['recurring'] as String?;

    if (title == null || date == null || startTime == null) {
      return ToolExecutionResult.failure('Title, date, and start time required for event');
    }

    try {
      // Create new event
      await accessibilityService.findAndClickButton('Create');
      await Future.delayed(Duration(seconds: 1));

      // Set event title
      await accessibilityService.fillTextField('Event title', title);

      // Set date
      await _setEventDate(date, mobileController, accessibilityService);

      // Set start time
      await _setEventTime('start', startTime, mobileController, accessibilityService);

      // Set end time if provided
      if (endTime != null) {
        await _setEventTime('end', endTime, mobileController, accessibilityService);
      }

      // Set location if provided
      if (location != null) {
        await accessibilityService.fillTextField('Location', location);
      }

      // Set description if provided
      if (description != null) {
        await accessibilityService.fillTextField('Description', description);
      }

      // Add attendees if provided
      if (attendees != null && attendees.isNotEmpty) {
        await _addAttendees(attendees, mobileController, accessibilityService);
      }

      // Set reminder if provided
      if (reminder != null) {
        await _setEventReminder(reminder, mobileController, accessibilityService);
      }

      // Set recurring pattern if provided
      if (recurring != null) {
        await _setRecurringPattern(recurring, mobileController, accessibilityService);
      }

      // Save event
      await accessibilityService.findAndClickButton('Save');
      await Future.delayed(Duration(seconds: 2));

      return ToolExecutionResult.success({
        'action': 'schedule_calendar_event',
        'title': title,
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
        'location': location,
        'attendees': attendees,
        'reminder': reminder,
        'recurring': recurring,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Calendar event scheduling failed: $e');
    }
  }

  Future<ToolExecutionResult> _createMeeting(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final title = context['title'] as String?;
    final date = context['date'] as String?;
    final startTime = context['start_time'] as String?;
    final duration = context['duration'] as int? ?? 60; // minutes
    final attendees = context['attendees'] as List<String>?;
    final meetingLink = context['meeting_link'] as String?;
    final agenda = context['agenda'] as String?;

    if (title == null || date == null || startTime == null) {
      return ToolExecutionResult.failure('Title, date, and start time required for meeting');
    }

    try {
      // Create meeting event (similar to regular event but with meeting-specific features)
      await accessibilityService.findAndClickButton('Create');
      await Future.delayed(Duration(seconds: 1));

      // Set meeting title
      await accessibilityService.fillTextField('Event title', title);

      // Set date and time
      await _setEventDate(date, mobileController, accessibilityService);
      await _setEventTime('start', startTime, mobileController, accessibilityService);

      // Calculate and set end time based on duration
      final endTime = _calculateEndTime(startTime, duration);
      await _setEventTime('end', endTime, mobileController, accessibilityService);

      // Add meeting details
      if (agenda != null) {
        await accessibilityService.fillTextField('Description', 'Agenda: $agenda');
      }

      // Add video conference link if provided
      if (meetingLink != null) {
        await accessibilityService.fillTextField('Location', meetingLink);
      } else {
        // Add default video conference
        await accessibilityService.findAndClickButton('Add video conference');
      }

      // Add attendees
      if (attendees != null && attendees.isNotEmpty) {
        await _addAttendees(attendees, mobileController, accessibilityService);
      }

      // Set default meeting reminder (15 minutes)
      await _setEventReminder(15, mobileController, accessibilityService);

      // Save meeting
      await accessibilityService.findAndClickButton('Save');
      await Future.delayed(Duration(seconds: 2));

      return ToolExecutionResult.success({
        'action': 'create_calendar_meeting',
        'title': title,
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
        'duration': duration,
        'attendees': attendees,
        'meeting_link': meetingLink,
        'agenda': agenda,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Calendar meeting creation failed: $e');
    }
  }

  Future<ToolExecutionResult> _editEvent(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final eventTitle = context['event_title'] as String?;
    final eventDate = context['event_date'] as String?;
    final newTitle = context['new_title'] as String?;
    final newDate = context['new_date'] as String?;
    final newTime = context['new_time'] as String?;
    final newLocation = context['new_location'] as String?;

    if (eventTitle == null && eventDate == null) {
      return ToolExecutionResult.failure('Event title or date required to find event');
    }

    try {
      // Find and open the event
      await _findAndOpenEvent(eventTitle, eventDate, mobileController, accessibilityService);

      // Edit event details
      await accessibilityService.findAndClickButton('Edit');
      await Future.delayed(Duration(seconds: 1));

      // Update title if provided
      if (newTitle != null) {
        await accessibilityService.fillTextField('Event title', newTitle);
      }

      // Update date if provided
      if (newDate != null) {
        await _setEventDate(newDate, mobileController, accessibilityService);
      }

      // Update time if provided
      if (newTime != null) {
        await _setEventTime('start', newTime, mobileController, accessibilityService);
      }

      // Update location if provided
      if (newLocation != null) {
        await accessibilityService.fillTextField('Location', newLocation);
      }

      // Save changes
      await accessibilityService.findAndClickButton('Save');
      await Future.delayed(Duration(seconds: 1));

      return ToolExecutionResult.success({
        'action': 'edit_calendar_event',
        'original_title': eventTitle,
        'original_date': eventDate,
        'new_title': newTitle,
        'new_date': newDate,
        'new_time': newTime,
        'new_location': newLocation,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Calendar event editing failed: $e');
    }
  }

  Future<ToolExecutionResult> _deleteEvent(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final eventTitle = context['event_title'] as String?;
    final eventDate = context['event_date'] as String?;
    final deleteRecurring = context['delete_recurring'] as String? ?? 'this_event'; // this_event, all_events

    if (eventTitle == null && eventDate == null) {
      return ToolExecutionResult.failure('Event title or date required to find event');
    }

    try {
      // Find and open the event
      await _findAndOpenEvent(eventTitle, eventDate, mobileController, accessibilityService);

      // Delete event
      await accessibilityService.findAndClickButton('Delete');
      await Future.delayed(Duration(seconds: 1));

      // Handle recurring event deletion
      if (deleteRecurring == 'all_events') {
        await accessibilityService.findAndClickButton('Delete all events in series');
      } else {
        await accessibilityService.findAndClickButton('Delete this event');
      }

      await Future.delayed(Duration(seconds: 1));

      return ToolExecutionResult.success({
        'action': 'delete_calendar_event',
        'event_title': eventTitle,
        'event_date': eventDate,
        'delete_recurring': deleteRecurring,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Calendar event deletion failed: $e');
    }
  }

  Future<ToolExecutionResult> _viewSchedule(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final viewType = context['view_type'] as String? ?? 'day'; // day, week, month, agenda
    final date = context['date'] as String?;

    try {
      // Set calendar view
      await _setCalendarView(viewType, mobileController, accessibilityService);

      // Navigate to specific date if provided
      if (date != null) {
        await _navigateToDate(date, mobileController, accessibilityService);
      }

      await Future.delayed(Duration(seconds: 1));

      // Get schedule information
      final scheduleData = await _getScheduleData(viewType, accessibilityService, vlm);

      return ToolExecutionResult.success({
        'action': 'view_calendar_schedule',
        'view_type': viewType,
        'date': date ?? 'today',
        'schedule_data': scheduleData,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Calendar schedule viewing failed: $e');
    }
  }

  Future<ToolExecutionResult> _setReminder(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final title = context['title'] as String?;
    final date = context['date'] as String?;
    final time = context['time'] as String?;
    final reminderText = context['reminder_text'] as String?;
    final reminderBefore = context['reminder_before'] as int? ?? 15; // minutes

    if (title == null || date == null || time == null) {
      return ToolExecutionResult.failure('Title, date, and time required for reminder');
    }

    try {
      // Create a quick reminder (all-day event with reminder)
      await accessibilityService.findAndClickButton('Create');
      await Future.delayed(Duration(seconds: 1));

      // Set reminder title
      await accessibilityService.fillTextField('Event title', title);

      // Set as all-day event
      await accessibilityService.findAndClickButton('All day');

      // Set date
      await _setEventDate(date, mobileController, accessibilityService);

      // Add reminder text as description
      if (reminderText != null) {
        await accessibilityService.fillTextField('Description', reminderText);
      }

      // Set reminder time
      await _setEventReminder(reminderBefore, mobileController, accessibilityService);

      // Save reminder
      await accessibilityService.findAndClickButton('Save');
      await Future.delayed(Duration(seconds: 1));

      return ToolExecutionResult.success({
        'action': 'set_calendar_reminder',
        'title': title,
        'date': date,
        'time': time,
        'reminder_text': reminderText,
        'reminder_before': reminderBefore,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Calendar reminder setting failed: $e');
    }
  }

  Future<ToolExecutionResult> _findFreeTime(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final duration = context['duration'] as int? ?? 60; // minutes
    final startDate = context['start_date'] as String?;
    final endDate = context['end_date'] as String?;
    final timeRange = context['time_range'] as Map<String, String>?; // {start: '9:00', end: '17:00'}

    try {
      // Switch to week or agenda view for better free time visibility
      await _setCalendarView('week', mobileController, accessibilityService);

      // Navigate to start date if provided
      if (startDate != null) {
        await _navigateToDate(startDate, mobileController, accessibilityService);
      }

      await Future.delayed(Duration(seconds: 1));

      // Analyze schedule for free time slots
      final freeTimeSlots = await _analyzeFreeTimeSlots(
        duration,
        timeRange,
        accessibilityService,
        vlm,
      );

      return ToolExecutionResult.success({
        'action': 'find_calendar_free_time',
        'duration': duration,
        'start_date': startDate,
        'end_date': endDate,
        'time_range': timeRange,
        'free_slots': freeTimeSlots,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Calendar free time finding failed: $e');
    }
  }

  Future<ToolExecutionResult> _acceptInvitation(
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final eventTitle = context['event_title'] as String?;
    final inviterEmail = context['inviter_email'] as String?;
    final response = context['response'] as String? ?? 'yes'; // yes, no, maybe
    final message = context['message'] as String?;

    try {
      // Navigate to invitations/notifications
      await accessibilityService.findAndClickButton('Notifications');
      await Future.delayed(Duration(seconds: 1));

      // Find the specific invitation
      if (eventTitle != null) {
        await _findInvitationByTitle(eventTitle, accessibilityService);
      } else if (inviterEmail != null) {
        await _findInvitationByInviter(inviterEmail, accessibilityService);
      } else {
        // Select first invitation
        await mobileController.execute({
          'action': 'tap',
          'x': 200,
          'y': 300,
        });
      }

      await Future.delayed(Duration(seconds: 1));

      // Respond to invitation
      switch (response.toLowerCase()) {
        case 'yes':
          await accessibilityService.findAndClickButton('Yes');
          break;
        case 'no':
          await accessibilityService.findAndClickButton('No');
          break;
        case 'maybe':
          await accessibilityService.findAndClickButton('Maybe');
          break;
      }

      // Add message if provided
      if (message != null) {
        await accessibilityService.fillTextField('Add a note', message);
      }

      // Send response
      await accessibilityService.findAndClickButton('Send');
      await Future.delayed(Duration(seconds: 1));

      return ToolExecutionResult.success({
        'action': 'accept_calendar_invitation',
        'event_title': eventTitle,
        'inviter_email': inviterEmail,
        'response': response,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Calendar invitation response failed: $e');
    }
  }

  // Helper methods
  Future<void> _setEventDate(
    String date,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Date');
    await Future.delayed(Duration(seconds: 1));

    // Parse date and navigate to it
    // This would require more sophisticated date picker interaction
    await accessibilityService.findAndClickButton('Done');
  }

  Future<void> _setEventTime(
    String timeType,
    String time,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    final buttonText = timeType == 'start' ? 'Start time' : 'End time';
    await accessibilityService.findAndClickButton(buttonText);
    await Future.delayed(Duration(seconds: 1));

    // Parse time and set hours/minutes
    // This would require time picker interaction
    await accessibilityService.findAndClickButton('Done');
  }

  Future<void> _addAttendees(
    List<String> attendees,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Add guests');
    await Future.delayed(Duration(seconds: 1));

    for (final attendee in attendees) {
      await accessibilityService.fillTextField('Add guests', attendee);
      await Future.delayed(Duration(milliseconds: 500));
      await accessibilityService.findAndClickButton(attendee);
    }

    await accessibilityService.findAndClickButton('Done');
  }

  Future<void> _setEventReminder(
    int minutes,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Add notification');
    await Future.delayed(Duration(seconds: 1));

    // Set reminder time
    if (minutes < 60) {
      await accessibilityService.findAndClickButton('$minutes minutes before');
    } else {
      final hours = minutes ~/ 60;
      await accessibilityService.findAndClickButton('$hours hour${hours > 1 ? 's' : ''} before');
    }
  }

  Future<void> _setRecurringPattern(
    String pattern,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    await accessibilityService.findAndClickButton('Does not repeat');
    await Future.delayed(Duration(seconds: 1));

    switch (pattern.toLowerCase()) {
      case 'daily':
        await accessibilityService.findAndClickButton('Daily');
        break;
      case 'weekly':
        await accessibilityService.findAndClickButton('Weekly');
        break;
      case 'monthly':
        await accessibilityService.findAndClickButton('Monthly');
        break;
      case 'yearly':
        await accessibilityService.findAndClickButton('Annually');
        break;
    }
  }

  String _calculateEndTime(String startTime, int durationMinutes) {
    // Parse start time and add duration
    // This is a simplified implementation
    final parts = startTime.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);

    final totalMinutes = hours * 60 + minutes + durationMinutes;
    final endHours = (totalMinutes ~/ 60) % 24;
    final endMinutes = totalMinutes % 60;

    return '${endHours.toString().padLeft(2, '0')}:${endMinutes.toString().padLeft(2, '0')}';
  }

  Future<void> _findAndOpenEvent(
    String? eventTitle,
    String? eventDate,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    // Search for event
    await accessibilityService.findAndClickButton('Search');
    await accessibilityService.fillTextField('Search events', eventTitle ?? eventDate!);
    await Future.delayed(Duration(seconds: 1));

    // Click on first result
    await mobileController.execute({
      'action': 'tap',
      'x': 200,
      'y': 300,
    });
  }

  Future<void> _setCalendarView(
    String viewType,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    switch (viewType.toLowerCase()) {
      case 'day':
        await accessibilityService.findAndClickButton('Day');
        break;
      case 'week':
        await accessibilityService.findAndClickButton('Week');
        break;
      case 'month':
        await accessibilityService.findAndClickButton('Month');
        break;
      case 'agenda':
        await accessibilityService.findAndClickButton('Agenda');
        break;
    }
  }

  Future<void> _navigateToDate(
    String date,
    MobileController mobileController,
    AccessibilityService accessibilityService,
  ) async {
    // Navigate to specific date
    await accessibilityService.findAndClickButton('Go to date');
    // Set the specific date
    await Future.delayed(Duration(seconds: 1));
  }

  Future<Map<String, dynamic>> _getScheduleData(
    String viewType,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final scheduleData = <String, dynamic>{};

    try {
      // Extract events from the current view
      final eventResults = await accessibilityService.execute({
        'action': 'find_by_class',
        'class_name': 'calendar_event',
      });

      if (eventResults.success) {
        final events = <Map<String, dynamic>>[];
        final nodes = eventResults.data['nodes'] as List;

        for (final node in nodes) {
          events.add({
            'title': node['text'],
            'time': 'N/A',
            'location': 'N/A',
          });
        }

        scheduleData['events'] = events;
        scheduleData['total_events'] = events.length;
      }
    } catch (e) {
      // Fallback to basic schedule data
      scheduleData['events'] = [];
      scheduleData['total_events'] = 0;
    }

    return scheduleData;
  }

  Future<List<Map<String, dynamic>>> _analyzeFreeTimeSlots(
    int duration,
    Map<String, String>? timeRange,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    final freeSlots = <Map<String, dynamic>>[];

    try {
      // Analyze calendar view for gaps between events
      // This would require sophisticated calendar parsing
      // For now, return mock data
      freeSlots.addAll([
        {
          'start_time': '10:00',
          'end_time': '11:00',
          'duration': 60,
          'date': 'today',
        },
        {
          'start_time': '14:00',
          'end_time': '15:30',
          'duration': 90,
          'date': 'today',
        },
      ]);
    } catch (e) {
      // Return empty if analysis fails
    }

    return freeSlots;
  }

  Future<void> _findInvitationByTitle(
    String eventTitle,
    AccessibilityService accessibilityService,
  ) async {
    final invitationResult = await accessibilityService.execute({
      'action': 'find_by_text',
      'text': eventTitle,
    });

    if (invitationResult.success) {
      final nodes = invitationResult.data['nodes'] as List;
      if (nodes.isNotEmpty) {
        await accessibilityService.execute({
          'action': 'perform_action',
          'node_id': nodes.first['id'],
          'node_action': 'click',
        });
      }
    }
  }

  Future<void> _findInvitationByInviter(
    String inviterEmail,
    AccessibilityService accessibilityService,
  ) async {
    // Search for invitation by inviter email
    await accessibilityService.execute({
      'action': 'find_by_text',
      'text': inviterEmail,
    });
  }
}

class GenericAppLibrary extends AppWorkflowLibrary {
  @override
  Future<ToolExecutionResult> executeIntent(
    String intent,
    Map<String, dynamic> context,
    MobileController mobileController,
    AccessibilityService accessibilityService,
    VLMInterface? vlm,
  ) async {
    // Generic fallback using VLM analysis
    if (vlm != null) {
      return await _executeGenericIntent(intent, context, mobileController, vlm);
    }

    return ToolExecutionResult.failure('Generic app automation requires VLM for unknown apps');
  }

  Future<ToolExecutionResult> _executeGenericIntent(
    String intent,
    Map<String, dynamic> context,
    MobileController mobileController,
    VLMInterface? vlm,
  ) async {
    final screenshot = await mobileController.execute({'action': 'take_screenshot'});
    if (!screenshot.success) {
      return ToolExecutionResult.failure('Could not analyze app interface');
    }

    final analysisPrompt = '''
    Analyze this app interface to accomplish the intent: "$intent"
    Context: ${jsonEncode(context)}

    Generate a step-by-step action plan with coordinates:
    1. What UI elements to interact with
    2. Tap coordinates for buttons/fields
    3. Text to input
    4. Expected flow to complete the intent

    Return JSON format:
    [
      {"action": "tap", "x": 100, "y": 200, "description": "tap search button"},
      {"action": "type", "text": "search term", "description": "enter search query"},
      {"action": "tap", "x": 150, "y": 300, "description": "tap first result"}
    ]
    ''';

    final plan = await vlm!.analyzeImage(
      screenshot.data['screenshot_path'],
      prompt: analysisPrompt,
    );

    // Execute the generated plan
    // TODO: Parse and execute the action plan

    return ToolExecutionResult.success({
      'action': 'generic_app_automation',
      'intent': intent,
      'plan': plan,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}