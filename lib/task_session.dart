import 'dart:async';
import 'package:flutter/material.dart';
import 'agent/models/agent_message.dart';
import 'agent/models/task.dart';

enum SessionStatus {
  active,
  working,
  completed,
  failed,
  paused,
}

class TaskSession {
  final String id;
  final String title;
  final DateTime createdAt;
  DateTime? completedAt;
  SessionStatus status;

  final List<AgentMessage> messages;
  final List<TaskProgress> tasks;
  final Map<String, dynamic> context;

  String? currentObjective;
  double progressPercentage;

  TaskSession({
    required this.id,
    required this.title,
    DateTime? createdAt,
    this.status = SessionStatus.active,
  }) : createdAt = createdAt ?? DateTime.now(),
       messages = [],
       tasks = [],
       context = {},
       progressPercentage = 0.0;

  void addMessage(AgentMessage message) {
    messages.add(message);
  }

  void updateProgress(double progress) {
    progressPercentage = progress.clamp(0.0, 100.0);
    if (progressPercentage >= 100.0 && status == SessionStatus.working) {
      status = SessionStatus.completed;
      completedAt = DateTime.now();
    }
  }

  void addTask(TaskProgress task) {
    tasks.add(task);
    _updateOverallProgress();
  }

  void updateTask(String taskId, TaskStatus status, {dynamic result, String? error}) {
    final taskIndex = tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      tasks[taskIndex].status = status;
      tasks[taskIndex].result = result;
      tasks[taskIndex].error = error;
      if (status == TaskStatus.completed || status == TaskStatus.failed) {
        tasks[taskIndex].completedAt = DateTime.now();
      }
      _updateOverallProgress();
    }
  }

  void _updateOverallProgress() {
    if (tasks.isEmpty) {
      progressPercentage = 0.0;
      return;
    }

    final completedTasks = tasks.where((t) =>
      t.status == TaskStatus.completed || t.status == TaskStatus.failed
    ).length;

    updateProgress((completedTasks / tasks.length) * 100);
  }

  Duration? get duration {
    if (completedAt != null) {
      return completedAt!.difference(createdAt);
    } else {
      return DateTime.now().difference(createdAt);
    }
  }

  String get formattedDuration {
    final dur = duration;
    if (dur == null) return '0m';

    if (dur.inHours > 0) {
      return '${dur.inHours}h ${dur.inMinutes % 60}m';
    } else if (dur.inMinutes > 0) {
      return '${dur.inMinutes}m';
    } else {
      return '${dur.inSeconds}s';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'progress_percentage': progressPercentage,
      'current_objective': currentObjective,
      'messages': messages.map((m) => m.toJson()).toList(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'context': context,
    };
  }

  factory TaskSession.fromJson(Map<String, dynamic> json) {
    final session = TaskSession(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['created_at']),
      status: SessionStatus.values.firstWhere((s) => s.name == json['status']),
    );

    if (json['completed_at'] != null) {
      session.completedAt = DateTime.parse(json['completed_at']);
    }

    session.progressPercentage = json['progress_percentage'] ?? 0.0;
    session.currentObjective = json['current_objective'];

    // Load messages
    for (final msgJson in json['messages'] ?? []) {
      session.messages.add(AgentMessage.fromJson(msgJson));
    }

    // Load tasks
    for (final taskJson in json['tasks'] ?? []) {
      session.tasks.add(TaskProgress.fromJson(taskJson));
    }

    session.context.addAll(Map<String, dynamic>.from(json['context'] ?? {}));

    return session;
  }
}

class TaskProgress {
  final String id;
  final String description;
  final String type;
  TaskStatus status;
  DateTime createdAt;
  DateTime? completedAt;
  dynamic result;
  String? error;
  double progress;

  TaskProgress({
    required this.id,
    required this.description,
    required this.type,
    this.status = TaskStatus.pending,
    DateTime? createdAt,
    this.progress = 0.0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'type': type,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'progress': progress,
      'result': result,
      'error': error,
    };
  }

  factory TaskProgress.fromJson(Map<String, dynamic> json) {
    final task = TaskProgress(
      id: json['id'],
      description: json['description'],
      type: json['type'],
      status: TaskStatus.values.firstWhere((s) => s.name == json['status']),
      createdAt: DateTime.parse(json['created_at']),
      progress: json['progress'] ?? 0.0,
    );

    if (json['completed_at'] != null) {
      task.completedAt = DateTime.parse(json['completed_at']);
    }

    task.result = json['result'];
    task.error = json['error'];

    return task;
  }
}

class SessionManager {
  final List<TaskSession> _sessions = [];
  final StreamController<TaskSession> _sessionController = StreamController<TaskSession>.broadcast();

  Stream<TaskSession> get sessionUpdates => _sessionController.stream;
  List<TaskSession> get sessions => List.unmodifiable(_sessions);

  TaskSession createSession(String title) {
    final session = TaskSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
    );

    _sessions.insert(0, session); // Add to beginning for recency
    _sessionController.add(session);

    return session;
  }

  TaskSession? getSession(String sessionId) {
    try {
      return _sessions.firstWhere((s) => s.id == sessionId);
    } catch (e) {
      return null;
    }
  }

  void updateSession(TaskSession session) {
    _sessionController.add(session);
  }

  void deleteSession(String sessionId) {
    _sessions.removeWhere((s) => s.id == sessionId);
  }

  List<TaskSession> getRecentSessions({int limit = 10}) {
    return _sessions.take(limit).toList();
  }

  List<TaskSession> getActiveSessions() {
    return _sessions.where((s) =>
      s.status == SessionStatus.active || s.status == SessionStatus.working
    ).toList();
  }

  List<TaskSession> searchSessions(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _sessions.where((s) =>
      s.title.toLowerCase().contains(lowercaseQuery) ||
      s.currentObjective?.toLowerCase().contains(lowercaseQuery) == true ||
      s.messages.any((m) => m.content.toLowerCase().contains(lowercaseQuery))
    ).toList();
  }

  void dispose() {
    _sessionController.close();
  }
}