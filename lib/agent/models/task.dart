enum TaskStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
}

enum TaskPriority {
  low,
  normal,
  high,
  urgent,
}

class Task {
  final String id;
  final String type;
  final String description;
  final Map<String, dynamic> parameters;
  final TaskPriority priority;
  final DateTime createdAt;
  final String? parentTaskId;
  final List<String> dependencies;

  TaskStatus status;
  DateTime? startedAt;
  DateTime? completedAt;
  String? assignedAgentId;

  Task({
    required this.id,
    required this.type,
    required this.description,
    required this.parameters,
    this.priority = TaskPriority.normal,
    DateTime? createdAt,
    this.parentTaskId,
    this.dependencies = const [],
    this.status = TaskStatus.pending,
    this.assignedAgentId,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get canExecute => dependencies.isEmpty && status == TaskStatus.pending;

  Task copyWith({
    String? id,
    String? type,
    String? description,
    Map<String, dynamic>? parameters,
    TaskPriority? priority,
    DateTime? createdAt,
    String? parentTaskId,
    List<String>? dependencies,
    TaskStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? assignedAgentId,
  }) {
    return Task(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      parameters: parameters ?? this.parameters,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      dependencies: dependencies ?? this.dependencies,
      status: status ?? this.status,
      assignedAgentId: assignedAgentId ?? this.assignedAgentId,
    )
      ..startedAt = startedAt ?? this.startedAt
      ..completedAt = completedAt ?? this.completedAt;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'parameters': parameters,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'parentTaskId': parentTaskId,
      'dependencies': dependencies,
      'status': status.name,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'assignedAgentId': assignedAgentId,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      type: json['type'],
      description: json['description'],
      parameters: Map<String, dynamic>.from(json['parameters']),
      priority: TaskPriority.values.firstWhere((p) => p.name == json['priority']),
      createdAt: DateTime.parse(json['createdAt']),
      parentTaskId: json['parentTaskId'],
      dependencies: List<String>.from(json['dependencies']),
      status: TaskStatus.values.firstWhere((s) => s.name == json['status']),
      assignedAgentId: json['assignedAgentId'],
    )
      ..startedAt = json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null
      ..completedAt = json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null;
  }
}

class TaskResult {
  final String taskId;
  final TaskStatus status;
  final dynamic result;
  final String? error;
  final DateTime completedAt;
  final Map<String, dynamic> metadata;

  TaskResult({
    required this.taskId,
    required this.status,
    this.result,
    this.error,
    DateTime? completedAt,
    this.metadata = const {},
  }) : completedAt = completedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'status': status.name,
      'result': result,
      'error': error,
      'completedAt': completedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory TaskResult.fromJson(Map<String, dynamic> json) {
    return TaskResult(
      taskId: json['taskId'],
      status: TaskStatus.values.firstWhere((s) => s.name == json['status']),
      result: json['result'],
      error: json['error'],
      completedAt: DateTime.parse(json['completedAt']),
      metadata: Map<String, dynamic>.from(json['metadata']),
    );
  }
}

class TaskGraph {
  final Map<String, Task> _tasks = {};
  final Map<String, Set<String>> _dependents = {};

  void addTask(Task task) {
    _tasks[task.id] = task;

    for (final dependencyId in task.dependencies) {
      _dependents.putIfAbsent(dependencyId, () => <String>{});
      _dependents[dependencyId]!.add(task.id);
    }
  }

  void removeTask(String taskId) {
    final task = _tasks.remove(taskId);
    if (task == null) return;

    for (final dependencyId in task.dependencies) {
      _dependents[dependencyId]?.remove(taskId);
      if (_dependents[dependencyId]?.isEmpty == true) {
        _dependents.remove(dependencyId);
      }
    }

    _dependents.remove(taskId);
  }

  List<Task> getExecutableTasks() {
    return _tasks.values
        .where((task) => task.canExecute && _areDependenciesMet(task))
        .toList()
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
  }

  bool _areDependenciesMet(Task task) {
    return task.dependencies.every((depId) {
      final depTask = _tasks[depId];
      return depTask?.status == TaskStatus.completed;
    });
  }

  List<Task> getDependents(String taskId) {
    final dependentIds = _dependents[taskId] ?? <String>{};
    return dependentIds.map((id) => _tasks[id]!).toList();
  }

  List<Task> getTasksByStatus(TaskStatus status) {
    return _tasks.values.where((task) => task.status == status).toList();
  }

  Task? getTask(String taskId) => _tasks[taskId];

  List<Task> getAllTasks() => _tasks.values.toList();

  void updateTaskStatus(String taskId, TaskStatus status) {
    final task = _tasks[taskId];
    if (task != null) {
      task.status = status;
      if (status == TaskStatus.running) {
        task.startedAt = DateTime.now();
      } else if (status == TaskStatus.completed || status == TaskStatus.failed) {
        task.completedAt = DateTime.now();
      }
    }
  }

  bool hasCircularDependencies() {
    final visited = <String>{};
    final recursionStack = <String>{};

    bool hasCycle(String taskId) {
      if (recursionStack.contains(taskId)) return true;
      if (visited.contains(taskId)) return false;

      visited.add(taskId);
      recursionStack.add(taskId);

      final task = _tasks[taskId];
      if (task != null) {
        for (final depId in task.dependencies) {
          if (hasCycle(depId)) return true;
        }
      }

      recursionStack.remove(taskId);
      return false;
    }

    for (final taskId in _tasks.keys) {
      if (hasCycle(taskId)) return true;
    }

    return false;
  }
}