import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class VoiceInputService {
  static const MethodChannel _channel = MethodChannel('voice_input');

  final StreamController<VoiceInputEvent> _eventController =
      StreamController<VoiceInputEvent>.broadcast();

  final StreamController<String> _transcriptionController =
      StreamController<String>.broadcast();

  bool _isListening = false;
  bool _isInitialized = false;
  VoiceInputConfig _config = VoiceInputConfig.defaultConfig();

  Stream<VoiceInputEvent> get eventStream => _eventController.stream;
  Stream<String> get transcriptionStream => _transcriptionController.stream;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  Future<void> initialize({VoiceInputConfig? config}) async {
    if (_isInitialized) return;

    _config = config ?? VoiceInputConfig.defaultConfig();

    try {
      // Initialize platform-specific voice recognition
      await _channel.invokeMethod('initialize', _config.toMap());

      // Set up method call handler for platform callbacks
      _channel.setMethodCallHandler(_handleMethodCall);

      _isInitialized = true;
      _eventController.add(VoiceInputEvent.initialized());
    } catch (e) {
      _eventController.add(VoiceInputEvent.error('Initialization failed: $e'));
      rethrow;
    }
  }

  Future<void> startListening({
    String? language,
    Duration? timeout,
    bool partialResults = true,
  }) async {
    if (!_isInitialized) {
      throw Exception('VoiceInputService not initialized');
    }

    if (_isListening) {
      await stopListening();
    }

    try {
      final params = {
        'language': language ?? _config.language,
        'timeout': (timeout ?? _config.timeout).inMilliseconds,
        'partialResults': partialResults,
        'noiseReduction': _config.noiseReduction,
        'autoGain': _config.autoGainControl,
      };

      await _channel.invokeMethod('startListening', params);
      _isListening = true;
      _eventController.add(VoiceInputEvent.listeningStarted());
    } catch (e) {
      _eventController.add(VoiceInputEvent.error('Failed to start listening: $e'));
      rethrow;
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _channel.invokeMethod('stopListening');
      _isListening = false;
      _eventController.add(VoiceInputEvent.listeningStopped());
    } catch (e) {
      _eventController.add(VoiceInputEvent.error('Failed to stop listening: $e'));
    }
  }

  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      await _channel.invokeMethod('cancelListening');
      _isListening = false;
      _eventController.add(VoiceInputEvent.listeningCanceled());
    } catch (e) {
      _eventController.add(VoiceInputEvent.error('Failed to cancel listening: $e'));
    }
  }

  Future<bool> checkPermissions() async {
    try {
      final hasPermissions = await _channel.invokeMethod('checkPermissions');
      return hasPermissions as bool;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final granted = await _channel.invokeMethod('requestPermissions');
      return granted as bool;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _channel.invokeMethod('getAvailableLanguages');
      return List<String>.from(languages);
    } catch (e) {
      return ['en-US']; // Fallback to English
    }
  }

  Future<double> getInputLevel() async {
    try {
      final level = await _channel.invokeMethod('getInputLevel');
      return (level as num).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  void updateConfig(VoiceInputConfig config) {
    _config = config;
    if (_isInitialized) {
      _channel.invokeMethod('updateConfig', config.toMap());
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPartialResult':
        final text = call.arguments as String;
        _transcriptionController.add(text);
        _eventController.add(VoiceInputEvent.partialResult(text));
        break;

      case 'onFinalResult':
        final text = call.arguments as String;
        _transcriptionController.add(text);
        _eventController.add(VoiceInputEvent.finalResult(text));
        break;

      case 'onError':
        final error = call.arguments as String;
        _eventController.add(VoiceInputEvent.error(error));
        break;

      case 'onVolumeChanged':
        final volume = (call.arguments as num).toDouble();
        _eventController.add(VoiceInputEvent.volumeChanged(volume));
        break;

      case 'onReadyForSpeech':
        _eventController.add(VoiceInputEvent.readyForSpeech());
        break;

      case 'onBeginningOfSpeech':
        _eventController.add(VoiceInputEvent.beginningOfSpeech());
        break;

      case 'onEndOfSpeech':
        _eventController.add(VoiceInputEvent.endOfSpeech());
        break;

      case 'onTimeout':
        _isListening = false;
        _eventController.add(VoiceInputEvent.timeout());
        break;
    }
  }

  void dispose() {
    _isListening = false;
    _eventController.close();
    _transcriptionController.close();
  }
}

class VoiceInputConfig {
  final String language;
  final Duration timeout;
  final bool noiseReduction;
  final bool autoGainControl;
  final double minimumConfidence;
  final bool enableProfanityFilter;
  final bool enablePunctuation;

  const VoiceInputConfig({
    this.language = 'en-US',
    this.timeout = const Duration(seconds: 30),
    this.noiseReduction = true,
    this.autoGainControl = true,
    this.minimumConfidence = 0.5,
    this.enableProfanityFilter = false,
    this.enablePunctuation = true,
  });

  factory VoiceInputConfig.defaultConfig() => const VoiceInputConfig();

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'timeout': timeout.inMilliseconds,
      'noiseReduction': noiseReduction,
      'autoGainControl': autoGainControl,
      'minimumConfidence': minimumConfidence,
      'enableProfanityFilter': enableProfanityFilter,
      'enablePunctuation': enablePunctuation,
    };
  }

  VoiceInputConfig copyWith({
    String? language,
    Duration? timeout,
    bool? noiseReduction,
    bool? autoGainControl,
    double? minimumConfidence,
    bool? enableProfanityFilter,
    bool? enablePunctuation,
  }) {
    return VoiceInputConfig(
      language: language ?? this.language,
      timeout: timeout ?? this.timeout,
      noiseReduction: noiseReduction ?? this.noiseReduction,
      autoGainControl: autoGainControl ?? this.autoGainControl,
      minimumConfidence: minimumConfidence ?? this.minimumConfidence,
      enableProfanityFilter: enableProfanityFilter ?? this.enableProfanityFilter,
      enablePunctuation: enablePunctuation ?? this.enablePunctuation,
    );
  }
}

class VoiceInputEvent {
  final VoiceInputEventType type;
  final String? data;
  final double? volume;
  final DateTime timestamp;

  VoiceInputEvent._(this.type, this.data, this.volume)
      : timestamp = DateTime.now();

  factory VoiceInputEvent.initialized() => VoiceInputEvent._(
      VoiceInputEventType.initialized, null, null);

  factory VoiceInputEvent.listeningStarted() => VoiceInputEvent._(
      VoiceInputEventType.listeningStarted, null, null);

  factory VoiceInputEvent.listeningStopped() => VoiceInputEvent._(
      VoiceInputEventType.listeningStopped, null, null);

  factory VoiceInputEvent.listeningCanceled() => VoiceInputEvent._(
      VoiceInputEventType.listeningCanceled, null, null);

  factory VoiceInputEvent.partialResult(String text) => VoiceInputEvent._(
      VoiceInputEventType.partialResult, text, null);

  factory VoiceInputEvent.finalResult(String text) => VoiceInputEvent._(
      VoiceInputEventType.finalResult, text, null);

  factory VoiceInputEvent.error(String error) => VoiceInputEvent._(
      VoiceInputEventType.error, error, null);

  factory VoiceInputEvent.volumeChanged(double volume) => VoiceInputEvent._(
      VoiceInputEventType.volumeChanged, null, volume);

  factory VoiceInputEvent.readyForSpeech() => VoiceInputEvent._(
      VoiceInputEventType.readyForSpeech, null, null);

  factory VoiceInputEvent.beginningOfSpeech() => VoiceInputEvent._(
      VoiceInputEventType.beginningOfSpeech, null, null);

  factory VoiceInputEvent.endOfSpeech() => VoiceInputEvent._(
      VoiceInputEventType.endOfSpeech, null, null);

  factory VoiceInputEvent.timeout() => VoiceInputEvent._(
      VoiceInputEventType.timeout, null, null);

  @override
  String toString() => 'VoiceInputEvent(type: $type, data: $data, volume: $volume)';
}

enum VoiceInputEventType {
  initialized,
  listeningStarted,
  listeningStopped,
  listeningCanceled,
  partialResult,
  finalResult,
  error,
  volumeChanged,
  readyForSpeech,
  beginningOfSpeech,
  endOfSpeech,
  timeout,
}