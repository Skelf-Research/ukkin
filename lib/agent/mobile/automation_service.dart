import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

/// Platform capabilities for automation
class AutomationCapabilities {
  final String platform;
  final bool canReadScreen;
  final bool canPerformTaps;
  final bool canTypeText;
  final bool canLaunchApps;
  final bool canUseShortcuts;
  final bool canShareContent;
  final bool canOpenURLs;
  final List<String> limitations;
  final List<String> supportedFeatures;

  const AutomationCapabilities({
    required this.platform,
    required this.canReadScreen,
    required this.canPerformTaps,
    required this.canTypeText,
    required this.canLaunchApps,
    required this.canUseShortcuts,
    required this.canShareContent,
    required this.canOpenURLs,
    this.limitations = const [],
    this.supportedFeatures = const [],
  });

  /// Full automation capabilities (Android with accessibility service)
  factory AutomationCapabilities.full() {
    return const AutomationCapabilities(
      platform: 'Android',
      canReadScreen: true,
      canPerformTaps: true,
      canTypeText: true,
      canLaunchApps: true,
      canUseShortcuts: false,
      canShareContent: true,
      canOpenURLs: true,
      supportedFeatures: [
        'Full screen content reading',
        'UI element interaction',
        'Text input automation',
        'App launching',
        'Gesture automation',
      ],
    );
  }

  /// Limited capabilities (iOS - sandboxed)
  factory AutomationCapabilities.limited() {
    return const AutomationCapabilities(
      platform: 'iOS',
      canReadScreen: false,
      canPerformTaps: false,
      canTypeText: false,
      canLaunchApps: true,
      canUseShortcuts: true,
      canShareContent: true,
      canOpenURLs: true,
      limitations: [
        'iOS sandboxing prevents reading other apps content',
        'Cannot perform gestures in other apps',
        'App launching limited to registered URL schemes',
      ],
      supportedFeatures: [
        'launchApp - Open apps via URL schemes',
        'triggerShortcut - Run Siri Shortcuts',
        'shareContent - Share via system share sheet',
        'openURL - Open URLs in Safari or appropriate app',
      ],
    );
  }

  factory AutomationCapabilities.fromJson(Map<String, dynamic> json) {
    return AutomationCapabilities(
      platform: json['platform'] ?? 'unknown',
      canReadScreen: json['canReadScreen'] ?? false,
      canPerformTaps: json['canPerformTaps'] ?? false,
      canTypeText: json['canTypeText'] ?? false,
      canLaunchApps: json['canLaunchApps'] ?? false,
      canUseShortcuts: json['canUseShortcuts'] ?? false,
      canShareContent: json['canShareContent'] ?? false,
      canOpenURLs: json['canOpenURLs'] ?? false,
      limitations: List<String>.from(json['limitations'] ?? []),
      supportedFeatures: List<String>.from(json['supportedFeatures'] ?? []),
    );
  }

  bool get hasFullAutomation => canReadScreen && canPerformTaps && canTypeText;
}

/// High-level automation service for screen interaction
/// Uses Android Accessibility Service for real app automation
/// Provides graceful degradation on iOS with limited capabilities
class AutomationService {
  static const MethodChannel _channel = MethodChannel('com.ukkin/automation');
  static final AutomationService _instance = AutomationService._internal();

  AutomationCapabilities? _capabilities;

  factory AutomationService() => _instance;
  AutomationService._internal();

  /// Check if running on iOS
  bool get isIOS => Platform.isIOS;

  /// Check if running on Android
  bool get isAndroid => Platform.isAndroid;

  /// Get platform capabilities
  Future<AutomationCapabilities> getCapabilities() async {
    if (_capabilities != null) return _capabilities!;

    if (isIOS) {
      try {
        final result = await _channel.invokeMethod('getCapabilities');
        _capabilities = AutomationCapabilities.fromJson(Map<String, dynamic>.from(result));
      } catch (e) {
        _capabilities = AutomationCapabilities.limited();
      }
    } else {
      // Android with accessibility service
      final enabled = await isEnabled();
      if (enabled) {
        _capabilities = AutomationCapabilities.full();
      } else {
        _capabilities = AutomationCapabilities(
          platform: 'Android',
          canReadScreen: false,
          canPerformTaps: false,
          canTypeText: false,
          canLaunchApps: true,
          canUseShortcuts: false,
          canShareContent: true,
          canOpenURLs: true,
          limitations: ['Accessibility service not enabled'],
          supportedFeatures: ['Enable accessibility service for full automation'],
        );
      }
    }
    return _capabilities!;
  }

  /// Check if accessibility service is enabled
  Future<bool> isEnabled() async {
    try {
      return await _channel.invokeMethod('isAccessibilityEnabled') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Open system accessibility settings
  Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  /// Get all screen content as structured data
  Future<ScreenContent> getScreenContent() async {
    final result = await _channel.invokeMethod('getScreenContent');
    final json = jsonDecode(result as String);
    return ScreenContent.fromJson(json);
  }

  /// Find element by text
  Future<ScreenElement?> findByText(String text, {bool exact = false}) async {
    final result = await _channel.invokeMethod('findElementByText', {
      'text': text,
      'exact': exact,
    });

    if (result['found'] == true) {
      return ScreenElement(
        text: result['text'] ?? '',
        bounds: Bounds.fromMap(result['bounds']),
      );
    }
    return null;
  }

  /// Click on element containing text
  Future<bool> clickOnText(String text) async {
    return await _channel.invokeMethod('clickOnText', {'text': text}) ?? false;
  }

  /// Click at specific coordinates
  Future<bool> clickAt(double x, double y) async {
    return await _channel.invokeMethod('clickAt', {'x': x, 'y': y}) ?? false;
  }

  /// Type text into focused input field
  Future<bool> typeText(String text) async {
    return await _channel.invokeMethod('typeText', {'text': text}) ?? false;
  }

  /// Scroll in direction (up, down)
  Future<bool> scroll(String direction) async {
    return await _channel.invokeMethod('scroll', {'direction': direction}) ?? false;
  }

  /// Swipe gesture
  Future<bool> swipe(double startX, double startY, double endX, double endY, {int duration = 300}) async {
    return await _channel.invokeMethod('swipe', {
      'startX': startX,
      'startY': startY,
      'endX': endX,
      'endY': endY,
      'duration': duration,
    }) ?? false;
  }

  /// Press back button
  Future<bool> pressBack() async {
    return await _channel.invokeMethod('pressBack') ?? false;
  }

  /// Press home button
  Future<bool> pressHome() async {
    return await _channel.invokeMethod('pressHome') ?? false;
  }

  /// Get current foreground package
  Future<String> getCurrentPackage() async {
    return await _channel.invokeMethod('getCurrentPackage') ?? '';
  }

  /// Extract all text from screen
  Future<List<String>> extractAllText() async {
    final result = await _channel.invokeMethod('extractAllText');
    return List<String>.from(result ?? []);
  }

  /// Wait for element to appear
  Future<bool> waitForElement(String text, {int timeoutMs = 5000}) async {
    return await _channel.invokeMethod('waitForElement', {
      'text': text,
      'timeout': timeoutMs,
    }) ?? false;
  }

  /// Launch app by package name
  Future<bool> launchApp(String packageName) async {
    return await _channel.invokeMethod('launchApp', {'packageName': packageName}) ?? false;
  }

  // High-level automation helpers

  /// Open app and wait for it to load
  Future<bool> openAppAndWait(String packageName, {String? waitForText, int timeoutMs = 5000}) async {
    final launched = await launchApp(packageName);
    if (!launched) return false;

    await Future.delayed(Duration(milliseconds: 1000)); // Wait for app to start

    if (waitForText != null) {
      return await waitForElement(waitForText, timeoutMs: timeoutMs);
    }

    return true;
  }

  /// Find and click element, with retry
  Future<bool> findAndClick(String text, {int maxRetries = 3, int delayMs = 500}) async {
    for (int i = 0; i < maxRetries; i++) {
      if (await clickOnText(text)) {
        return true;
      }
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    return false;
  }

  /// Scroll until text is found
  Future<bool> scrollToFind(String text, {int maxScrolls = 10, String direction = 'down'}) async {
    for (int i = 0; i < maxScrolls; i++) {
      final element = await findByText(text);
      if (element != null) return true;

      await scroll(direction);
      await Future.delayed(Duration(milliseconds: 500));
    }
    return false;
  }

  /// Perform a sequence of actions
  Future<bool> performSequence(List<AutomationAction> actions) async {
    for (final action in actions) {
      bool success = false;

      switch (action.type) {
        case ActionType.click:
          success = await clickOnText(action.target!);
          break;
        case ActionType.type:
          success = await typeText(action.value!);
          break;
        case ActionType.scroll:
          success = await scroll(action.value ?? 'down');
          break;
        case ActionType.wait:
          await Future.delayed(Duration(milliseconds: action.duration ?? 1000));
          success = true;
          break;
        case ActionType.waitFor:
          success = await waitForElement(action.target!, timeoutMs: action.duration ?? 5000);
          break;
        case ActionType.back:
          success = await pressBack();
          break;
        case ActionType.launch:
          success = await launchApp(action.target!);
          break;
      }

      if (!success && action.required) {
        return false;
      }

      if (action.delayAfter != null) {
        await Future.delayed(Duration(milliseconds: action.delayAfter!));
      }
    }
    return true;
  }

  // ============================================
  // iOS-Specific Methods (Graceful Degradation)
  // ============================================

  /// Check if an app can be launched via URL scheme (iOS)
  Future<bool> canLaunchAppByScheme(String urlScheme) async {
    if (!isIOS) return true; // Android can launch by package name
    try {
      return await _channel.invokeMethod('canLaunchApp', {'urlScheme': urlScheme}) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Launch app by URL scheme (works on both platforms, required for iOS)
  Future<bool> launchAppByScheme(String urlScheme) async {
    try {
      return await _channel.invokeMethod('launchApp', {'urlScheme': urlScheme}) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Trigger a Siri Shortcut by name (iOS only)
  Future<bool> triggerShortcut(String shortcutName) async {
    if (!isIOS) {
      // Android doesn't have Siri Shortcuts
      return false;
    }
    try {
      return await _channel.invokeMethod('triggerShortcut', {'name': shortcutName}) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Share content via system share sheet
  Future<bool> shareContent({String? text, String? url}) async {
    try {
      return await _channel.invokeMethod('shareContent', {
        'text': text,
        'url': url,
      }) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Open a URL in the default browser or appropriate app
  Future<bool> openURL(String url) async {
    try {
      return await _channel.invokeMethod('openURL', {'url': url}) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Execute an action with platform-aware fallback
  /// Returns true if action succeeded, false if not supported or failed
  Future<AutomationResult> executeWithFallback({
    required String action,
    String? target,
    String? value,
    String? urlScheme,
    String? shortcutName,
  }) async {
    final caps = await getCapabilities();

    switch (action) {
      case 'click':
        if (caps.canPerformTaps) {
          final success = await clickOnText(target!);
          return AutomationResult(success: success, method: 'accessibility');
        } else if (caps.canUseShortcuts && shortcutName != null) {
          final success = await triggerShortcut(shortcutName);
          return AutomationResult(success: success, method: 'shortcut');
        }
        return AutomationResult(
          success: false,
          method: 'none',
          error: 'Tap automation not available on this platform',
        );

      case 'launch':
        if (caps.canLaunchApps) {
          if (isIOS && urlScheme != null) {
            final success = await launchAppByScheme(urlScheme);
            return AutomationResult(success: success, method: 'url_scheme');
          } else if (isAndroid && target != null) {
            final success = await launchApp(target);
            return AutomationResult(success: success, method: 'package_name');
          }
        }
        return AutomationResult(
          success: false,
          method: 'none',
          error: 'App launching not available',
        );

      case 'type':
        if (caps.canTypeText) {
          final success = await typeText(value!);
          return AutomationResult(success: success, method: 'accessibility');
        }
        return AutomationResult(
          success: false,
          method: 'none',
          error: 'Text input not available on this platform',
        );

      case 'share':
        if (caps.canShareContent) {
          final success = await shareContent(text: value, url: target);
          return AutomationResult(success: success, method: 'share_sheet');
        }
        return AutomationResult(
          success: false,
          method: 'none',
          error: 'Sharing not available',
        );

      default:
        return AutomationResult(
          success: false,
          method: 'none',
          error: 'Unknown action: $action',
        );
    }
  }
}

/// Result of an automation action with fallback info
class AutomationResult {
  final bool success;
  final String method;
  final String? error;

  const AutomationResult({
    required this.success,
    required this.method,
    this.error,
  });
}

// Common URL schemes for iOS app launching
class IOSAppSchemes {
  static const Map<String, String> schemes = {
    'com.apple.safari': 'https',
    'com.apple.mobilemail': 'mailto',
    'com.apple.mobilesms': 'sms',
    'com.apple.facetime': 'facetime',
    'com.apple.Maps': 'maps',
    'com.apple.Music': 'music',
    'com.google.chrome.ios': 'googlechrome',
    'com.google.Gmail': 'googlegmail',
    'com.google.Maps': 'comgooglemaps',
    'com.google.youtube': 'youtube',
    'com.burbn.instagram': 'instagram',
    'com.twitter.twitter': 'twitter',
    'net.whatsapp.WhatsApp': 'whatsapp',
    'com.spotify.client': 'spotify',
  };

  /// Get URL scheme for a package/bundle ID
  static String? getScheme(String bundleId) => schemes[bundleId];

  /// Get URL scheme with fallback to Android package name
  static String getSchemeOrPackage(String packageName) {
    return schemes[packageName] ?? packageName;
  }
}

// Data models

class ScreenContent {
  final String packageName;
  final List<ScreenElement> elements;
  final int timestamp;

  ScreenContent({
    required this.packageName,
    required this.elements,
    required this.timestamp,
  });

  factory ScreenContent.fromJson(Map<String, dynamic> json) {
    final elementsJson = json['elements'] as List? ?? [];
    return ScreenContent(
      packageName: json['package'] ?? '',
      elements: elementsJson.map((e) => ScreenElement.fromJson(e)).toList(),
      timestamp: json['timestamp'] ?? 0,
    );
  }

  /// Find elements containing text
  List<ScreenElement> findByText(String text, {bool ignoreCase = true}) {
    return elements.where((e) {
      final elementText = ignoreCase ? e.text.toLowerCase() : e.text;
      final searchText = ignoreCase ? text.toLowerCase() : text;
      return elementText.contains(searchText) ||
             (e.contentDescription?.toLowerCase().contains(searchText) ?? false);
    }).toList();
  }

  /// Get all clickable elements
  List<ScreenElement> get clickableElements => elements.where((e) => e.clickable).toList();

  /// Get all text on screen
  List<String> get allText => elements
      .where((e) => e.text.isNotEmpty)
      .map((e) => e.text)
      .toList();
}

class ScreenElement {
  final String text;
  final String? contentDescription;
  final String? viewId;
  final String? className;
  final Bounds bounds;
  final bool clickable;
  final bool editable;
  final bool scrollable;

  ScreenElement({
    required this.text,
    this.contentDescription,
    this.viewId,
    this.className,
    required this.bounds,
    this.clickable = false,
    this.editable = false,
    this.scrollable = false,
  });

  factory ScreenElement.fromJson(Map<String, dynamic> json) {
    return ScreenElement(
      text: json['text'] ?? '',
      contentDescription: json['contentDescription'],
      viewId: json['viewId'],
      className: json['class'],
      bounds: Bounds.fromMap(json['bounds'] ?? {}),
      clickable: json['clickable'] ?? false,
      editable: json['editable'] ?? false,
      scrollable: json['scrollable'] ?? false,
    );
  }
}

class Bounds {
  final int left;
  final int top;
  final int right;
  final int bottom;
  final int centerX;
  final int centerY;

  Bounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.centerX,
    required this.centerY,
  });

  factory Bounds.fromMap(Map<String, dynamic> map) {
    return Bounds(
      left: map['left'] ?? 0,
      top: map['top'] ?? 0,
      right: map['right'] ?? 0,
      bottom: map['bottom'] ?? 0,
      centerX: map['centerX'] ?? 0,
      centerY: map['centerY'] ?? 0,
    );
  }

  int get width => right - left;
  int get height => bottom - top;
}

// Action types for automation sequences

enum ActionType {
  click,
  type,
  scroll,
  wait,
  waitFor,
  back,
  launch,
}

class AutomationAction {
  final ActionType type;
  final String? target;
  final String? value;
  final int? duration;
  final int? delayAfter;
  final bool required;

  AutomationAction({
    required this.type,
    this.target,
    this.value,
    this.duration,
    this.delayAfter,
    this.required = true,
  });

  // Convenience constructors
  factory AutomationAction.click(String text, {int? delayAfter}) =>
      AutomationAction(type: ActionType.click, target: text, delayAfter: delayAfter);

  factory AutomationAction.type(String text, {int? delayAfter}) =>
      AutomationAction(type: ActionType.type, value: text, delayAfter: delayAfter);

  factory AutomationAction.scroll({String direction = 'down', int? delayAfter}) =>
      AutomationAction(type: ActionType.scroll, value: direction, delayAfter: delayAfter);

  factory AutomationAction.wait(int ms) =>
      AutomationAction(type: ActionType.wait, duration: ms);

  factory AutomationAction.waitFor(String text, {int timeoutMs = 5000}) =>
      AutomationAction(type: ActionType.waitFor, target: text, duration: timeoutMs);

  factory AutomationAction.back({int? delayAfter}) =>
      AutomationAction(type: ActionType.back, delayAfter: delayAfter);

  factory AutomationAction.launch(String packageName, {int? delayAfter}) =>
      AutomationAction(type: ActionType.launch, target: packageName, delayAfter: delayAfter);
}
