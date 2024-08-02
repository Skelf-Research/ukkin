// llm_service.dart
import 'dart:async';
import 'package:fllama/fllama.dart';

class LLMService {
  static final LLMService _instance = LLMService._internal();
  factory LLMService() => _instance;
  LLMService._internal();

  String? _modelPath;
  String? _mmprojPath;
  bool _isModelReady = false;
  final _requestQueue = StreamController<_LLMRequest>();

  Future<void> initialize({required String modelPath, required String mmprojPath}) async {
    _modelPath = modelPath;
    _mmprojPath = mmprojPath;
    _isModelReady = true;
    _processQueue();
  }

  void _processQueue() async {
    await for (final request in _requestQueue.stream) {
      try {
        final llmRequest = OpenAiRequest(
          maxTokens: 256,
          messages: request.messages,
          numGpuLayers: 99,
          modelPath: _modelPath!,
          mmprojPath: _mmprojPath!,
          frequencyPenalty: 0.0,
          presencePenalty: 1.1,
          topP: 1.0,
          contextSize: 2048,
          temperature: 0.7,
          logger: (log) {
            print('[llama.cpp] $log');
          },
        );

        String result = "";
        await fllamaChat(llmRequest, (response, done) {
          result += response;
          if (done) {
            request.completer.complete(result.trim());
          }
        });
      } catch (e) {
        request.completer.completeError(e);
      }
    }
  }

  Future<String> generateResponse(List<Message> messages) {
    if (!_isModelReady) {
      throw Exception("LLM model is not initialized");
    }
    final completer = Completer<String>();
    _requestQueue.add(_LLMRequest(messages, completer));
    return completer.future;
  }

  void dispose() {
    _requestQueue.close();
  }
}

class _LLMRequest {
  final List<Message> messages;
  final Completer<String> completer;

  _LLMRequest(this.messages, this.completer);
}