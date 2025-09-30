import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'voice_input_service.dart';
import 'voice_animation_controller.dart';

class VoiceInputWidget extends StatefulWidget {
  final Function(String) onVoiceInput;
  final Function(String)? onPartialInput;
  final VoidCallback? onListeningStart;
  final VoidCallback? onListeningStop;
  final Widget? customMicIcon;
  final Duration? animationDuration;
  final bool showWaveform;
  final bool showTranscription;
  final Color? primaryColor;
  final Color? secondaryColor;

  const VoiceInputWidget({
    Key? key,
    required this.onVoiceInput,
    this.onPartialInput,
    this.onListeningStart,
    this.onListeningStop,
    this.customMicIcon,
    this.animationDuration,
    this.showWaveform = true,
    this.showTranscription = true,
    this.primaryColor,
    this.secondaryColor,
  }) : super(key: key);

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget>
    with TickerProviderStateMixin {
  late VoiceInputService _voiceService;
  late VoiceAnimationController _animationController;

  StreamSubscription<VoiceInputEvent>? _eventSubscription;
  StreamSubscription<String>? _transcriptionSubscription;

  String _currentTranscription = '';
  String _partialTranscription = '';
  bool _isListening = false;
  bool _hasPermission = false;
  String? _errorMessage;
  double _currentVolume = 0.0;

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeVoiceService();
    _setupAnimations();
  }

  void _initializeVoiceService() async {
    _voiceService = VoiceInputService();
    _animationController = VoiceAnimationController();

    try {
      await _voiceService.initialize();
      _hasPermission = await _voiceService.checkPermissions();

      if (!_hasPermission) {
        _hasPermission = await _voiceService.requestPermissions();
      }

      _setupEventListeners();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize voice input: $e';
      });
    }
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 1500),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _setupEventListeners() {
    _eventSubscription = _voiceService.eventStream.listen((event) {
      switch (event.type) {
        case VoiceInputEventType.listeningStarted:
          setState(() {
            _isListening = true;
            _currentTranscription = '';
            _partialTranscription = '';
            _errorMessage = null;
          });
          _animationController.startListening();
          widget.onListeningStart?.call();
          break;

        case VoiceInputEventType.listeningStopped:
        case VoiceInputEventType.listeningCanceled:
          setState(() {
            _isListening = false;
          });
          _animationController.stopListening();
          widget.onListeningStop?.call();
          break;

        case VoiceInputEventType.partialResult:
          setState(() {
            _partialTranscription = event.data ?? '';
          });
          widget.onPartialInput?.call(_partialTranscription);
          break;

        case VoiceInputEventType.finalResult:
          setState(() {
            _currentTranscription = event.data ?? '';
            _partialTranscription = '';
            _isListening = false;
          });
          _animationController.stopListening();
          widget.onVoiceInput(_currentTranscription);
          break;

        case VoiceInputEventType.error:
          setState(() {
            _errorMessage = event.data;
            _isListening = false;
          });
          _animationController.stopListening();
          break;

        case VoiceInputEventType.volumeChanged:
          setState(() {
            _currentVolume = event.volume ?? 0.0;
          });
          _updateWaveAnimation();
          break;

        default:
          break;
      }
    });
  }

  void _updateWaveAnimation() {
    final normalizedVolume = (_currentVolume * 10).clamp(0.0, 1.0);
    _waveController.animateTo(normalizedVolume);
  }

  Future<void> _toggleListening() async {
    if (!_hasPermission) {
      _hasPermission = await _voiceService.requestPermissions();
      if (!_hasPermission) {
        setState(() {
          _errorMessage = 'Microphone permission required';
        });
        return;
      }
    }

    try {
      if (_isListening) {
        await _voiceService.stopListening();
      } else {
        await _voiceService.startListening(partialResults: true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Voice input error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.primaryColor;
    final secondaryColor = widget.secondaryColor ?? theme.colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voice Input Button with Animation
          _buildVoiceInputButton(primaryColor, secondaryColor),

          if (widget.showWaveform && _isListening) ...[
            const SizedBox(height: 16),
            _buildWaveform(primaryColor),
          ],

          if (widget.showTranscription) ...[
            const SizedBox(height: 16),
            _buildTranscriptionArea(theme),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            _buildErrorMessage(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceInputButton(Color primaryColor, Color secondaryColor) {
    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedBuilder(
        animation: _isListening ? _pulseAnimation : _scaleAnimation,
        builder: (context, child) {
          final scale = _isListening ? _pulseAnimation.value : _scaleAnimation.value;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isListening
                    ? LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: _isListening ? null : primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: _isListening ? 20 : 8,
                    spreadRadius: _isListening ? 4 : 2,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 32,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWaveform(Color primaryColor) {
    return Container(
      height: 60,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return CustomPaint(
            painter: WaveformPainter(
              volume: _currentVolume,
              color: primaryColor,
              isListening: _isListening,
            ),
            size: const Size(double.infinity, 60),
          );
        },
      ),
    );
  }

  Widget _buildTranscriptionArea(ThemeData theme) {
    final displayText = _partialTranscription.isNotEmpty
        ? _partialTranscription
        : _currentTranscription;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isListening)
            Text(
              'Listening...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),

          if (displayText.isNotEmpty) ...[
            if (_isListening) const SizedBox(height: 8),
            Text(
              displayText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: _partialTranscription.isNotEmpty
                    ? theme.colorScheme.onSurface.withOpacity(0.7)
                    : theme.colorScheme.onSurface,
                fontStyle: _partialTranscription.isNotEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ] else if (!_isListening) ...[
            Text(
              'Tap the microphone to start voice input',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
            icon: Icon(
              Icons.close,
              color: theme.colorScheme.onErrorContainer,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _transcriptionSubscription?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _animationController.dispose();
    _voiceService.dispose();
    super.dispose();
  }
}

class WaveformPainter extends CustomPainter {
  final double volume;
  final Color color;
  final bool isListening;

  WaveformPainter({
    required this.volume,
    required this.color,
    required this.isListening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isListening) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = size.height / 2;
    final width = size.width;
    final amplitude = volume * center * 0.8;

    final path = Path();

    // Generate wave points
    for (double x = 0; x <= width; x += 2) {
      final frequency = 0.02;
      final y = center + amplitude * math.sin(x * frequency) *
          math.sin(x * frequency * 2) * math.sin(x * frequency * 0.5);

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw additional harmonics for richer waveform
    paint.color = color.withOpacity(0.5);
    final path2 = Path();

    for (double x = 0; x <= width; x += 2) {
      final frequency = 0.04;
      final y = center + amplitude * 0.6 * math.sin(x * frequency + math.pi / 4);

      if (x == 0) {
        path2.moveTo(x, y);
      } else {
        path2.lineTo(x, y);
      }
    }

    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.volume != volume || oldDelegate.isListening != isListening;
  }
}