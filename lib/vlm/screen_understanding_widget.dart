import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'vlm_service.dart';

class ScreenUnderstandingWidget extends StatefulWidget {
  final Widget child;
  final Function(VLMScreenAnalysis)? onAnalysisComplete;
  final Function(List<VLMAction>)? onActionsDetected;
  final bool enableRealTimeAnalysis;
  final Duration analysisInterval;
  final bool showOverlay;
  final bool enableAccessibilityCheck;

  const ScreenUnderstandingWidget({
    Key? key,
    required this.child,
    this.onAnalysisComplete,
    this.onActionsDetected,
    this.enableRealTimeAnalysis = false,
    this.analysisInterval = const Duration(seconds: 5),
    this.showOverlay = false,
    this.enableAccessibilityCheck = true,
  }) : super(key: key);

  @override
  State<ScreenUnderstandingWidget> createState() => _ScreenUnderstandingWidgetState();
}

class _ScreenUnderstandingWidgetState extends State<ScreenUnderstandingWidget> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final VLMService _vlmService = VLMService();

  Timer? _analysisTimer;
  VLMScreenAnalysis? _lastAnalysis;
  List<VLMUIElement> _detectedElements = [];
  List<VLMAction> _suggestedActions = [];
  bool _isAnalyzing = false;
  String? _lastScreenshotPath;

  @override
  void initState() {
    super.initState();
    _initializeVLM();
  }

  Future<void> _initializeVLM() async {
    try {
      await _vlmService.initialize();

      if (widget.enableRealTimeAnalysis) {
        _startRealTimeAnalysis();
      }
    } catch (e) {
      debugPrint('VLM initialization failed: $e');
    }
  }

  void _startRealTimeAnalysis() {
    _analysisTimer = Timer.periodic(widget.analysisInterval, (_) {
      if (!_isAnalyzing) {
        _analyzeCurrentScreen();
      }
    });
  }

  Future<void> _analyzeCurrentScreen() async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final screenshotPath = await _captureScreen();
      if (screenshotPath != null) {
        final analysis = await _vlmService.analyzeScreen(screenshotPath);

        setState(() {
          _lastAnalysis = analysis;
          _detectedElements = analysis.uiElements;
          _suggestedActions = analysis.suggestedActions;
          _lastScreenshotPath = screenshotPath;
        });

        widget.onAnalysisComplete?.call(analysis);
        widget.onActionsDetected?.call(analysis.suggestedActions);
      }
    } catch (e) {
      debugPrint('Screen analysis failed: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<String?> _captureScreen() async {
    try {
      final RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      return imagePath;
    } catch (e) {
      debugPrint('Screen capture failed: $e');
      return null;
    }
  }

  // Public API for manual analysis
  Future<VLMScreenAnalysis?> analyzeScreen() async {
    await _analyzeCurrentScreen();
    return _lastAnalysis;
  }

  Future<List<VLMUIElement>> findElementsByType(String elementType) async {
    if (_lastScreenshotPath == null) {
      await _analyzeCurrentScreen();
    }

    if (_lastScreenshotPath != null) {
      return await _vlmService.findUIElements(_lastScreenshotPath!, elementType: elementType);
    }

    return [];
  }

  Future<List<VLMAction>> suggestActionsForIntent(String userIntent) async {
    if (_lastScreenshotPath == null) {
      await _analyzeCurrentScreen();
    }

    if (_lastScreenshotPath != null) {
      return await _vlmService.suggestActions(_lastScreenshotPath!, userIntent: userIntent);
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: Stack(
        children: [
          widget.child,

          // Analysis overlay
          if (widget.showOverlay) ...[
            _buildAnalysisOverlay(),
          ],

          // Loading indicator
          if (_isAnalyzing) ...[
            Positioned(
              top: 50,
              right: 16,
              child: _buildAnalysisIndicator(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisOverlay() {
    if (_detectedElements.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: _detectedElements.map((element) {
        return Positioned(
          left: element.boundingBox.x,
          top: element.boundingBox.y,
          width: element.boundingBox.width,
          height: element.boundingBox.height,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _getElementColor(element.type),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: element.text.isNotEmpty
                ? Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      color: _getElementColor(element.type).withOpacity(0.8),
                      child: Text(
                        element.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnalysisIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Analyzing...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getElementColor(String elementType) {
    switch (elementType.toLowerCase()) {
      case 'button':
        return Colors.blue;
      case 'textfield':
      case 'input':
        return Colors.green;
      case 'text':
      case 'label':
        return Colors.orange;
      case 'image':
        return Colors.purple;
      case 'icon':
        return Colors.red;
      case 'list':
      case 'scroll':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _vlmService.dispose();
    super.dispose();
  }
}

class SmartScreenReader extends StatefulWidget {
  final Function(String) onTextDetected;
  final Function(VLMScreenAnalysis)? onScreenAnalyzed;
  final bool enableContinuousReading;
  final Duration readingInterval;

  const SmartScreenReader({
    Key? key,
    required this.onTextDetected,
    this.onScreenAnalyzed,
    this.enableContinuousReading = false,
    this.readingInterval = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<SmartScreenReader> createState() => _SmartScreenReaderState();
}

class _SmartScreenReaderState extends State<SmartScreenReader> {
  final VLMService _vlmService = VLMService();
  Timer? _readingTimer;
  String _lastDetectedText = '';
  bool _isReading = false;

  @override
  void initState() {
    super.initState();
    _initializeVLM();
  }

  Future<void> _initializeVLM() async {
    try {
      await _vlmService.initialize();

      if (widget.enableContinuousReading) {
        _startContinuousReading();
      }
    } catch (e) {
      debugPrint('VLM initialization failed: $e');
    }
  }

  void _startContinuousReading() {
    _readingTimer = Timer.periodic(widget.readingInterval, (_) {
      if (!_isReading) {
        _readCurrentScreen();
      }
    });
  }

  Future<void> _readCurrentScreen() async {
    if (_isReading) return;

    setState(() {
      _isReading = true;
    });

    try {
      // Capture screen
      final screenshotPath = await _captureScreen();
      if (screenshotPath == null) return;

      // Analyze screen for comprehensive understanding
      final analysis = await _vlmService.analyzeScreen(screenshotPath);
      widget.onScreenAnalyzed?.call(analysis);

      // Extract text
      final extractedText = analysis.extractedText;

      if (extractedText.isNotEmpty && extractedText != _lastDetectedText) {
        _lastDetectedText = extractedText;
        widget.onTextDetected(extractedText);
      }

    } catch (e) {
      debugPrint('Screen reading failed: $e');
    } finally {
      setState(() {
        _isReading = false;
      });
    }
  }

  Future<String?> _captureScreen() async {
    try {
      // Use platform-specific screen capture
      final result = await SystemChannels.platform.invokeMethod('captureScreen');
      return result as String?;
    } catch (e) {
      debugPrint('Screen capture failed: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_isReading) ...[
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Reading screen...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          ElevatedButton.icon(
            onPressed: _isReading ? null : _readCurrentScreen,
            icon: const Icon(Icons.visibility),
            label: const Text('Read Screen'),
          ),

          if (_lastDetectedText.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detected Text:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lastDetectedText,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _readingTimer?.cancel();
    _vlmService.dispose();
    super.dispose();
  }
}

class VLMActionExecutor extends StatelessWidget {
  final List<VLMAction> actions;
  final Function(VLMAction) onActionExecute;
  final bool showConfirmation;

  const VLMActionExecutor({
    Key? key,
    required this.actions,
    required this.onActionExecute,
    this.showConfirmation = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No suggested actions available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ...actions.map((action) => _buildActionCard(context, action)),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, VLMAction action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          leading: Icon(_getActionIcon(action.type)),
          title: Text(action.description),
          subtitle: Text(
            '${action.type} • ${(action.confidence * 100).toInt()}% confidence',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => _executeAction(context, action),
          ),
        ),
      ),
    );
  }

  IconData _getActionIcon(String actionType) {
    switch (actionType.toLowerCase()) {
      case 'tap':
      case 'click':
        return Icons.touch_app;
      case 'type':
      case 'input':
        return Icons.keyboard;
      case 'scroll':
        return Icons.swap_vert;
      case 'swipe':
        return Icons.swipe;
      case 'navigate':
        return Icons.navigation;
      default:
        return Icons.touch_app;
    }
  }

  void _executeAction(BuildContext context, VLMAction action) {
    if (showConfirmation) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Execute Action'),
          content: Text('Do you want to execute: ${action.description}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onActionExecute(action);
              },
              child: const Text('Execute'),
            ),
          ],
        ),
      );
    } else {
      onActionExecute(action);
    }
  }
}