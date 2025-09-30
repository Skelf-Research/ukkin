import 'dart:async';
import 'package:fllama/fllama.dart';

class LLMService {
  static final LLMService _instance = LLMService._internal();
  factory LLMService() => _instance;
  LLMService._internal();

  String? _modelPath;
  bool _isModelReady = false;

  Future<void> initialize({required String modelPath}) async {
    _modelPath = modelPath;
    _isModelReady = true;
  }

  Future<String> getCompletion(String prompt) async {
    if (!_isModelReady) {
      throw Exception("LLM model is not initialized");
    }

    final completer = Completer<String>();

    try {
      final llmRequest = OpenAiRequest(
        maxTokens: 256,
        messages: [Message(Role.user, prompt)],
        numGpuLayers: 99,
        modelPath: _modelPath!,
        frequencyPenalty: 0.0,
        presencePenalty: 1.1,
        topP: 1.0,
        contextSize: 2048,
        temperature: 0.1,
        logger: (log) {
          print('[llama.cpp] $log');
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

  void dispose() {}
}
