import 'dart:async';
import 'package:llamafu/llamafu.dart';
import 'llm_interface.dart';

/// LLM adapter implementation using llamafu (on-device llama.cpp FFI bindings)
class LlamafuLLMAdapter implements LLMInterface {
  final String modelPath;
  final String? mmprojPath;
  final int threads;
  final int contextSize;

  Llamafu? _llamafu;
  Chat? _chat;
  StreamController<String>? _streamController;
  bool _isInitialized = false;

  LlamafuLLMAdapter({
    required this.modelPath,
    this.mmprojPath,
    this.threads = 4,
    this.contextSize = 2048,
  });

  /// Initialize the LLM model
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _llamafu = await Llamafu.init(
        modelPath: modelPath,
        mmprojPath: mmprojPath,
        threads: threads,
        contextSize: contextSize,
      );

      // Create a chat instance for conversation-style interactions
      _chat = Chat(
        _llamafu!,
        config: const ChatConfig(
          maxHistory: 50,
          maxTokens: 512,
          temperature: 0.7,
        ),
      );

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Llamafu: $e');
    }
  }

  @override
  Future<String> generateResponse(
    String prompt, {
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || _llamafu == null) {
      await initialize();
    }

    final maxTokens = parameters?['max_tokens'] as int? ?? 512;
    final temperature = (parameters?['temperature'] as num?)?.toDouble() ?? 0.7;

    try {
      // Use the Chat interface for conversation-style interactions
      if (_chat != null && parameters?['use_chat'] == true) {
        return await _chat!.send(prompt);
      }

      // Direct completion for non-conversational prompts
      return await _llamafu!.complete(
        prompt: prompt,
        maxTokens: maxTokens,
        temperature: temperature,
      );
    } catch (e) {
      throw Exception('Failed to generate response: $e');
    }
  }

  @override
  Future<List<String>> generateMultipleResponses(String prompt, int count) async {
    final responses = <String>[];
    for (int i = 0; i < count; i++) {
      final response = await generateResponse(
        prompt,
        parameters: {'temperature': 0.9}, // Higher temperature for variety
      );
      responses.add(response);
    }
    return responses;
  }

  @override
  Future<bool> isReady() async {
    return _isInitialized && _llamafu != null;
  }

  @override
  Stream<String>? get streamingResponse => _streamController?.stream;

  /// Generate response with streaming
  Stream<String> generateResponseStream(
    String prompt, {
    int maxTokens = 512,
    double temperature = 0.7,
  }) {
    if (!_isInitialized || _llamafu == null) {
      throw StateError('LLM not initialized. Call initialize() first.');
    }

    return _llamafu!.completeStream(
      prompt: prompt,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }

  /// Generate response with grammar constraints (JSON, etc.)
  Future<String> generateWithGrammar(
    String prompt, {
    required String grammarStr,
    String grammarRoot = 'root',
    int maxTokens = 512,
    double temperature = 0.7,
  }) async {
    if (!_isInitialized || _llamafu == null) {
      await initialize();
    }

    return await _llamafu!.completeWithGrammar(
      prompt: prompt,
      grammarStr: grammarStr,
      grammarRoot: grammarRoot,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }

  /// Clear chat history
  void clearChatHistory({bool keepSystemPrompt = true}) {
    _chat?.clear(keepSystemPrompt: keepSystemPrompt);
  }

  /// Get chat history
  List<ChatMessage> getChatHistory() {
    return _chat?.history ?? [];
  }

  /// Get model information
  ModelInfo? getModelInfo() {
    return _llamafu?.getModelInfo();
  }

  /// Get performance statistics
  PerfStats? getPerfStats() {
    return _llamafu?.getPerfStats();
  }

  /// Get memory usage
  MemoryUsage? getMemoryUsage() {
    return _llamafu?.getMemoryUsage();
  }

  @override
  void dispose() {
    _streamController?.close();
    _llamafu?.close();
    _llamafu = null;
    _chat = null;
    _isInitialized = false;
  }
}

/// VLM adapter implementation using llamafu multimodal capabilities
class LlamafuVLMAdapter implements VLMInterface {
  final String modelPath;
  final String mmprojPath;
  final int threads;
  final int contextSize;

  Llamafu? _llamafu;
  bool _isInitialized = false;

  LlamafuVLMAdapter({
    required this.modelPath,
    required this.mmprojPath,
    this.threads = 4,
    this.contextSize = 2048,
  });

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _llamafu = await Llamafu.init(
        modelPath: modelPath,
        mmprojPath: mmprojPath,
        threads: threads,
        contextSize: contextSize,
      );
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize VLM: $e');
    }
  }

  @override
  Future<String> generateResponse(
    String prompt, {
    String? imagePath,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized || _llamafu == null) {
      await initialize();
    }

    final maxTokens = parameters?['max_tokens'] as int? ?? 512;
    final temperature = (parameters?['temperature'] as num?)?.toDouble() ?? 0.7;

    if (imagePath != null) {
      // Multimodal completion with image
      return await _llamafu!.multimodalComplete(
        prompt: prompt,
        mediaInputs: [
          MediaInput(type: MediaType.image, data: imagePath),
        ],
        maxTokens: maxTokens,
        temperature: temperature,
      );
    } else {
      // Text-only completion
      return await _llamafu!.complete(
        prompt: prompt,
        maxTokens: maxTokens,
        temperature: temperature,
      );
    }
  }

  @override
  Future<String> analyzeImage(String imagePath, {String? prompt}) async {
    final analysisPrompt = prompt ?? 'Describe this image in detail.';
    return await generateResponse(analysisPrompt, imagePath: imagePath);
  }

  @override
  Future<String> describeImage(String imagePath) async {
    return await analyzeImage(
      imagePath,
      prompt: 'Provide a detailed description of this image, including objects, colors, text, and layout.',
    );
  }

  @override
  Future<List<String>> extractText(String imagePath) async {
    final response = await analyzeImage(
      imagePath,
      prompt: 'Extract all visible text from this image. Return each text segment on a new line.',
    );
    return response.split('\n').where((line) => line.trim().isNotEmpty).toList();
  }

  @override
  Future<Map<String, dynamic>> analyzeScreenshot(String screenshotPath) async {
    final description = await analyzeImage(
      screenshotPath,
      prompt: '''Analyze this screenshot and provide:
1. App or interface type
2. Main UI elements visible (buttons, text fields, menus)
3. Current state or screen
4. Any text content visible
5. Actionable elements and their locations

Format as structured analysis.''',
    );

    return {
      'description': description,
      'screenshot_path': screenshotPath,
      'analyzed_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<bool> isReady() async {
    return _isInitialized && _llamafu != null;
  }

  /// Stream multimodal response
  Stream<String> generateResponseStream(
    String prompt, {
    String? imagePath,
    int maxTokens = 512,
    double temperature = 0.7,
  }) {
    if (!_isInitialized || _llamafu == null) {
      throw StateError('VLM not initialized. Call initialize() first.');
    }

    final mediaInputs = imagePath != null
        ? [MediaInput(type: MediaType.image, data: imagePath)]
        : <MediaInput>[];

    return _llamafu!.multimodalCompleteStream(
      prompt: prompt,
      mediaInputs: mediaInputs,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }

  @override
  void dispose() {
    _llamafu?.close();
    _llamafu = null;
    _isInitialized = false;
  }
}
