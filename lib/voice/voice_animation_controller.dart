import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/animation.dart';

class VoiceAnimationController {
  Timer? _pulseTimer;
  Timer? _waveTimer;
  bool _isAnimating = false;

  final List<double> _waveformData = [];
  final int _maxWaveformPoints = 50;

  // Animation state
  double _currentPulse = 1.0;
  double _currentWave = 0.0;
  double _volume = 0.0;

  // Callbacks
  Function(double)? onPulseUpdate;
  Function(List<double>)? onWaveformUpdate;
  Function(double)? onVolumeUpdate;

  bool get isAnimating => _isAnimating;
  double get currentPulse => _currentPulse;
  double get currentWave => _currentWave;
  List<double> get waveformData => _waveformData;

  void startListening() {
    if (_isAnimating) return;

    _isAnimating = true;
    _startPulseAnimation();
    _startWaveformAnimation();
  }

  void stopListening() {
    _isAnimating = false;
    _pulseTimer?.cancel();
    _waveTimer?.cancel();
    _resetAnimations();
  }

  void updateVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    onVolumeUpdate?.call(_volume);
  }

  void _startPulseAnimation() {
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isAnimating) {
        timer.cancel();
        return;
      }

      // Create breathing pulse effect
      final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
      _currentPulse = 1.0 + 0.2 * math.sin(time * math.pi * 2 / 1.5);

      // Add volume influence
      _currentPulse += _volume * 0.3;

      onPulseUpdate?.call(_currentPulse);
    });
  }

  void _startWaveformAnimation() {
    _waveTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isAnimating) {
        timer.cancel();
        return;
      }

      _updateWaveform();
    });
  }

  void _updateWaveform() {
    // Generate realistic waveform data
    final random = math.Random();
    final baseAmplitude = _volume * 0.8;

    // Add new point to waveform
    double newPoint = 0.0;

    if (_volume > 0.1) {
      // Generate speech-like waveform
      newPoint = baseAmplitude * (0.5 + 0.5 * math.sin(DateTime.now().millisecondsSinceEpoch / 100.0));
      newPoint += (random.nextDouble() - 0.5) * 0.2 * baseAmplitude;
      newPoint = newPoint.clamp(0.0, 1.0);
    }

    _waveformData.add(newPoint);

    // Keep only recent points
    if (_waveformData.length > _maxWaveformPoints) {
      _waveformData.removeAt(0);
    }

    onWaveformUpdate?.call(_waveformData);
  }

  void _resetAnimations() {
    _currentPulse = 1.0;
    _currentWave = 0.0;
    _volume = 0.0;
    _waveformData.clear();

    onPulseUpdate?.call(_currentPulse);
    onWaveformUpdate?.call(_waveformData);
    onVolumeUpdate?.call(_volume);
  }

  void dispose() {
    stopListening();
  }
}

class VoiceWaveformGenerator {
  static List<double> generateRealisticWaveform({
    required double volume,
    required int points,
    double frequency = 1.0,
    double? seed,
  }) {
    final random = math.Random(seed?.toInt());
    final waveform = <double>[];

    for (int i = 0; i < points; i++) {
      final x = i / points;

      // Base sine wave
      double value = math.sin(x * 2 * math.pi * frequency);

      // Add harmonics for more realistic speech pattern
      value += 0.3 * math.sin(x * 4 * math.pi * frequency);
      value += 0.15 * math.sin(x * 8 * math.pi * frequency);

      // Add random noise for natural variation
      value += (random.nextDouble() - 0.5) * 0.2;

      // Apply volume scaling
      value *= volume;

      // Add speech-like envelope
      final envelope = math.sin(x * math.pi); // Natural speech envelope
      value *= envelope;

      // Normalize to 0-1 range
      value = (value + 1) / 2;
      value = value.clamp(0.0, 1.0);

      waveform.add(value);
    }

    return waveform;
  }

  static List<double> generateSilentWaveform(int points) {
    return List.filled(points, 0.0);
  }

  static List<double> smoothWaveform(List<double> waveform, double factor) {
    if (waveform.length < 3) return waveform;

    final smoothed = <double>[];

    for (int i = 0; i < waveform.length; i++) {
      if (i == 0 || i == waveform.length - 1) {
        smoothed.add(waveform[i]);
      } else {
        final avg = (waveform[i - 1] + waveform[i] + waveform[i + 1]) / 3;
        smoothed.add(waveform[i] * (1 - factor) + avg * factor);
      }
    }

    return smoothed;
  }
}

class VoiceVisualizer {
  static const double defaultBarWidth = 4.0;
  static const double defaultBarSpacing = 2.0;
  static const double defaultMinHeight = 2.0;
  static const double defaultMaxHeight = 60.0;

  final double barWidth;
  final double barSpacing;
  final double minHeight;
  final double maxHeight;

  const VoiceVisualizer({
    this.barWidth = defaultBarWidth,
    this.barSpacing = defaultBarSpacing,
    this.minHeight = defaultMinHeight,
    this.maxHeight = defaultMaxHeight,
  });

  List<double> normalizeWaveform(List<double> waveform) {
    if (waveform.isEmpty) return waveform;

    final max = waveform.reduce(math.max);
    if (max == 0) return waveform;

    return waveform.map((value) => value / max).toList();
  }

  List<double> scaleToHeight(List<double> normalizedWaveform) {
    return normalizedWaveform.map((value) {
      final height = minHeight + (maxHeight - minHeight) * value;
      return height;
    }).toList();
  }

  int calculateBarCount(double availableWidth) {
    return ((availableWidth + barSpacing) / (barWidth + barSpacing)).floor();
  }

  List<double> resampleWaveform(List<double> waveform, int targetLength) {
    if (waveform.length == targetLength) return waveform;
    if (waveform.isEmpty) return List.filled(targetLength, 0.0);

    final resampled = <double>[];
    final ratio = waveform.length / targetLength;

    for (int i = 0; i < targetLength; i++) {
      final sourceIndex = (i * ratio).floor();
      if (sourceIndex < waveform.length) {
        resampled.add(waveform[sourceIndex]);
      } else {
        resampled.add(0.0);
      }
    }

    return resampled;
  }
}