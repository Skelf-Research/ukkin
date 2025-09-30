enum MessageType {
  user,
  agent,
  system,
  status,
  error,
  response,
  learning,
  tool,
}

class AgentMessage {
  final String id;
  final String agentId;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final String? replyTo;
  final Map<String, dynamic> metadata;
  final List<String> attachments;

  AgentMessage({
    required this.id,
    required this.agentId,
    required this.type,
    required this.content,
    DateTime? timestamp,
    this.replyTo,
    this.metadata = const {},
    this.attachments = const [],
  }) : timestamp = timestamp ?? DateTime.now();

  AgentMessage copyWith({
    String? id,
    String? agentId,
    MessageType? type,
    String? content,
    DateTime? timestamp,
    String? replyTo,
    Map<String, dynamic>? metadata,
    List<String>? attachments,
  }) {
    return AgentMessage(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      replyTo: replyTo ?? this.replyTo,
      metadata: metadata ?? this.metadata,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agentId': agentId,
      'type': type.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'replyTo': replyTo,
      'metadata': metadata,
      'attachments': attachments,
    };
  }

  factory AgentMessage.fromJson(Map<String, dynamic> json) {
    return AgentMessage(
      id: json['id'],
      agentId: json['agentId'],
      type: MessageType.values.firstWhere((t) => t.name == json['type']),
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      replyTo: json['replyTo'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      attachments: List<String>.from(json['attachments'] ?? []),
    );
  }

  @override
  String toString() {
    return 'AgentMessage(id: $id, type: $type, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Conversation {
  final String id;
  final List<String> participants;
  final List<AgentMessage> messages;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  Conversation({
    required this.id,
    required this.participants,
    List<AgentMessage>? messages,
    DateTime? createdAt,
    this.metadata = const {},
  })  : messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now();

  void addMessage(AgentMessage message) {
    messages.add(message);
  }

  List<AgentMessage> getMessagesFromAgent(String agentId) {
    return messages.where((msg) => msg.agentId == agentId).toList();
  }

  List<AgentMessage> getMessagesByType(MessageType type) {
    return messages.where((msg) => msg.type == type).toList();
  }

  AgentMessage? getLastMessage() {
    return messages.isNotEmpty ? messages.last : null;
  }

  List<AgentMessage> getRecentMessages(int count) {
    if (messages.length <= count) return messages;
    return messages.sublist(messages.length - count);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      participants: List<String>.from(json['participants']),
      messages: (json['messages'] as List)
          .map((msgJson) => AgentMessage.fromJson(msgJson))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}