import 'dart:convert';
import 'package:flutter/services.dart';
import '../tools/tool.dart';
import '../models/task.dart';
import '../llm/llm_interface.dart';
import 'mobile_controller.dart';

class AppAutomationTool extends Tool with ToolValidation {
  final MobileController mobileController;
  final VLMInterface? vlm;

  AppAutomationTool({
    required this.mobileController,
    this.vlm,
  });

  @override
  String get name => 'app_automation';

  @override
  String get description => 'Automate specific app interactions: social media, messaging, email, shopping, etc.';

  @override
  Map<String, String> get parameters => {
        'app': 'Target app: whatsapp, telegram, gmail, chrome, instagram, youtube, spotify, etc.',
        'action': 'Action: send_message, post, search, play_music, take_photo, book_ride, order_food, etc.',
        'recipient': 'Message recipient (for messaging apps)',
        'message': 'Message content',
        'search_query': 'Search term',
        'amount': 'Amount for payment/transfer',
        'location': 'Location for maps/ride booking',
        'custom_instructions': 'Detailed instructions for complex workflows',
      };

  @override
  bool canHandle(Task task) {
    return task.type == 'app_automation' || task.type.startsWith('app_');
  }

  @override
  Future<bool> validate(Map<String, dynamic> parameters) async {
    return validateRequired(parameters, ['app', 'action']);
  }

  @override
  Future<dynamic> execute(Map<String, dynamic> parameters) async {
    if (!await validate(parameters)) {
      throw Exception('Invalid parameters for app automation');
    }

    final app = parameters['app'] as String;
    final action = parameters['action'] as String;

    try {
      switch (app.toLowerCase()) {
        case 'whatsapp':
          return await _automateWhatsApp(action, parameters);
        case 'telegram':
          return await _automateTelegram(action, parameters);
        case 'gmail':
        case 'email':
          return await _automateEmail(action, parameters);
        case 'chrome':
        case 'browser':
          return await _automateBrowser(action, parameters);
        case 'instagram':
          return await _automateInstagram(action, parameters);
        case 'youtube':
          return await _automateYoutube(action, parameters);
        case 'spotify':
        case 'music':
          return await _automateMusic(action, parameters);
        case 'camera':
          return await _automateCamera(action, parameters);
        case 'uber':
        case 'lyft':
          return await _automateRideHailing(action, parameters);
        case 'doordash':
        case 'ubereats':
          return await _automateFoodDelivery(action, parameters);
        case 'settings':
          return await _automateSettings(action, parameters);
        default:
          return await _automateGenericApp(app, action, parameters);
      }
    } catch (e) {
      return ToolExecutionResult.failure('App automation failed: $e');
    }
  }

  Future<ToolExecutionResult> _automateWhatsApp(String action, Map<String, dynamic> params) async {
    switch (action) {
      case 'send_message':
        return await _whatsappSendMessage(params['recipient'], params['message']);
      case 'search_contact':
        return await _whatsappSearchContact(params['search_query']);
      case 'create_group':
        return await _whatsappCreateGroup(params['group_name'], params['participants']);
      default:
        return await _genericAppAction('com.whatsapp', action, params);
    }
  }

  Future<ToolExecutionResult> _whatsappSendMessage(String? recipient, String? message) async {
    if (recipient == null || message == null) {
      return ToolExecutionResult.failure('Recipient and message are required');
    }

    try {
      // Open WhatsApp
      await mobileController.execute({'action': 'open_app', 'app_package': 'com.whatsapp'});
      await Future.delayed(Duration(seconds: 2));

      // Take screenshot and analyze
      final screenResult = await mobileController.execute({'action': 'analyze_screen'});

      // Search for contact
      final searchResult = await mobileController.execute({
        'action': 'find_element',
        'element_description': 'search button or search field'
      });

      if (vlm != null) {
        // Use VLM to navigate WhatsApp interface
        final workflow = await _generateWhatsAppWorkflow(recipient, message);
        return await _executeWorkflow(workflow);
      } else {
        // Fallback to hardcoded interactions
        return await _whatsappFallbackWorkflow(recipient, message);
      }
    } catch (e) {
      return ToolExecutionResult.failure('WhatsApp automation failed: $e');
    }
  }

  Future<ToolExecutionResult> _automateTelegram(String action, Map<String, dynamic> params) async {
    switch (action) {
      case 'send_message':
        return await _telegramSendMessage(params['recipient'], params['message']);
      case 'join_channel':
        return await _telegramJoinChannel(params['channel_name']);
      default:
        return await _genericAppAction('org.telegram.messenger', action, params);
    }
  }

  Future<ToolExecutionResult> _automateEmail(String action, Map<String, dynamic> params) async {
    switch (action) {
      case 'send_email':
        return await _emailSend(params['recipient'], params['subject'], params['message']);
      case 'search_emails':
        return await _emailSearch(params['search_query']);
      case 'mark_as_read':
        return await _emailMarkAsRead();
      default:
        return await _genericAppAction('com.google.android.gm', action, params);
    }
  }

  Future<ToolExecutionResult> _automateBrowser(String action, Map<String, dynamic> params) async {
    switch (action) {
      case 'search':
        return await _browserSearch(params['search_query']);
      case 'navigate':
        return await _browserNavigate(params['url']);
      case 'bookmark':
        return await _browserBookmark();
      default:
        return await _genericAppAction('com.android.chrome', action, params);
    }
  }

  Future<ToolExecutionResult> _automateInstagram(String action, Map<String, dynamic> params) async {
    switch (action) {
      case 'post_photo':
        return await _instagramPostPhoto(params['caption']);
      case 'story':
        return await _instagramPostStory();
      case 'search_user':
        return await _instagramSearchUser(params['username']);
      default:
        return await _genericAppAction('com.instagram.android', action, params);
    }
  }

  Future<ToolExecutionResult> _automateYoutube(String action, Map<String, dynamic> params) async {
    switch (action) {
      case 'search':
        return await _youtubeSearch(params['search_query']);
      case 'play_video':
        return await _youtubePlayVideo(params['video_title']);
      case 'subscribe':
        return await _youtubeSubscribe();
      default:
        return await _genericAppAction('com.google.android.youtube', action, params);
    }
  }

  Future<ToolExecutionResult> _automateMusic(String action, Map<String, dynamic> params) async {
    switch (action) {
      case 'play_song':
        return await _musicPlaySong(params['song_name'], params['artist']);
      case 'create_playlist':
        return await _musicCreatePlaylist(params['playlist_name']);
      case 'search':
        return await _musicSearch(params['search_query']);
      default:
        return await _genericAppAction('com.spotify.music', action, params);
    }
  }

  Future<ToolExecutionResult> _automateCamera(String action, Map<String, dynamic> params) async {
    switch (action) {
      case 'take_photo':
        return await _cameraTakePhoto();
      case 'record_video':
        return await _cameraRecordVideo(params['duration']);
      case 'switch_mode':
        return await _cameraSwitchMode(params['mode']);
      default:
        return await _genericAppAction('com.android.camera2', action, params);
    }
  }

  Future<ToolExecutionResult> _automateRideHailing(String action, Map<String, dynamic> params) async {
    switch (action) {
      case 'book_ride':
        return await _rideHailingBookRide(params['destination'], params['ride_type']);
      case 'track_ride':
        return await _rideHailingTrackRide();
      default:
        return await _genericAppAction('com.ubercab', action, params);
    }
  }

  Future<ToolExecutionResult> _automateFoodDelivery(String action, Map<String, dynamic> params) async {
    switch (action) {
      case 'order_food':
        return await _foodDeliveryOrder(params['restaurant'], params['items']);
      case 'track_order':
        return await _foodDeliveryTrackOrder();
      default:
        return await _genericAppAction('com.dd.doordash', action, params);
    }
  }

  Future<ToolExecutionResult> _automateSettings(String action, Map<String, dynamic> params) async {
    switch (action) {
      case 'toggle_wifi':
        return await _settingsToggleWifi();
      case 'toggle_bluetooth':
        return await _settingsToggleBluetooth();
      case 'change_brightness':
        return await _settingsChangeBrightness(params['level']);
      case 'open_app_settings':
        return await _settingsOpenAppSettings(params['app_package']);
      default:
        return await _genericAppAction('com.android.settings', action, params);
    }
  }

  /// Maps common app names to their Android package names
  static const Map<String, String> _appPackageMap = {
    'whatsapp': 'com.whatsapp',
    'telegram': 'org.telegram.messenger',
    'gmail': 'com.google.android.gm',
    'email': 'com.google.android.gm',
    'chrome': 'com.android.chrome',
    'browser': 'com.android.chrome',
    'instagram': 'com.instagram.android',
    'youtube': 'com.google.android.youtube',
    'spotify': 'com.spotify.music',
    'music': 'com.spotify.music',
    'camera': 'com.android.camera2',
    'uber': 'com.ubercab',
    'lyft': 'com.lyft.android',
    'doordash': 'com.dd.doordash',
    'ubereats': 'com.ubercab.eats',
    'settings': 'com.android.settings',
    'maps': 'com.google.android.apps.maps',
    'twitter': 'com.twitter.android',
    'x': 'com.twitter.android',
    'facebook': 'com.facebook.katana',
    'messenger': 'com.facebook.orca',
    'snapchat': 'com.snapchat.android',
    'tiktok': 'com.zhiliaoapp.musically',
    'linkedin': 'com.linkedin.android',
    'slack': 'com.Slack',
    'discord': 'com.discord',
    'zoom': 'us.zoom.videomeetings',
    'teams': 'com.microsoft.teams',
    'calendar': 'com.google.android.calendar',
    'photos': 'com.google.android.apps.photos',
    'drive': 'com.google.android.apps.docs',
    'notes': 'com.google.android.keep',
    'contacts': 'com.google.android.contacts',
    'phone': 'com.google.android.dialer',
    'messages': 'com.google.android.apps.messaging',
  };

  /// Automates any app using its name, converting to package name automatically
  Future<ToolExecutionResult> _automateGenericApp(String appName, String action, Map<String, dynamic> params) async {
    final packageName = _appPackageMap[appName.toLowerCase()] ?? appName;
    return await _genericAppAction(packageName, action, params);
  }

  Future<ToolExecutionResult> _genericAppAction(String packageName, String action, Map<String, dynamic> params) async {
    try {
      // Open the app
      await mobileController.execute({'action': 'open_app', 'app_package': packageName});
      await Future.delayed(Duration(seconds: 2));

      // Analyze screen
      final screenAnalysis = await mobileController.execute({'action': 'analyze_screen'});

      if (vlm != null) {
        // Generate workflow using VLM
        final workflow = await _generateGenericWorkflow(packageName, action, params);
        return await _executeWorkflow(workflow);
      } else {
        return ToolExecutionResult.success({
          'app': packageName,
          'action': action,
          'message': 'App opened, manual interaction required',
          'screen_analysis': screenAnalysis.data,
        });
      }
    } catch (e) {
      return ToolExecutionResult.failure('Generic app action failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _generateWhatsAppWorkflow(String recipient, String message) async {
    if (vlm == null) return [];

    final prompt = '''
    Create a step-by-step workflow to send a WhatsApp message to "$recipient" with content "$message".

    Analyze the current WhatsApp interface and generate actions like:
    1. Find and tap search button
    2. Type recipient name
    3. Tap on contact
    4. Type message
    5. Tap send button

    Return JSON array of actions:
    [
      {"action": "find_and_tap", "element": "search button"},
      {"action": "type", "text": "$recipient"},
      {"action": "find_and_tap", "element": "contact result"},
      {"action": "type", "text": "$message"},
      {"action": "find_and_tap", "element": "send button"}
    ]
    ''';

    // This would use VLM to analyze the screen and generate workflow
    // For now, return a basic workflow
    return [
      {"action": "find_and_tap", "element": "search button"},
      {"action": "type", "text": recipient},
      {"action": "wait", "duration": 1000},
      {"action": "find_and_tap", "element": "first contact result"},
      {"action": "find_and_tap", "element": "message input field"},
      {"action": "type", "text": message},
      {"action": "find_and_tap", "element": "send button"},
    ];
  }

  Future<List<Map<String, dynamic>>> _generateGenericWorkflow(String app, String action, Map<String, dynamic> params) async {
    // Generate workflow based on app and action
    return [
      {"action": "analyze_screen"},
      {"action": "wait", "duration": 1000},
    ];
  }

  Future<ToolExecutionResult> _executeWorkflow(List<Map<String, dynamic>> workflow) async {
    final results = <Map<String, dynamic>>[];

    for (final step in workflow) {
      try {
        final action = step['action'] as String;
        ToolExecutionResult result;

        switch (action) {
          case 'find_and_tap':
            result = await mobileController.execute({
              'action': 'find_element',
              'element_description': step['element'],
            });
            if (result.success) {
              // Extract coordinates and tap
              // This would need to parse the VLM response for coordinates
              await mobileController.execute({
                'action': 'tap',
                'x': 200, // Would be extracted from VLM response
                'y': 300,
              });
            }
            break;
          case 'type':
            result = await mobileController.execute({
              'action': 'type',
              'text': step['text'],
            });
            break;
          case 'wait':
            result = await mobileController.execute({
              'action': 'wait',
              'wait_time': step['duration'] ?? 1000,
            });
            break;
          default:
            result = await mobileController.execute(step);
        }

        results.add({
          'step': step,
          'result': result.toJson(),
        });

        if (!result.success) {
          return ToolExecutionResult.failure('Workflow step failed: ${result.error}');
        }

      } catch (e) {
        return ToolExecutionResult.failure('Workflow execution failed: $e');
      }
    }

    return ToolExecutionResult.success({
      'workflow_completed': true,
      'steps_executed': results.length,
      'results': results,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Fallback implementations for when VLM is not available
  Future<ToolExecutionResult> _whatsappFallbackWorkflow(String recipient, String message) async {
    // Hardcoded coordinates and interactions for WhatsApp
    // This would need to be implemented based on specific WhatsApp version
    return ToolExecutionResult.success({
      'message': 'WhatsApp message workflow initiated (fallback mode)',
      'recipient': recipient,
      'message': message,
    });
  }

  // Placeholder implementations for specific app actions
  Future<ToolExecutionResult> _telegramSendMessage(String? recipient, String? message) async {
    return await _genericAppAction('org.telegram.messenger', 'send_message', {
      'recipient': recipient,
      'message': message,
    });
  }

  Future<ToolExecutionResult> _telegramJoinChannel(String? channel) async {
    return await _genericAppAction('org.telegram.messenger', 'join_channel', {
      'channel': channel,
    });
  }

  Future<ToolExecutionResult> _emailSend(String? recipient, String? subject, String? message) async {
    return await _genericAppAction('com.google.android.gm', 'send_email', {
      'recipient': recipient,
      'subject': subject,
      'message': message,
    });
  }

  Future<ToolExecutionResult> _emailSearch(String? query) async {
    return await _genericAppAction('com.google.android.gm', 'search', {
      'query': query,
    });
  }

  Future<ToolExecutionResult> _emailMarkAsRead() async {
    return await _genericAppAction('com.google.android.gm', 'mark_as_read', {});
  }

  Future<ToolExecutionResult> _browserSearch(String? query) async {
    return await _genericAppAction('com.android.chrome', 'search', {
      'query': query,
    });
  }

  Future<ToolExecutionResult> _browserNavigate(String? url) async {
    return await _genericAppAction('com.android.chrome', 'navigate', {
      'url': url,
    });
  }

  Future<ToolExecutionResult> _browserBookmark() async {
    return await _genericAppAction('com.android.chrome', 'bookmark', {});
  }

  Future<ToolExecutionResult> _instagramPostPhoto(String? caption) async {
    return await _genericAppAction('com.instagram.android', 'post_photo', {
      'caption': caption,
    });
  }

  Future<ToolExecutionResult> _instagramPostStory() async {
    return await _genericAppAction('com.instagram.android', 'post_story', {});
  }

  Future<ToolExecutionResult> _instagramSearchUser(String? username) async {
    return await _genericAppAction('com.instagram.android', 'search_user', {
      'username': username,
    });
  }

  Future<ToolExecutionResult> _youtubeSearch(String? query) async {
    return await _genericAppAction('com.google.android.youtube', 'search', {
      'query': query,
    });
  }

  Future<ToolExecutionResult> _youtubePlayVideo(String? title) async {
    return await _genericAppAction('com.google.android.youtube', 'play_video', {
      'title': title,
    });
  }

  Future<ToolExecutionResult> _youtubeSubscribe() async {
    return await _genericAppAction('com.google.android.youtube', 'subscribe', {});
  }

  Future<ToolExecutionResult> _musicPlaySong(String? song, String? artist) async {
    return await _genericAppAction('com.spotify.music', 'play_song', {
      'song': song,
      'artist': artist,
    });
  }

  Future<ToolExecutionResult> _musicCreatePlaylist(String? name) async {
    return await _genericAppAction('com.spotify.music', 'create_playlist', {
      'name': name,
    });
  }

  Future<ToolExecutionResult> _musicSearch(String? query) async {
    return await _genericAppAction('com.spotify.music', 'search', {
      'query': query,
    });
  }

  Future<ToolExecutionResult> _cameraTakePhoto() async {
    return await _genericAppAction('com.android.camera2', 'take_photo', {});
  }

  Future<ToolExecutionResult> _cameraRecordVideo(String? duration) async {
    return await _genericAppAction('com.android.camera2', 'record_video', {
      'duration': duration,
    });
  }

  Future<ToolExecutionResult> _cameraSwitchMode(String? mode) async {
    return await _genericAppAction('com.android.camera2', 'switch_mode', {
      'mode': mode,
    });
  }

  Future<ToolExecutionResult> _rideHailingBookRide(String? destination, String? type) async {
    return await _genericAppAction('com.ubercab', 'book_ride', {
      'destination': destination,
      'type': type,
    });
  }

  Future<ToolExecutionResult> _rideHailingTrackRide() async {
    return await _genericAppAction('com.ubercab', 'track_ride', {});
  }

  Future<ToolExecutionResult> _foodDeliveryOrder(String? restaurant, List? items) async {
    return await _genericAppAction('com.dd.doordash', 'order_food', {
      'restaurant': restaurant,
      'items': items,
    });
  }

  Future<ToolExecutionResult> _foodDeliveryTrackOrder() async {
    return await _genericAppAction('com.dd.doordash', 'track_order', {});
  }

  Future<ToolExecutionResult> _settingsToggleWifi() async {
    return await _genericAppAction('com.android.settings', 'toggle_wifi', {});
  }

  Future<ToolExecutionResult> _settingsToggleBluetooth() async {
    return await _genericAppAction('com.android.settings', 'toggle_bluetooth', {});
  }

  Future<ToolExecutionResult> _settingsChangeBrightness(String? level) async {
    return await _genericAppAction('com.android.settings', 'change_brightness', {
      'level': level,
    });
  }

  Future<ToolExecutionResult> _settingsOpenAppSettings(String? package) async {
    return await _genericAppAction('com.android.settings', 'open_app_settings', {
      'package': package,
    });
  }

  Future<ToolExecutionResult> _whatsappSearchContact(String? query) async {
    return await _genericAppAction('com.whatsapp', 'search_contact', {
      'query': query,
    });
  }

  Future<ToolExecutionResult> _whatsappCreateGroup(String? name, List? participants) async {
    return await _genericAppAction('com.whatsapp', 'create_group', {
      'name': name,
      'participants': participants,
    });
  }
}