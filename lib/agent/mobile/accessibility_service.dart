import 'package:flutter/services.dart';
import '../tools/tool.dart';
import '../models/task.dart';

class AccessibilityService extends Tool with ToolValidation {
  static const MethodChannel _platform = MethodChannel('ukkin.accessibility/service');

  @override
  String get name => 'accessibility_service';

  @override
  String get description => 'Access and control device using accessibility services for UI automation';

  @override
  Map<String, String> get parameters => {
        'action': 'Action: get_nodes, find_by_text, find_by_id, perform_action, get_window_info',
        'text': 'Text to search for',
        'resource_id': 'Resource ID to find',
        'class_name': 'Class name to filter by',
        'node_action': 'Action to perform on node: click, long_click, scroll, focus, set_text',
        'scroll_direction': 'Scroll direction: up, down, left, right',
        'input_text': 'Text to input',
      };

  @override
  bool canHandle(Task task) {
    return task.type == 'accessibility' || task.type.startsWith('a11y_');
  }

  @override
  Future<bool> validate(Map<String, dynamic> parameters) async {
    return validateRequired(parameters, ['action']);
  }

  @override
  Future<dynamic> execute(Map<String, dynamic> parameters) async {
    if (!await validate(parameters)) {
      throw Exception('Invalid parameters for accessibility service');
    }

    final action = parameters['action'] as String;

    try {
      switch (action) {
        case 'get_nodes':
          return await _getAllNodes();
        case 'find_by_text':
          return await _findNodesByText(parameters['text']);
        case 'find_by_id':
          return await _findNodesByResourceId(parameters['resource_id']);
        case 'find_by_class':
          return await _findNodesByClass(parameters['class_name']);
        case 'perform_action':
          return await _performNodeAction(
            parameters['node_id'],
            parameters['node_action'],
            parameters,
          );
        case 'get_window_info':
          return await _getWindowInfo();
        case 'get_current_app':
          return await _getCurrentAppInfo();
        case 'global_action':
          return await _performGlobalAction(parameters['global_action']);
        default:
          throw Exception('Unknown accessibility action: $action');
      }
    } catch (e) {
      return ToolExecutionResult.failure('Accessibility action failed: $e');
    }
  }

  Future<ToolExecutionResult> _getAllNodes() async {
    try {
      final result = await _platform.invokeMethod('getAllNodes');
      final nodes = result['nodes'] as List?;

      return ToolExecutionResult.success({
        'action': 'get_nodes',
        'nodes': nodes ?? [],
        'count': nodes?.length ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Get nodes failed: $e');
    }
  }

  Future<ToolExecutionResult> _findNodesByText(String? text) async {
    if (text == null) {
      return ToolExecutionResult.failure('Text parameter is required');
    }

    try {
      final result = await _platform.invokeMethod('findNodesByText', {
        'text': text,
      });

      final nodes = result['nodes'] as List?;

      return ToolExecutionResult.success({
        'action': 'find_by_text',
        'search_text': text,
        'nodes': nodes ?? [],
        'count': nodes?.length ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Find by text failed: $e');
    }
  }

  Future<ToolExecutionResult> _findNodesByResourceId(String? resourceId) async {
    if (resourceId == null) {
      return ToolExecutionResult.failure('Resource ID parameter is required');
    }

    try {
      final result = await _platform.invokeMethod('findNodesByResourceId', {
        'resourceId': resourceId,
      });

      final nodes = result['nodes'] as List?;

      return ToolExecutionResult.success({
        'action': 'find_by_id',
        'resource_id': resourceId,
        'nodes': nodes ?? [],
        'count': nodes?.length ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Find by resource ID failed: $e');
    }
  }

  Future<ToolExecutionResult> _findNodesByClass(String? className) async {
    if (className == null) {
      return ToolExecutionResult.failure('Class name parameter is required');
    }

    try {
      final result = await _platform.invokeMethod('findNodesByClass', {
        'className': className,
      });

      final nodes = result['nodes'] as List?;

      return ToolExecutionResult.success({
        'action': 'find_by_class',
        'class_name': className,
        'nodes': nodes ?? [],
        'count': nodes?.length ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Find by class failed: $e');
    }
  }

  Future<ToolExecutionResult> _performNodeAction(
    String? nodeId,
    String? action,
    Map<String, dynamic> parameters,
  ) async {
    if (nodeId == null || action == null) {
      return ToolExecutionResult.failure('Node ID and action are required');
    }

    try {
      final result = await _platform.invokeMethod('performNodeAction', {
        'nodeId': nodeId,
        'action': action,
        'parameters': parameters,
      });

      return ToolExecutionResult.success({
        'action': 'perform_action',
        'node_id': nodeId,
        'node_action': action,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Perform node action failed: $e');
    }
  }

  Future<ToolExecutionResult> _getWindowInfo() async {
    try {
      final result = await _platform.invokeMethod('getWindowInfo');

      return ToolExecutionResult.success({
        'action': 'get_window_info',
        'window_info': result,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Get window info failed: $e');
    }
  }

  Future<ToolExecutionResult> _getCurrentAppInfo() async {
    try {
      final result = await _platform.invokeMethod('getCurrentAppInfo');

      return ToolExecutionResult.success({
        'action': 'get_current_app',
        'package_name': result['packageName'],
        'app_name': result['appName'],
        'activity': result['activity'],
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Get current app info failed: $e');
    }
  }

  Future<ToolExecutionResult> _performGlobalAction(String? globalAction) async {
    if (globalAction == null) {
      return ToolExecutionResult.failure('Global action is required');
    }

    try {
      final result = await _platform.invokeMethod('performGlobalAction', {
        'action': globalAction,
      });

      return ToolExecutionResult.success({
        'action': 'global_action',
        'global_action': globalAction,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Global action failed: $e');
    }
  }

  Future<ToolExecutionResult> findClickableElements() async {
    try {
      final result = await _platform.invokeMethod('findClickableElements');
      final elements = result['elements'] as List?;

      return ToolExecutionResult.success({
        'action': 'find_clickable_elements',
        'elements': elements ?? [],
        'count': elements?.length ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Find clickable elements failed: $e');
    }
  }

  Future<ToolExecutionResult> findEditableElements() async {
    try {
      final result = await _platform.invokeMethod('findEditableElements');
      final elements = result['elements'] as List?;

      return ToolExecutionResult.success({
        'action': 'find_editable_elements',
        'elements': elements ?? [],
        'count': elements?.length ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Find editable elements failed: $e');
    }
  }

  Future<ToolExecutionResult> getElementHierarchy() async {
    try {
      final result = await _platform.invokeMethod('getElementHierarchy');

      return ToolExecutionResult.success({
        'action': 'get_element_hierarchy',
        'hierarchy': result['hierarchy'],
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Get element hierarchy failed: $e');
    }
  }

  Future<ToolExecutionResult> findElementByPosition(double x, double y) async {
    try {
      final result = await _platform.invokeMethod('findElementByPosition', {
        'x': x,
        'y': y,
      });

      return ToolExecutionResult.success({
        'action': 'find_element_by_position',
        'x': x,
        'y': y,
        'element': result['element'],
        'found': result['found'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Find element by position failed: $e');
    }
  }

  Future<ToolExecutionResult> scrollToElement(String nodeId) async {
    try {
      final result = await _platform.invokeMethod('scrollToElement', {
        'nodeId': nodeId,
      });

      return ToolExecutionResult.success({
        'action': 'scroll_to_element',
        'node_id': nodeId,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Scroll to element failed: $e');
    }
  }

  Future<ToolExecutionResult> getElementText(String nodeId) async {
    try {
      final result = await _platform.invokeMethod('getElementText', {
        'nodeId': nodeId,
      });

      return ToolExecutionResult.success({
        'action': 'get_element_text',
        'node_id': nodeId,
        'text': result['text'],
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Get element text failed: $e');
    }
  }

  Future<ToolExecutionResult> setElementText(String nodeId, String text) async {
    try {
      final result = await _platform.invokeMethod('setElementText', {
        'nodeId': nodeId,
        'text': text,
      });

      return ToolExecutionResult.success({
        'action': 'set_element_text',
        'node_id': nodeId,
        'text': text,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Set element text failed: $e');
    }
  }

  Future<bool> isServiceEnabled() async {
    try {
      final result = await _platform.invokeMethod('isServiceEnabled');
      return result['enabled'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> requestServicePermission() async {
    try {
      await _platform.invokeMethod('requestServicePermission');
    } catch (e) {
      throw Exception('Failed to request accessibility service permission: $e');
    }
  }

  Future<Map<String, dynamic>> getServiceStatus() async {
    try {
      final result = await _platform.invokeMethod('getServiceStatus');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {
        'enabled': false,
        'error': e.toString(),
      };
    }
  }

  // Helper methods for common UI patterns
  Future<ToolExecutionResult> findAndClickButton(String buttonText) async {
    try {
      // Find button by text
      final findResult = await _findNodesByText(buttonText);
      if (!findResult.success) {
        return findResult;
      }

      final nodes = findResult.data['nodes'] as List;
      if (nodes.isEmpty) {
        return ToolExecutionResult.failure('Button with text "$buttonText" not found');
      }

      // Click the first matching button
      final firstNode = nodes.first;
      final nodeId = firstNode['id'] as String;

      return await _performNodeAction(nodeId, 'click', {});
    } catch (e) {
      return ToolExecutionResult.failure('Find and click button failed: $e');
    }
  }

  Future<ToolExecutionResult> fillTextField(String fieldText, String inputText) async {
    try {
      // Find text field
      final findResult = await _findNodesByText(fieldText);
      if (!findResult.success) {
        return findResult;
      }

      final nodes = findResult.data['nodes'] as List;
      if (nodes.isEmpty) {
        return ToolExecutionResult.failure('Text field with text "$fieldText" not found');
      }

      // Set text in the first matching field
      final firstNode = nodes.first;
      final nodeId = firstNode['id'] as String;

      return await setElementText(nodeId, inputText);
    } catch (e) {
      return ToolExecutionResult.failure('Fill text field failed: $e');
    }
  }

  Future<ToolExecutionResult> scrollUntilElementVisible(String elementText) async {
    try {
      int maxScrollAttempts = 10;
      int attempts = 0;

      while (attempts < maxScrollAttempts) {
        // Check if element is visible
        final findResult = await _findNodesByText(elementText);
        if (findResult.success) {
          final nodes = findResult.data['nodes'] as List;
          if (nodes.isNotEmpty) {
            return ToolExecutionResult.success({
              'action': 'scroll_until_visible',
              'element_text': elementText,
              'found': true,
              'attempts': attempts,
              'timestamp': DateTime.now().toIso8601String(),
            });
          }
        }

        // Scroll down
        await _performGlobalAction('scroll_down');
        await Future.delayed(Duration(milliseconds: 500));
        attempts++;
      }

      return ToolExecutionResult.failure('Element "$elementText" not found after scrolling');
    } catch (e) {
      return ToolExecutionResult.failure('Scroll until element visible failed: $e');
    }
  }
}