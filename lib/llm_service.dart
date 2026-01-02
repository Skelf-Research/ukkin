import 'dart:async';
import 'package:llamafu/llamafu.dart' as llamafu;

/// Service for on-device LLM inference using llamafu
class LLMService {
  static final LLMService _instance = LLMService._internal();
  factory LLMService() => _instance;
  LLMService._internal();

  String? _modelPath;
  llamafu.Llamafu? _llamafu;
  llamafu.Chat? _chat;
  bool _isModelReady = false;

  Future<void> initialize({required String modelPath}) async {
    _modelPath = modelPath;

    try {
      _llamafu = await llamafu.Llamafu.init(
        modelPath: modelPath,
        threads: 4,
        contextSize: 2048,
      );

      _chat = llamafu.Chat(
        _llamafu!,
        config: const llamafu.ChatConfig(
          maxHistory: 50,
          maxTokens: 256,
          temperature: 0.1,
        ),
      );

      _isModelReady = true;
    } catch (e) {
      throw Exception("Failed to initialize LLM: $e");
    }
  }

  bool get isReady => _isModelReady;

  Future<String> getCompletion(String prompt) async {
    if (!_isModelReady || _llamafu == null) {
      throw Exception("LLM model is not initialized");
    }

    try {
      return await _llamafu!.complete(
        prompt: prompt,
        maxTokens: 256,
        temperature: 0.1,
      );
    } catch (e) {
      throw Exception("Failed to generate completion: $e");
    }
  }

  /// Generate response from chat history
  Future<String> generateResponse(List<llamafu.ChatMessage> messages) async {
    if (!_isModelReady || _chat == null) {
      throw Exception("LLM model is not initialized");
    }

    // Get the last user message
    final userMessage = messages.lastWhere(
      (m) => m.role == llamafu.Role.user,
      orElse: () => throw Exception("No user message found"),
    );

    try {
      return await _chat!.send(userMessage.content);
    } catch (e) {
      throw Exception("Failed to generate response: $e");
    }
  }

  /// Stream response tokens
  Stream<String> streamCompletion(String prompt) {
    if (!_isModelReady || _llamafu == null) {
      throw StateError("LLM model is not initialized");
    }

    return _llamafu!.completeStream(
      prompt: prompt,
      maxTokens: 256,
      temperature: 0.1,
    );
  }

  void clearHistory() {
    _chat?.clear();
  }

  void dispose() {
    _llamafu?.close();
    _llamafu = null;
    _chat = null;
    _isModelReady = false;
  }
}
