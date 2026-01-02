import 'dart:async';

abstract class LLMInterface {
  Future<String> generateResponse(String prompt, {Map<String, dynamic>? parameters});
  Future<List<String>> generateMultipleResponses(String prompt, int count);
  Future<bool> isReady();
  Stream<String>? get streamingResponse;
  void dispose();
}

abstract class VLMInterface {
  Future<void> initialize();
  Future<String> generateResponse(String prompt, {String? imagePath, Map<String, dynamic>? parameters});
  Future<String> analyzeImage(String imagePath, {String? prompt});
  Future<String> describeImage(String imagePath);
  Future<List<String>> extractText(String imagePath);
  Future<Map<String, dynamic>> analyzeScreenshot(String screenshotPath);
  Future<bool> isReady();
  void dispose();
}

class LLMParameters {
  final double temperature;
  final int maxTokens;
  final double topP;
  final double frequencyPenalty;
  final double presencePenalty;
  final List<String>? stop;

  const LLMParameters({
    this.temperature = 0.7,
    this.maxTokens = 512,
    this.topP = 1.0,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
    this.stop,
  });

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'max_tokens': maxTokens,
      'top_p': topP,
      'frequency_penalty': frequencyPenalty,
      'presence_penalty': presencePenalty,
      if (stop != null) 'stop': stop,
    };
  }
}

class ModelCapabilities {
  final bool supportsStreaming;
  final bool supportsVision;
  final bool supportsFunctionCalling;
  final int maxContextLength;
  final List<String> supportedImageFormats;

  const ModelCapabilities({
    this.supportsStreaming = false,
    this.supportsVision = false,
    this.supportsFunctionCalling = false,
    this.maxContextLength = 2048,
    this.supportedImageFormats = const [],
  });
}

enum ModelType {
  llm,
  vlm,
  multimodal,
}

abstract class ModelInterface {
  String get name;
  String get version;
  ModelType get type;
  ModelCapabilities get capabilities;
  bool get isLoaded;

  Future<void> load();
  Future<void> unload();
  Future<Map<String, dynamic>> getInfo();
}