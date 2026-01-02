import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import '../config/config_manager.dart';

/// Intelligent notification service for agent updates
class NotificationService {
  static const MethodChannel _channel = MethodChannel('com.ukkin/notifications');
  static final NotificationService _instance = NotificationService._();

  factory NotificationService() => _instance;
  NotificationService._();

  bool _isInitialized = false;
  final _notificationController = StreamController<AgentNotification>.broadcast();

  Stream<AgentNotification> get notifications => _notificationController.stream;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _channel.invokeMethod('initialize');
      _channel.setMethodCallHandler(_handleMethodCall);
      _isInitialized = true;
    } catch (e) {
      // Notifications may not be available on all platforms
      _isInitialized = false;
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onNotificationTapped':
        final data = Map<String, dynamic>.from(call.arguments);
        _notificationController.add(AgentNotification.fromJson(data));
        break;
      case 'onActionSelected':
        final actionId = call.arguments['actionId'] as String;
        final notificationId = call.arguments['notificationId'] as int;
        return _handleQuickAction(actionId, notificationId);
    }
  }

  /// Show agent progress notification
  Future<void> showAgentProgress({
    required String agentId,
    required String agentName,
    required String status,
    double? progress,
    List<NotificationAction>? actions,
  }) async {
    final config = ConfigManager.instance.config.notifications;
    if (!config.enableNotifications || !config.showAgentProgress) return;
    if (_isInQuietHours(config)) return;

    try {
      await _channel.invokeMethod('showProgress', {
        'id': agentId.hashCode,
        'title': agentName,
        'body': status,
        'progress': progress,
        'ongoing': progress != null && progress < 1.0,
        'actions': actions?.map((a) => a.toJson()).toList(),
      });
    } catch (e) {
      // Silently fail if notifications unavailable
    }
  }

  /// Show task completion notification
  Future<void> showTaskComplete({
    required String agentId,
    required String agentName,
    required String summary,
    String? details,
    bool success = true,
  }) async {
    final config = ConfigManager.instance.config.notifications;
    if (!config.enableNotifications || !config.showTaskCompletion) return;
    if (_isInQuietHours(config)) return;

    try {
      await _channel.invokeMethod('showComplete', {
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': '$agentName ${success ? 'completed' : 'failed'}',
        'body': summary,
        'details': details,
        'success': success,
        'vibrate': config.vibrateOnComplete,
      });
    } catch (e) {
      // Silently fail
    }
  }

  /// Show error notification
  Future<void> showError({
    required String agentId,
    required String agentName,
    required String error,
    List<NotificationAction>? actions,
  }) async {
    final config = ConfigManager.instance.config.notifications;
    if (!config.enableNotifications || !config.showErrors) return;

    try {
      await _channel.invokeMethod('showError', {
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': '$agentName Error',
        'body': error,
        'actions': actions?.map((a) => a.toJson()).toList(),
      });
    } catch (e) {
      // Silently fail
    }
  }

  /// Show quick action notification for immediate user response
  Future<void> showQuickAction({
    required String title,
    required String body,
    required List<NotificationAction> actions,
    int timeoutSeconds = 30,
  }) async {
    final config = ConfigManager.instance.config.notifications;
    if (!config.enableNotifications) return;

    try {
      await _channel.invokeMethod('showQuickAction', {
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': title,
        'body': body,
        'actions': actions.map((a) => a.toJson()).toList(),
        'timeout': timeoutSeconds,
      });
    } catch (e) {
      // Silently fail
    }
  }

  /// Cancel a specific notification
  Future<void> cancel(int notificationId) async {
    try {
      await _channel.invokeMethod('cancel', {'id': notificationId});
    } catch (e) {
      // Silently fail
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    try {
      await _channel.invokeMethod('cancelAll');
    } catch (e) {
      // Silently fail
    }
  }

  /// Check if we're in quiet hours
  bool _isInQuietHours(dynamic config) {
    if (!config.quietHoursEnabled) return false;

    final now = DateTime.now();
    final currentHour = now.hour;
    final start = config.quietHoursStart as int;
    final end = config.quietHoursEnd as int;

    if (start < end) {
      // Same day range (e.g., 9-17)
      return currentHour >= start && currentHour < end;
    } else {
      // Overnight range (e.g., 22-7)
      return currentHour >= start || currentHour < end;
    }
  }

  Future<void> _handleQuickAction(String actionId, int notificationId) async {
    // Handle quick actions from notification
    // This would dispatch to appropriate handlers
  }

  void dispose() {
    _notificationController.close();
  }
}

/// A notification from an agent
class AgentNotification {
  final int id;
  final String agentId;
  final String type;
  final String title;
  final String body;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const AgentNotification({
    required this.id,
    required this.agentId,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.data = const {},
  });

  factory AgentNotification.fromJson(Map<String, dynamic> json) {
    return AgentNotification(
      id: json['id'] as int,
      agentId: json['agentId'] as String? ?? '',
      type: json['type'] as String? ?? 'info',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
    );
  }
}

/// An action button for notifications
class NotificationAction {
  final String id;
  final String label;
  final String? icon;
  final bool destructive;

  const NotificationAction({
    required this.id,
    required this.label,
    this.icon,
    this.destructive = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'icon': icon,
        'destructive': destructive,
      };

  // Common quick actions
  static const confirm = NotificationAction(id: 'confirm', label: 'Confirm');
  static const cancel = NotificationAction(id: 'cancel', label: 'Cancel');
  static const retry = NotificationAction(id: 'retry', label: 'Retry');
  static const dismiss = NotificationAction(id: 'dismiss', label: 'Dismiss');
  static const stop = NotificationAction(
    id: 'stop',
    label: 'Stop',
    destructive: true,
  );
}
