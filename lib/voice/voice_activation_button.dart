import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'voice_input_service.dart';

class VoiceActivationButton extends StatefulWidget {
  final Function(String) onVoiceInput;
  final Function(String)? onPartialInput;
  final VoidCallback? onListeningStart;
  final VoidCallback? onListeningStop;
  final double size;
  final Color? primaryColor;
  final Color? backgroundColor;
  final bool showRipple;
  final bool hapticFeedback;
  final Duration? longPressDuration;

  const VoiceActivationButton({
    Key? key,
    required this.onVoiceInput,
    this.onPartialInput,
    this.onListeningStart,
    this.onListeningStop,
    this.size = 56.0,
    this.primaryColor,
    this.backgroundColor,
    this.showRipple = true,
    this.hapticFeedback = true,
    this.longPressDuration,
  }) : super(key: key);

  @override
  State<VoiceActivationButton> createState() => _VoiceActivationButtonState();
}

class _VoiceActivationButtonState extends State<VoiceActivationButton>
    with TickerProviderStateMixin {
  late VoiceInputService _voiceService;
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _scaleController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _scaleAnimation;

  StreamSubscription<VoiceInputEvent>? _eventSubscription;

  bool _isListening = false;
  bool _hasPermission = false;
  bool _isPressed = false;
  Timer? _longPressTimer;

  @override
  void initState() {
    super.initState();
    _initializeVoiceService();
    _setupAnimations();
  }

  void _initializeVoiceService() async {
    _voiceService = VoiceInputService();

    try {
      await _voiceService.initialize();
      _hasPermission = await _voiceService.checkPermissions();

      if (!_hasPermission) {
        _hasPermission = await _voiceService.requestPermissions();
      }

      _setupEventListeners();
    } catch (e) {
      // Handle initialization error
      debugPrint('Voice service initialization error: $e');
    }
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.4,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupEventListeners() {
    _eventSubscription = _voiceService.eventStream.listen((event) {
      switch (event.type) {
        case VoiceInputEventType.listeningStarted:
          setState(() {
            _isListening = true;
          });
          _pulseController.repeat(reverse: true);
          widget.onListeningStart?.call();
          break;

        case VoiceInputEventType.listeningStopped:
        case VoiceInputEventType.listeningCanceled:
          setState(() {
            _isListening = false;
          });
          _pulseController.stop();
          _pulseController.reset();
          widget.onListeningStop?.call();
          break;

        case VoiceInputEventType.partialResult:
          widget.onPartialInput?.call(event.data ?? '');
          break;

        case VoiceInputEventType.finalResult:
          setState(() {
            _isListening = false;
          });
          _pulseController.stop();
          _pulseController.reset();
          widget.onVoiceInput(event.data ?? '');
          break;

        case VoiceInputEventType.error:
          setState(() {
            _isListening = false;
          });
          _pulseController.stop();
          _pulseController.reset();
          break;

        default:
          break;
      }
    });
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _scaleController.forward();

    if (widget.hapticFeedback) {
      HapticFeedback.lightImpact();
    }

    // Start long press timer for continuous listening
    _longPressTimer = Timer(
      widget.longPressDuration ?? const Duration(milliseconds: 500),
      _startContinuousListening,
    );
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();
    _longPressTimer?.cancel();

    if (!_isListening) {
      _startQuickListening();
    }
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();
    _longPressTimer?.cancel();

    if (_isListening) {
      _stopListening();
    }
  }

  void _startQuickListening() async {
    if (!_hasPermission) {
      _hasPermission = await _voiceService.requestPermissions();
      if (!_hasPermission) return;
    }

    try {
      await _voiceService.startListening(
        timeout: const Duration(seconds: 5),
        partialResults: true,
      );

      if (widget.showRipple) {
        _rippleController.forward().then((_) {
          _rippleController.reset();
        });
      }
    } catch (e) {
      debugPrint('Quick listening error: $e');
    }
  }

  void _startContinuousListening() async {
    if (!_hasPermission) {
      _hasPermission = await _voiceService.requestPermissions();
      if (!_hasPermission) return;
    }

    try {
      await _voiceService.startListening(
        timeout: const Duration(seconds: 30),
        partialResults: true,
      );

      if (widget.hapticFeedback) {
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      debugPrint('Continuous listening error: $e');
    }
  }

  void _stopListening() async {
    try {
      await _voiceService.stopListening();
    } catch (e) {
      debugPrint('Stop listening error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.colorScheme.primary;
    final backgroundColor = widget.backgroundColor ?? Colors.white;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseAnimation,
          _rippleAnimation,
          _scaleAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ripple effect
                if (widget.showRipple && _rippleAnimation.value > 0) ...[
                  Container(
                    width: widget.size * 2 * _rippleAnimation.value,
                    height: widget.size * 2 * _rippleAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(
                        0.3 * (1 - _rippleAnimation.value),
                      ),
                    ),
                  ),
                ],

                // Pulse effect when listening
                if (_isListening) ...[
                  Container(
                    width: widget.size * _pulseAnimation.value,
                    height: widget.size * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.2),
                    ),
                  ),
                ],

                // Main button
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening ? primaryColor : backgroundColor,
                    border: Border.all(
                      color: primaryColor,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: _isListening ? 12 : 8,
                        spreadRadius: _isListening ? 2 : 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.white : primaryColor,
                    size: widget.size * 0.4,
                  ),
                ),

                // Visual feedback for press state
                if (_isPressed)
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.1),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _longPressTimer?.cancel();
    _pulseController.dispose();
    _rippleController.dispose();
    _scaleController.dispose();
    _voiceService.dispose();
    super.dispose();
  }
}

class FloatingVoiceButton extends StatefulWidget {
  final Function(String) onVoiceInput;
  final Function(String)? onPartialInput;
  final Alignment alignment;
  final EdgeInsets margin;
  final bool heroTag;

  const FloatingVoiceButton({
    Key? key,
    required this.onVoiceInput,
    this.onPartialInput,
    this.alignment = Alignment.bottomRight,
    this.margin = const EdgeInsets.all(16),
    this.heroTag = true,
  }) : super(key: key);

  @override
  State<FloatingVoiceButton> createState() => _FloatingVoiceButtonState();
}

class _FloatingVoiceButtonState extends State<FloatingVoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _setupFabAnimation();
  }

  void _setupFabAnimation() {
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));

    _fabController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: Container(
        margin: widget.margin,
        child: ScaleTransition(
          scale: _fabAnimation,
          child: VoiceActivationButton(
            onVoiceInput: widget.onVoiceInput,
            onPartialInput: widget.onPartialInput,
            size: 64,
            showRipple: true,
            hapticFeedback: true,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }
}