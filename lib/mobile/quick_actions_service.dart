import 'dart:async';
import 'package:flutter/services.dart';

/// Service for managing quick actions from notification panel and app shortcuts
class QuickActionsService {
  static const MethodChannel _channel = MethodChannel('com.ukkin/quick_actions');
  static final QuickActionsService _instance = QuickActionsService._();

  factory QuickActionsService() => _instance;
  QuickActionsService._();

  bool _isInitialized = false;
  final _actionController = StreamController<QuickAction>.broadcast();

  Stream<QuickAction> get actions => _actionController.stream;

  /// Initialize quick actions service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _channel.setMethodCallHandler(_handleMethodCall);
      await _registerDefaultActions();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onQuickAction':
        final actionType = call.arguments['type'] as String;
        final data = Map<String, dynamic>.from(call.arguments['data'] ?? {});
        _actionController.add(QuickAction(type: actionType, data: data));
        break;
    }
  }

  /// Register default quick actions
  Future<void> _registerDefaultActions() async {
    await setQuickActions([
      const QuickActionItem(
        type: 'new_chat',
        title: 'New Chat',
        subtitle: 'Start a conversation',
        icon: 'chat_bubble',
      ),
      const QuickActionItem(
        type: 'run_agent',
        title: 'Run Agent',
        subtitle: 'Execute an agent task',
        icon: 'smart_toy',
      ),
      const QuickActionItem(
        type: 'voice_command',
        title: 'Voice Command',
        subtitle: 'Speak to Ukkin',
        icon: 'mic',
      ),
    ]);
  }

  /// Set available quick actions
  Future<void> setQuickActions(List<QuickActionItem> items) async {
    try {
      await _channel.invokeMethod('setQuickActions', {
        'actions': items.map((item) => item.toJson()).toList(),
      });
    } catch (e) {
      // Silently fail if not supported
    }
  }

  /// Clear all quick actions
  Future<void> clearQuickActions() async {
    try {
      await _channel.invokeMethod('clearQuickActions');
    } catch (e) {
      // Silently fail
    }
  }

  /// Add a dynamic quick action
  Future<void> addDynamicAction(QuickActionItem item) async {
    try {
      await _channel.invokeMethod('addDynamicAction', item.toJson());
    } catch (e) {
      // Silently fail
    }
  }

  /// Remove a dynamic quick action
  Future<void> removeDynamicAction(String type) async {
    try {
      await _channel.invokeMethod('removeDynamicAction', {'type': type});
    } catch (e) {
      // Silently fail
    }
  }

  void dispose() {
    _actionController.close();
  }
}

/// A quick action event
class QuickAction {
  final String type;
  final Map<String, dynamic> data;

  const QuickAction({
    required this.type,
    this.data = const {},
  });
}

/// Configuration for a quick action item
class QuickActionItem {
  final String type;
  final String title;
  final String? subtitle;
  final String? icon;

  const QuickActionItem({
    required this.type,
    required this.title,
    this.subtitle,
    this.icon,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'subtitle': subtitle,
        'icon': icon,
      };
}
