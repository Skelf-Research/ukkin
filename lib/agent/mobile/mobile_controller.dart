import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../tools/tool.dart';
import '../models/task.dart';
import '../llm/llm_interface.dart';

class MobileController extends Tool with ToolValidation {
  static const MethodChannel _platform = MethodChannel('ukkin.mobile/controller');
  final VLMInterface? vlm;

  MobileController({this.vlm});

  @override
  String get name => 'mobile_controller';

  @override
  String get description => 'Control mobile device: tap, swipe, type, open apps, take screenshots, analyze UI';

  @override
  Map<String, String> get parameters => {
        'action': 'Action: tap, swipe, type, scroll, back, home, recent_apps, open_app, close_app, screenshot, analyze_screen, find_element',
        'x': 'X coordinate for tap/swipe actions',
        'y': 'Y coordinate for tap/swipe actions',
        'text': 'Text to type',
        'app_package': 'Package name of app to open/close',
        'app_name': 'Human readable app name',
        'direction': 'Swipe direction: up, down, left, right',
        'distance': 'Swipe distance in pixels',
        'element_description': 'Description of UI element to find',
        'wait_time': 'Time to wait in milliseconds',
      };

  @override
  bool canHandle(Task task) {
    return task.type == 'mobile_control' || task.type.startsWith('mobile_');
  }

  @override
  Future<bool> validate(Map<String, dynamic> parameters) async {
    if (!validateRequired(parameters, ['action'])) return false;

    final action = parameters['action'] as String;
    switch (action) {
      case 'tap':
        return validateRequired(parameters, ['x', 'y']);
      case 'swipe':
        return validateRequired(parameters, ['x', 'y', 'direction']);
      case 'type':
        return validateRequired(parameters, ['text']);
      case 'open_app':
      case 'close_app':
        return parameters.containsKey('app_package') || parameters.containsKey('app_name');
      case 'find_element':
        return validateRequired(parameters, ['element_description']);
      default:
        return true;
    }
  }

  @override
  Future<dynamic> execute(Map<String, dynamic> parameters) async {
    if (!await validate(parameters)) {
      throw Exception('Invalid parameters for mobile controller');
    }

    final action = parameters['action'] as String;

    try {
      switch (action) {
        case 'tap':
          return await _tap(parameters['x'], parameters['y']);
        case 'swipe':
          return await _swipe(
            parameters['x'],
            parameters['y'],
            parameters['direction'],
            parameters['distance'],
          );
        case 'type':
          return await _type(parameters['text']);
        case 'scroll':
          return await _scroll(parameters['direction'] ?? 'down');
        case 'back':
          return await _pressBack();
        case 'home':
          return await _pressHome();
        case 'recent_apps':
          return await _openRecentApps();
        case 'open_app':
          return await _openApp(
            parameters['app_package'],
            parameters['app_name'],
          );
        case 'close_app':
          return await _closeApp(parameters['app_package']);
        case 'screenshot':
          return await _takeScreenshot();
        case 'analyze_screen':
          return await _analyzeCurrentScreen();
        case 'find_element':
          return await _findElement(parameters['element_description']);
        case 'wait':
          return await _wait(parameters['wait_time'] ?? 1000);
        default:
          throw Exception('Unknown mobile action: $action');
      }
    } catch (e) {
      return ToolExecutionResult.failure('Mobile action failed: $e');
    }
  }

  Future<ToolExecutionResult> _tap(dynamic x, dynamic y) async {
    try {
      final result = await _platform.invokeMethod('tap', {
        'x': x is String ? double.parse(x) : x.toDouble(),
        'y': y is String ? double.parse(y) : y.toDouble(),
      });

      return ToolExecutionResult.success({
        'action': 'tap',
        'x': x,
        'y': y,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Tap failed: $e');
    }
  }

  Future<ToolExecutionResult> _swipe(dynamic x, dynamic y, String direction, dynamic distance) async {
    try {
      final result = await _platform.invokeMethod('swipe', {
        'startX': x is String ? double.parse(x) : x.toDouble(),
        'startY': y is String ? double.parse(y) : y.toDouble(),
        'direction': direction,
        'distance': distance is String ? double.parse(distance) : distance?.toDouble() ?? 200.0,
      });

      return ToolExecutionResult.success({
        'action': 'swipe',
        'x': x,
        'y': y,
        'direction': direction,
        'distance': distance,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Swipe failed: $e');
    }
  }

  Future<ToolExecutionResult> _type(String text) async {
    try {
      final result = await _platform.invokeMethod('type', {
        'text': text,
      });

      return ToolExecutionResult.success({
        'action': 'type',
        'text': text,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Type failed: $e');
    }
  }

  Future<ToolExecutionResult> _scroll(String direction) async {
    try {
      final result = await _platform.invokeMethod('scroll', {
        'direction': direction,
      });

      return ToolExecutionResult.success({
        'action': 'scroll',
        'direction': direction,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Scroll failed: $e');
    }
  }

  Future<ToolExecutionResult> _pressBack() async {
    try {
      final result = await _platform.invokeMethod('pressBack');

      return ToolExecutionResult.success({
        'action': 'back',
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Back button failed: $e');
    }
  }

  Future<ToolExecutionResult> _pressHome() async {
    try {
      final result = await _platform.invokeMethod('pressHome');

      return ToolExecutionResult.success({
        'action': 'home',
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Home button failed: $e');
    }
  }

  Future<ToolExecutionResult> _openRecentApps() async {
    try {
      final result = await _platform.invokeMethod('openRecentApps');

      return ToolExecutionResult.success({
        'action': 'recent_apps',
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Recent apps failed: $e');
    }
  }

  Future<ToolExecutionResult> _openApp(String? packageName, String? appName) async {
    try {
      final result = await _platform.invokeMethod('openApp', {
        'packageName': packageName,
        'appName': appName,
      });

      return ToolExecutionResult.success({
        'action': 'open_app',
        'package_name': packageName,
        'app_name': appName,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Open app failed: $e');
    }
  }

  Future<ToolExecutionResult> _closeApp(String? packageName) async {
    try {
      final result = await _platform.invokeMethod('closeApp', {
        'packageName': packageName,
      });

      return ToolExecutionResult.success({
        'action': 'close_app',
        'package_name': packageName,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Close app failed: $e');
    }
  }

  Future<ToolExecutionResult> _takeScreenshot() async {
    try {
      final result = await _platform.invokeMethod('takeScreenshot');
      final screenshotPath = result['path'] as String?;

      if (screenshotPath != null) {
        return ToolExecutionResult.success({
          'action': 'screenshot',
          'screenshot_path': screenshotPath,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        return ToolExecutionResult.failure('Screenshot path is null');
      }
    } catch (e) {
      return ToolExecutionResult.failure('Screenshot failed: $e');
    }
  }

  Future<ToolExecutionResult> _analyzeCurrentScreen() async {
    try {
      // First take a screenshot
      final screenshotResult = await _takeScreenshot();
      if (!screenshotResult.success) {
        return screenshotResult;
      }

      final screenshotPath = screenshotResult.data['screenshot_path'] as String;

      // Analyze the screenshot with VLM
      if (vlm != null) {
        final analysis = await vlm!.analyzeScreenshot(screenshotPath);

        return ToolExecutionResult.success({
          'action': 'analyze_screen',
          'screenshot_path': screenshotPath,
          'analysis': analysis,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        // Fallback: Get basic UI structure via accessibility
        final uiStructure = await _getUIStructure();

        return ToolExecutionResult.success({
          'action': 'analyze_screen',
          'screenshot_path': screenshotPath,
          'ui_structure': uiStructure,
          'analysis_type': 'accessibility_based',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      return ToolExecutionResult.failure('Screen analysis failed: $e');
    }
  }

  Future<ToolExecutionResult> _findElement(String elementDescription) async {
    try {
      // First analyze the current screen
      final screenAnalysis = await _analyzeCurrentScreen();
      if (!screenAnalysis.success) {
        return screenAnalysis;
      }

      if (vlm != null) {
        // Use VLM to find the element
        final screenshotPath = screenAnalysis.data['screenshot_path'] as String;
        final prompt = '''
        Find the UI element described as: "$elementDescription"

        Analyze the screenshot and identify:
        1. Whether the element exists
        2. Its approximate coordinates (x, y)
        3. Its type (button, text field, image, etc.)
        4. Any text content
        5. Whether it appears clickable/interactable

        Respond in JSON format:
        {
          "found": true/false,
          "x": coordinate,
          "y": coordinate,
          "type": "element_type",
          "text": "visible_text",
          "clickable": true/false,
          "confidence": 0.0-1.0
        }
        ''';

        final analysis = await vlm!.analyzeImage(screenshotPath, prompt: prompt);

        return ToolExecutionResult.success({
          'action': 'find_element',
          'element_description': elementDescription,
          'screenshot_path': screenshotPath,
          'analysis': analysis,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        // Fallback: Use accessibility service to find elements
        final result = await _platform.invokeMethod('findElement', {
          'description': elementDescription,
        });

        return ToolExecutionResult.success({
          'action': 'find_element',
          'element_description': elementDescription,
          'result': result,
          'method': 'accessibility_service',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      return ToolExecutionResult.failure('Find element failed: $e');
    }
  }

  Future<ToolExecutionResult> _wait(int milliseconds) async {
    await Future.delayed(Duration(milliseconds: milliseconds));

    return ToolExecutionResult.success({
      'action': 'wait',
      'duration_ms': milliseconds,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> _getUIStructure() async {
    try {
      final result = await _platform.invokeMethod('getUIStructure');
      return result as Map<String, dynamic>;
    } catch (e) {
      return {'error': 'Failed to get UI structure: $e'};
    }
  }

  Future<ToolExecutionResult> getInstalledApps() async {
    try {
      final result = await _platform.invokeMethod('getInstalledApps');
      final apps = result['apps'] as List?;

      return ToolExecutionResult.success({
        'action': 'get_installed_apps',
        'apps': apps ?? [],
        'count': apps?.length ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Get installed apps failed: $e');
    }
  }

  Future<ToolExecutionResult> getCurrentApp() async {
    try {
      final result = await _platform.invokeMethod('getCurrentApp');

      return ToolExecutionResult.success({
        'action': 'get_current_app',
        'package_name': result['packageName'],
        'app_name': result['appName'],
        'activity': result['activity'],
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Get current app failed: $e');
    }
  }

  Future<ToolExecutionResult> performComplexGesture(List<Map<String, dynamic>> gestures) async {
    try {
      final result = await _platform.invokeMethod('performComplexGesture', {
        'gestures': gestures,
      });

      return ToolExecutionResult.success({
        'action': 'complex_gesture',
        'gestures': gestures,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Complex gesture failed: $e');
    }
  }

  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final result = await _platform.invokeMethod('isAccessibilityServiceEnabled');
      return result['enabled'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> requestAccessibilityPermission() async {
    try {
      await _platform.invokeMethod('requestAccessibilityPermission');
    } catch (e) {
      throw Exception('Failed to request accessibility permission: $e');
    }
  }
}