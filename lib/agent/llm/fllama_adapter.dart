import 'dart:async';
import 'package:fllama/fllama.dart';
import 'llm_interface.dart';

class FllamaLLMAdapter implements LLMInterface {
  final String modelPath;
  final LLMParameters defaultParameters;

  bool _isInitialized = false;
  StreamController<String>? _streamController;

  FllamaLLMAdapter({
    required this.modelPath,
    this.defaultParameters = const LLMParameters(),
  });

  @override
  Future<bool> isReady() async {
    return _isInitialized;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize fllama if needed
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Fllama LLM: $e');
    }
  }

  @override
  Future<String> generateResponse(String prompt, {Map<String, dynamic>? parameters}) async {
    if (!_isInitialized) {
      await initialize();
    }

    final params = _mergeParameters(parameters);
    final completer = Completer<String>();

    try {
      final llmRequest = OpenAiRequest(
        maxTokens: params['max_tokens'] ?? defaultParameters.maxTokens,
        messages: [Message(Role.user, prompt)],
        numGpuLayers: 99,
        modelPath: modelPath,
        frequencyPenalty: params['frequency_penalty'] ?? defaultParameters.frequencyPenalty,
        presencePenalty: params['presence_penalty'] ?? defaultParameters.presencePenalty,
        topP: params['top_p'] ?? defaultParameters.topP,
        contextSize: 2048,
        temperature: params['temperature'] ?? defaultParameters.temperature,
        logger: (log) {
          print('[fllama] $log');
        },
      );

      String result = "";
      fllamaChat(llmRequest, (response, done) {
        result += response;
        if (done) {
          completer.complete(result.trim());
        }
      });
    } catch (e) {
      completer.completeError(e);
    }

    return completer.future;
  }

  @override
  Future<List<String>> generateMultipleResponses(String prompt, int count) async {
    final responses = <String>[];

    for (int i = 0; i < count; i++) {
      final response = await generateResponse(prompt, {
        'temperature': defaultParameters.temperature + (i * 0.1),
      });
      responses.add(response);
    }

    return responses;
  }

  Future<String> generateStreamingResponse(String prompt, {Map<String, dynamic>? parameters}) async {
    if (!_isInitialized) {
      await initialize();
    }

    _streamController = StreamController<String>.broadcast();
    final params = _mergeParameters(parameters);

    try {
      final llmRequest = OpenAiRequest(
        maxTokens: params['max_tokens'] ?? defaultParameters.maxTokens,
        messages: [Message(Role.user, prompt)],
        numGpuLayers: 99,
        modelPath: modelPath,
        frequencyPenalty: params['frequency_penalty'] ?? defaultParameters.frequencyPenalty,
        presencePenalty: params['presence_penalty'] ?? defaultParameters.presencePenalty,
        topP: params['top_p'] ?? defaultParameters.topP,
        contextSize: 2048,
        temperature: params['temperature'] ?? defaultParameters.temperature,
        logger: (log) {
          print('[fllama] $log');
        },
      );

      String fullResponse = "";
      final completer = Completer<String>();

      fllamaChat(llmRequest, (response, done) {
        fullResponse += response;
        _streamController?.add(response);

        if (done) {
          _streamController?.close();
          completer.complete(fullResponse.trim());
        }
      });

      return completer.future;
    } catch (e) {
      _streamController?.addError(e);
      _streamController?.close();
      rethrow;
    }
  }

  @override
  Stream<String>? get streamingResponse => _streamController?.stream;

  Map<String, dynamic> _mergeParameters(Map<String, dynamic>? parameters) {
    final merged = defaultParameters.toMap();
    if (parameters != null) {
      merged.addAll(parameters);
    }
    return merged;
  }

  Future<String> chatWithContext(
    List<Message> messages, {
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final params = _mergeParameters(parameters);
    final completer = Completer<String>();

    try {
      final llmRequest = OpenAiRequest(
        maxTokens: params['max_tokens'] ?? defaultParameters.maxTokens,
        messages: messages,
        numGpuLayers: 99,
        modelPath: modelPath,
        frequencyPenalty: params['frequency_penalty'] ?? defaultParameters.frequencyPenalty,
        presencePenalty: params['presence_penalty'] ?? defaultParameters.presencePenalty,
        topP: params['top_p'] ?? defaultParameters.topP,
        contextSize: 2048,
        temperature: params['temperature'] ?? defaultParameters.temperature,
        logger: (log) {
          print('[fllama] $log');
        },
      );

      String result = "";
      fllamaChat(llmRequest, (response, done) {
        result += response;
        if (done) {
          completer.complete(result.trim());
        }
      });
    } catch (e) {
      completer.completeError(e);
    }

    return completer.future;
  }

  Future<String> generateWithSystemPrompt(
    String systemPrompt,
    String userPrompt, {
    Map<String, dynamic>? parameters,
  }) async {
    final messages = [
      Message(Role.system, systemPrompt),
      Message(Role.user, userPrompt),
    ];

    return chatWithContext(messages, parameters: parameters);
  }

  Future<double> calculatePerplexity(String text) async {
    // TODO: Implement perplexity calculation if supported by fllama
    return 0.0;
  }

  Future<List<double>> getEmbeddings(String text) async {
    // TODO: Implement embeddings if supported by fllama
    return [];
  }

  Future<Map<String, dynamic>> getModelInfo() async {
    return {
      'model_path': modelPath,
      'is_initialized': _isInitialized,
      'capabilities': {
        'streaming': true,
        'chat': true,
        'embeddings': false,
        'function_calling': false,
      },
      'parameters': defaultParameters.toMap(),
    };
  }

  @override
  void dispose() {
    _streamController?.close();
    _streamController = null;
    _isInitialized = false;
  }
}

class FllamaVLMAdapter implements VLMInterface {
  final String modelPath;
  bool _isInitialized = false;

  FllamaVLMAdapter({required this.modelPath});

  @override
  Future<bool> isReady() async {
    return _isInitialized;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize VLM model if supported
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Fllama VLM: $e');
    }
  }

  @override
  Future<String> analyzeImage(String imagePath, {String? prompt}) async {
    if (!_isInitialized) {
      await initialize();
    }

    // TODO: Implement image analysis when VLM support is available in fllama
    return "Image analysis not yet implemented in fllama";
  }

  @override
  Future<String> describeImage(String imagePath) async {
    return analyzeImage(imagePath, prompt: "Describe this image in detail.");
  }

  @override
  Future<List<String>> extractText(String imagePath) async {
    final description = await analyzeImage(imagePath, prompt: "Extract all text visible in this image.");
    return [description]; // Simplified for now
  }

  @override
  Future<Map<String, dynamic>> analyzeScreenshot(String screenshotPath) async {
    final description = await analyzeImage(
      screenshotPath,
      prompt: "Analyze this screenshot. Identify UI elements, text, and interactive components.",
    );

    return {
      'description': description,
      'ui_elements': <String>[], // TODO: Parse UI elements
      'text_content': <String>[], // TODO: Extract text
      'interactive_elements': <String>[], // TODO: Identify buttons, links, etc.
    };
  }

  @override
  void dispose() {
    _isInitialized = false;
  }
}

class FllamaModelManager implements ModelInterface {
  @override
  final String name;

  @override
  final String version;

  final String modelPath;
  FllamaLLMAdapter? _llmAdapter;
  FllamaVLMAdapter? _vlmAdapter;
  bool _isLoaded = false;

  FllamaModelManager({
    required this.name,
    required this.version,
    required this.modelPath,
  });

  @override
  ModelType get type => ModelType.llm; // TODO: Detect based on model

  @override
  ModelCapabilities get capabilities => const ModelCapabilities(
    supportsStreaming: true,
    supportsVision: false, // TODO: Update when VLM support is added
    supportsFunctionCalling: false,
    maxContextLength: 2048,
    supportedImageFormats: [],
  );

  @override
  bool get isLoaded => _isLoaded;

  @override
  Future<void> load() async {
    if (_isLoaded) return;

    _llmAdapter = FllamaLLMAdapter(modelPath: modelPath);
    await _llmAdapter!.initialize();

    if (capabilities.supportsVision) {
      _vlmAdapter = FllamaVLMAdapter(modelPath: modelPath);
      await _vlmAdapter!.initialize();
    }

    _isLoaded = true;
  }

  @override
  Future<void> unload() async {
    _llmAdapter?.dispose();
    _vlmAdapter?.dispose();
    _llmAdapter = null;
    _vlmAdapter = null;
    _isLoaded = false;
  }

  @override
  Future<Map<String, dynamic>> getInfo() async {
    final info = await _llmAdapter?.getModelInfo() ?? {};
    return {
      'name': name,
      'version': version,
      'type': type.name,
      'is_loaded': isLoaded,
      'capabilities': {
        'streaming': capabilities.supportsStreaming,
        'vision': capabilities.supportsVision,
        'function_calling': capabilities.supportsFunctionCalling,
        'max_context_length': capabilities.maxContextLength,
      },
      ...info,
    };
  }

  FllamaLLMAdapter? get llm => _llmAdapter;
  FllamaVLMAdapter? get vlm => _vlmAdapter;
}