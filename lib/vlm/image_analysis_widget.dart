import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'vlm_service.dart';

class ImageAnalysisWidget extends StatefulWidget {
  final Function(VLMAnalysisResult)? onAnalysisComplete;
  final Function(String)? onTextExtracted;
  final Function(List<VLMDetection>)? onObjectsDetected;
  final bool enableRealTimeAnalysis;
  final bool showDetailedAnalysis;
  final bool enableObjectDetection;
  final bool enableTextExtraction;
  final bool enableSemanticAnalysis;

  const ImageAnalysisWidget({
    Key? key,
    this.onAnalysisComplete,
    this.onTextExtracted,
    this.onObjectsDetected,
    this.enableRealTimeAnalysis = false,
    this.showDetailedAnalysis = true,
    this.enableObjectDetection = true,
    this.enableTextExtraction = true,
    this.enableSemanticAnalysis = true,
  }) : super(key: key);

  @override
  State<ImageAnalysisWidget> createState() => _ImageAnalysisWidgetState();
}

class _ImageAnalysisWidgetState extends State<ImageAnalysisWidget>
    with TickerProviderStateMixin {
  final VLMService _vlmService = VLMService();
  final ImagePicker _imagePicker = ImagePicker();

  late AnimationController _analysisController;
  late AnimationController _resultController;
  late Animation<double> _analysisAnimation;
  late Animation<Offset> _resultSlideAnimation;

  File? _selectedImage;
  VLMAnalysisResult? _analysisResult;
  List<VLMDetection> _detectedObjects = [];
  String _extractedText = '';
  VLMSemanticAnalysis? _semanticAnalysis;
  bool _isAnalyzing = false;
  String _analysisProgress = '';

  @override
  void initState() {
    super.initState();
    _initializeVLM();
    _setupAnimations();
  }

  Future<void> _initializeVLM() async {
    try {
      await _vlmService.initialize();
    } catch (e) {
      _showError('Failed to initialize VLM service: $e');
    }
  }

  void _setupAnimations() {
    _analysisController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _resultController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _analysisAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _analysisController,
      curve: Curves.easeInOut,
    ));

    _resultSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _analysisResult = null;
          _detectedObjects.clear();
          _extractedText = '';
          _semanticAnalysis = null;
        });

        if (widget.enableRealTimeAnalysis) {
          await _analyzeImage();
        }
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null || _isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _analysisProgress = 'Starting analysis...';
    });

    _analysisController.repeat();

    try {
      // Comprehensive analysis
      if (widget.showDetailedAnalysis) {
        setState(() {
          _analysisProgress = 'Analyzing image content...';
        });

        final result = await _vlmService.analyzeImageDetailed(
          _selectedImage!.path,
          prompt: 'Provide a comprehensive analysis of this image including objects, scene, composition, and any notable features.',
        );

        setState(() {
          _analysisResult = result;
        });

        widget.onAnalysisComplete?.call(result);
      }

      // Object detection
      if (widget.enableObjectDetection) {
        setState(() {
          _analysisProgress = 'Detecting objects...';
        });

        final objects = await _vlmService.detectObjects(_selectedImage!.path);

        setState(() {
          _detectedObjects = objects;
        });

        widget.onObjectsDetected?.call(objects);
      }

      // Text extraction
      if (widget.enableTextExtraction) {
        setState(() {
          _analysisProgress = 'Extracting text...';
        });

        final text = await _vlmService.extractText(_selectedImage!.path);

        setState(() {
          _extractedText = text;
        });

        widget.onTextExtracted?.call(text);
      }

      // Semantic analysis
      if (widget.enableSemanticAnalysis) {
        setState(() {
          _analysisProgress = 'Analyzing semantics...';
        });

        final semantics = await _vlmService.analyzeSemantics(_selectedImage!.path);

        setState(() {
          _semanticAnalysis = semantics;
        });
      }

      // Show results
      _analysisController.stop();
      _analysisController.reset();
      _resultController.forward();

    } catch (e) {
      _showError('Analysis failed: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
        _analysisProgress = '';
      });

      _analysisController.stop();
      _analysisController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Image Analysis',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Image selection area
          _buildImageSelectionArea(),

          if (_selectedImage != null) ...[
            const SizedBox(height: 16),
            _buildSelectedImage(),
          ],

          // Analysis controls
          if (_selectedImage != null && !widget.enableRealTimeAnalysis) ...[
            const SizedBox(height: 16),
            _buildAnalysisControls(),
          ],

          // Analysis progress
          if (_isAnalyzing) ...[
            const SizedBox(height: 16),
            _buildAnalysisProgress(),
          ],

          // Results
          if (_analysisResult != null || _detectedObjects.isNotEmpty) ...[
            const SizedBox(height: 16),
            Expanded(child: _buildAnalysisResults()),
          ],
        ],
      ),
    );
  }

  Widget _buildImageSelectionArea() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Select an image to analyze',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedImage!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),

          // Object detection overlay
          if (_detectedObjects.isNotEmpty) ...[
            ...._detectedObjects.map((detection) => _buildDetectionOverlay(detection)),
          ],

          // Controls overlay
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    _selectedImage = null;
                    _analysisResult = null;
                    _detectedObjects.clear();
                    _extractedText = '';
                    _semanticAnalysis = null;
                  }),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionOverlay(VLMDetection detection) {
    return Positioned(
      left: detection.boundingBox.x,
      top: detection.boundingBox.y,
      width: detection.boundingBox.width,
      height: detection.boundingBox.height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.red,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            color: Colors.red,
            child: Text(
              '${detection.label} ${(detection.confidence * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisControls() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: _isAnalyzing ? null : _analyzeImage,
          icon: const Icon(Icons.analytics),
          label: const Text('Analyze'),
        ),
        OutlinedButton.icon(
          onPressed: _isAnalyzing ? null : () => _analyzeSpecific('objects'),
          icon: const Icon(Icons.category),
          label: const Text('Detect Objects'),
        ),
        OutlinedButton.icon(
          onPressed: _isAnalyzing ? null : () => _analyzeSpecific('text'),
          icon: const Icon(Icons.text_fields),
          label: const Text('Extract Text'),
        ),
        OutlinedButton.icon(
          onPressed: _isAnalyzing ? null : () => _analyzeSpecific('caption'),
          icon: const Icon(Icons.description),
          label: const Text('Generate Caption'),
        ),
      ],
    );
  }

  Future<void> _analyzeSpecific(String type) async {
    if (_selectedImage == null || _isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      switch (type) {
        case 'objects':
          final objects = await _vlmService.detectObjects(_selectedImage!.path);
          setState(() {
            _detectedObjects = objects;
          });
          break;

        case 'text':
          final text = await _vlmService.extractText(_selectedImage!.path);
          setState(() {
            _extractedText = text;
          });
          break;

        case 'caption':
          final caption = await _vlmService.generateImageCaption(_selectedImage!.path);
          _showCaptionDialog(caption);
          break;
      }
    } catch (e) {
      _showError('Analysis failed: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Widget _buildAnalysisProgress() {
    return AnimatedBuilder(
      animation: _analysisAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: _analysisAnimation.value,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _analysisProgress,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _analysisAnimation.value,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalysisResults() {
    return SlideTransition(
      position: _resultSlideAnimation,
      child: DefaultTabController(
        length: _getTabCount(),
        child: Column(
          children: [
            TabBar(
              tabs: _buildTabs(),
              isScrollable: true,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: _buildTabViews(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getTabCount() {
    int count = 0;
    if (_analysisResult != null) count++;
    if (_detectedObjects.isNotEmpty) count++;
    if (_extractedText.isNotEmpty) count++;
    if (_semanticAnalysis != null) count++;
    return count > 0 ? count : 1;
  }

  List<Widget> _buildTabs() {
    final tabs = <Widget>[];

    if (_analysisResult != null) {
      tabs.add(const Tab(icon: Icon(Icons.analytics), text: 'Analysis'));
    }

    if (_detectedObjects.isNotEmpty) {
      tabs.add(const Tab(icon: Icon(Icons.category), text: 'Objects'));
    }

    if (_extractedText.isNotEmpty) {
      tabs.add(const Tab(icon: Icon(Icons.text_fields), text: 'Text'));
    }

    if (_semanticAnalysis != null) {
      tabs.add(const Tab(icon: Icon(Icons.psychology), text: 'Semantics'));
    }

    if (tabs.isEmpty) {
      tabs.add(const Tab(icon: Icon(Icons.info), text: 'No Results'));
    }

    return tabs;
  }

  List<Widget> _buildTabViews() {
    final views = <Widget>[];

    if (_analysisResult != null) {
      views.add(_buildDetailedAnalysisView());
    }

    if (_detectedObjects.isNotEmpty) {
      views.add(_buildObjectDetectionView());
    }

    if (_extractedText.isNotEmpty) {
      views.add(_buildTextExtractionView());
    }

    if (_semanticAnalysis != null) {
      views.add(_buildSemanticAnalysisView());
    }

    if (views.isEmpty) {
      views.add(_buildNoResultsView());
    }

    return views;
  }

  Widget _buildDetailedAnalysisView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisSection('Description', _analysisResult!.description),

          if (_analysisResult!.dominantColors.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildColorAnalysisSection(),
          ],

          if (_analysisResult!.composition.layout.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCompositionSection(),
          ],

          const SizedBox(height: 16),
          _buildConfidenceSection(),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Text(content),
        ),
      ],
    );
  }

  Widget _buildColorAnalysisSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dominant Colors',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _analysisResult!.dominantColors.map((color) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Color.fromRGBO(color.red, color.green, color.blue, 1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                '${color.name} (${(color.percentage * 100).toInt()}%)',
                style: TextStyle(
                  color: _getContrastColor(color),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getContrastColor(VLMColor color) {
    final brightness = (color.red * 299 + color.green * 587 + color.blue * 114) / 1000;
    return brightness > 128 ? Colors.black : Colors.white;
  }

  Widget _buildCompositionSection() {
    final composition = _analysisResult!.composition;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Composition',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Layout: ${composition.layout}'),
              Text('Style: ${composition.style}'),
              Text('Lighting: ${composition.lighting}'),
              if (composition.subjects.isNotEmpty)
                Text('Subjects: ${composition.subjects.join(', ')}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Confidence',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _analysisResult!.confidence,
          backgroundColor: Theme.of(context).colorScheme.surface,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getConfidenceColor(_analysisResult!.confidence),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(_analysisResult!.confidence * 100).toInt()}% confident',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildObjectDetectionView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _detectedObjects.length,
      itemBuilder: (context, index) {
        final detection = _detectedObjects[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                '${(detection.confidence * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(detection.label),
            subtitle: Text(
              'Position: (${detection.boundingBox.x.toInt()}, ${detection.boundingBox.y.toInt()})',
            ),
            trailing: Icon(
              Icons.visibility,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextExtractionView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Extracted Text',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _extractedText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Text copied to clipboard')),
                  );
                },
                icon: const Icon(Icons.copy),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _extractedText.isEmpty ? 'No text detected' : _extractedText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemanticAnalysisView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_semanticAnalysis!.emotions.isNotEmpty) ...[
            _buildSemanticSection('Emotions', _semanticAnalysis!.emotions),
            const SizedBox(height: 16),
          ],

          if (_semanticAnalysis!.activities.isNotEmpty) ...[
            _buildSemanticSection('Activities', _semanticAnalysis!.activities),
            const SizedBox(height: 16),
          ],

          if (_semanticAnalysis!.relationships.isNotEmpty) ...[
            _buildSemanticSection('Relationships', _semanticAnalysis!.relationships),
            const SizedBox(height: 16),
          ],

          if (_semanticAnalysis!.scene.isNotEmpty) ...[
            _buildAnalysisSection('Scene', _semanticAnalysis!.scene),
          ],
        ],
      ),
    );
  }

  Widget _buildSemanticSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Chip(
              label: Text(item),
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No analysis results available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showCaptionDialog(String caption) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generated Caption'),
        content: Text(caption),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: caption));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Caption copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  void dispose() {
    _analysisController.dispose();
    _resultController.dispose();
    _vlmService.dispose();
    super.dispose();
  }
}