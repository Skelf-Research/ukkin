import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:sqlite_bm25/sqlite_bm25.dart';
import '../models/agent_message.dart';
import '../models/task.dart';

class MemoryManager {
  final Database _database;
  late final Bm25Extension _bm25;

  MemoryManager(this._database) {
    _bm25 = Bm25Extension(_database);
  }

  static Future<MemoryManager> create(Database database) async {
    await _initializeTables(database);
    return MemoryManager(database);
  }

  static Future<void> _initializeTables(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS memories (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        content TEXT NOT NULL,
        embedding BLOB,
        metadata TEXT,
        importance REAL DEFAULT 1.0,
        access_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        last_accessed TEXT,
        tags TEXT
      )
    ''');

    await database.execute('''
      CREATE TABLE IF NOT EXISTS conversations (
        id TEXT PRIMARY KEY,
        participant_ids TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_message_at TEXT,
        metadata TEXT
      )
    ''');

    await database.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        agent_id TEXT NOT NULL,
        type TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        reply_to TEXT,
        metadata TEXT,
        FOREIGN KEY (conversation_id) REFERENCES conversations (id)
      )
    ''');

    await database.execute('''
      CREATE TABLE IF NOT EXISTS task_history (
        id TEXT PRIMARY KEY,
        task_type TEXT NOT NULL,
        description TEXT NOT NULL,
        parameters TEXT,
        status TEXT NOT NULL,
        result TEXT,
        error TEXT,
        execution_time_ms INTEGER,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        agent_id TEXT
      )
    ''');

    await database.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS memory_search USING fts4(
        memory_id TEXT,
        content TEXT,
        tags TEXT
      )
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_memories_type ON memories(type)
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_memories_importance ON memories(importance)
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_memories_created_at ON memories(created_at)
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_task_history_type ON task_history(task_type)
    ''');
  }

  Future<void> storeMemory({
    required String id,
    required String type,
    required String content,
    Map<String, dynamic>? metadata,
    double importance = 1.0,
    List<String> tags = const [],
  }) async {
    final now = DateTime.now().toIso8601String();

    await _database.insert(
      'memories',
      {
        'id': id,
        'type': type,
        'content': content,
        'metadata': metadata != null ? jsonEncode(metadata) : null,
        'importance': importance,
        'created_at': now,
        'tags': tags.join(','),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _database.insert(
      'memory_search',
      {
        'memory_id': id,
        'content': content,
        'tags': tags.join(' '),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> storeMessage(AgentMessage message) async {
    await _database.insert(
      'messages',
      {
        'id': message.id,
        'conversation_id': 'default', // TODO: Implement proper conversation management
        'agent_id': message.agentId,
        'type': message.type.name,
        'content': message.content,
        'timestamp': message.timestamp.toIso8601String(),
        'reply_to': message.replyTo,
        'metadata': jsonEncode(message.metadata),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Also store as memory for long-term retention
    await storeMemory(
      id: 'msg_${message.id}',
      type: 'message',
      content: message.content,
      metadata: {
        'agent_id': message.agentId,
        'message_type': message.type.name,
        'timestamp': message.timestamp.toIso8601String(),
      },
      importance: _calculateMessageImportance(message),
    );
  }

  Future<void> storeExecution(String executionLog) async {
    await storeMemory(
      id: 'exec_${DateTime.now().millisecondsSinceEpoch}',
      type: 'execution',
      content: executionLog,
      importance: 0.8,
      tags: ['execution', 'learning'],
    );
  }

  Future<void> storeTask(Task task, TaskResult? result) async {
    await _database.insert(
      'task_history',
      {
        'id': task.id,
        'task_type': task.type,
        'description': task.description,
        'parameters': jsonEncode(task.parameters),
        'status': task.status.name,
        'result': result?.result != null ? jsonEncode(result!.result) : null,
        'error': result?.error,
        'execution_time_ms': result != null && task.startedAt != null
            ? result.completedAt.difference(task.startedAt!).inMilliseconds
            : null,
        'created_at': task.createdAt.toIso8601String(),
        'completed_at': task.completedAt?.toIso8601String(),
        'agent_id': task.assignedAgentId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> getRelevantContext(String query, {int limit = 10}) async {
    final searchResults = await _database.rawQuery('''
      SELECT m.content, m.importance, m.type, m.created_at
      FROM memory_search ms
      JOIN memories m ON ms.memory_id = m.id
      WHERE memory_search MATCH ?
      ORDER BY bm25(memory_search) * m.importance DESC
      LIMIT ?
    ''', [query, limit]);

    return searchResults.map((row) => row['content'] as String).toList();
  }

  Future<List<Task>> getRecentTasks({int limit = 10}) async {
    final taskResults = await _database.query(
      'task_history',
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return taskResults.map((row) {
      return Task(
        id: row['id'] as String,
        type: row['task_type'] as String,
        description: row['description'] as String,
        parameters: jsonDecode(row['parameters'] as String),
        status: TaskStatus.values.firstWhere(
          (s) => s.name == row['status'],
          orElse: () => TaskStatus.pending,
        ),
        createdAt: DateTime.parse(row['created_at'] as String),
        assignedAgentId: row['agent_id'] as String?,
      )
        ..completedAt = row['completed_at'] != null
            ? DateTime.parse(row['completed_at'] as String)
            : null;
    }).toList();
  }

  Future<List<AgentMessage>> getConversationHistory({
    String? conversationId,
    int limit = 50,
  }) async {
    final messageResults = await _database.query(
      'messages',
      where: conversationId != null ? 'conversation_id = ?' : null,
      whereArgs: conversationId != null ? [conversationId] : null,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return messageResults.map((row) {
      return AgentMessage(
        id: row['id'] as String,
        agentId: row['agent_id'] as String,
        type: MessageType.values.firstWhere(
          (t) => t.name == row['type'],
          orElse: () => MessageType.agent,
        ),
        content: row['content'] as String,
        timestamp: DateTime.parse(row['timestamp'] as String),
        replyTo: row['reply_to'] as String?,
        metadata: jsonDecode(row['metadata'] as String? ?? '{}'),
      );
    }).toList();
  }

  Future<void> updateMemoryImportance(String memoryId, double importance) async {
    await _database.update(
      'memories',
      {'importance': importance},
      where: 'id = ?',
      whereArgs: [memoryId],
    );
  }

  Future<void> incrementAccessCount(String memoryId) async {
    await _database.rawUpdate('''
      UPDATE memories
      SET access_count = access_count + 1,
          last_accessed = ?
      WHERE id = ?
    ''', [DateTime.now().toIso8601String(), memoryId]);
  }

  Future<Map<String, dynamic>> getMemoryStats() async {
    final totalMemories = Sqflite.firstIntValue(
      await _database.rawQuery('SELECT COUNT(*) FROM memories'),
    ) ?? 0;

    final memoryTypes = await _database.rawQuery('''
      SELECT type, COUNT(*) as count
      FROM memories
      GROUP BY type
    ''');

    final totalTasks = Sqflite.firstIntValue(
      await _database.rawQuery('SELECT COUNT(*) FROM task_history'),
    ) ?? 0;

    final tasksByStatus = await _database.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM task_history
      GROUP BY status
    ''');

    return {
      'total_memories': totalMemories,
      'memory_types': Map.fromIterable(
        memoryTypes,
        key: (row) => row['type'],
        value: (row) => row['count'],
      ),
      'total_tasks': totalTasks,
      'tasks_by_status': Map.fromIterable(
        tasksByStatus,
        key: (row) => row['status'],
        value: (row) => row['count'],
      ),
    };
  }

  Future<void> cleanupOldMemories({
    Duration retentionPeriod = const Duration(days: 30),
    double minImportance = 0.1,
  }) async {
    final cutoffDate = DateTime.now()
        .subtract(retentionPeriod)
        .toIso8601String();

    await _database.delete(
      'memories',
      where: 'created_at < ? AND importance < ?',
      whereArgs: [cutoffDate, minImportance],
    );

    await _database.delete(
      'memory_search',
      where: 'memory_id NOT IN (SELECT id FROM memories)',
    );
  }

  Future<List<String>> getSimilarMemories(String content, {int limit = 5}) async {
    final searchResults = await _database.rawQuery('''
      SELECT m.content, bm25(memory_search) as score
      FROM memory_search ms
      JOIN memories m ON ms.memory_id = m.id
      WHERE memory_search MATCH ?
      ORDER BY score DESC
      LIMIT ?
    ''', [content, limit]);

    return searchResults.map((row) => row['content'] as String).toList();
  }

  double _calculateMessageImportance(AgentMessage message) {
    double importance = 1.0;

    // Higher importance for error messages
    if (message.type == MessageType.error) importance *= 1.5;

    // Higher importance for learning messages
    if (message.type == MessageType.learning) importance *= 1.3;

    // Higher importance for longer messages
    if (message.content.length > 200) importance *= 1.2;

    // Higher importance for messages with attachments
    if (message.attachments.isNotEmpty) importance *= 1.4;

    return importance;
  }

  Future<void> optimizeDatabase() async {
    await _database.execute('VACUUM');
    await _database.execute('REINDEX');
  }
}