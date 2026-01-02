import 'dart:io';
import 'package:flutter/services.dart';
import 'tool.dart';
import '../models/task.dart';
import '../llm/llm_interface.dart';

class VisionTool extends Tool with ToolValidation {
  final VLMInterface? vlm;

  VisionTool({this.vlm});

  @override
  String get name => 'vision';

  @override
  String get description => 'Analyze images, screenshots, and visual content for understanding and interaction';

  @override
  Map<String, String> get parameters => {
        'action': 'Action: describe, analyze, extract_text, find_elements, compare',
        'image_path': 'Path to image file',
        'prompt': 'Custom analysis prompt (optional)',
        'target_element': 'Element to find (for find_elements action)',
        'compare_with': 'Second image path for comparison',
      };

  @override
  bool canHandle(Task task) {
    return task.type == 'vision' || task.type.startsWith('vision_');
  }

  @override
  Future<bool> validate(Map<String, dynamic> parameters) async {
    if (!validateRequired(parameters, ['action', 'image_path'])) return false;

    final action = parameters['action'] as String;
    final imagePath = parameters['image_path'] as String;

    // Check if image file exists
    if (!await File(imagePath).exists()) return false;

    // Validate action-specific parameters
    switch (action) {
      case 'compare':
        return parameters.containsKey('compare_with') &&
               await File(parameters['compare_with']).exists();
      case 'find_elements':
        return parameters.containsKey('target_element');
      default:
        return true;
    }
  }

  @override
  Future<dynamic> execute(Map<String, dynamic> parameters) async {
    if (!await validate(parameters)) {
      throw Exception('Invalid parameters for vision tool');
    }

    final action = parameters['action'] as String;
    final imagePath = parameters['image_path'] as String;

    try {
      switch (action) {
        case 'describe':
          return await _describeImage(imagePath, parameters['prompt']);
        case 'analyze':
          return await _analyzeImage(imagePath, parameters['prompt']);
        case 'extract_text':
          return await _extractText(imagePath);
        case 'find_elements':
          return await _findElements(imagePath, parameters['target_element']);
        case 'compare':
          return await _compareImages(imagePath, parameters['compare_with']);
        case 'screenshot_analysis':
          return await _analyzeScreenshot(imagePath);
        default:
          throw Exception('Unknown vision action: $action');
      }
    } catch (e) {
      return ToolExecutionResult.failure('Vision analysis failed: $e');
    }
  }

  Future<ToolExecutionResult> _describeImage(String imagePath, String? customPrompt) async {
    try {
      if (vlm != null) {
        final description = customPrompt != null
            ? await vlm!.analyzeImage(imagePath, prompt: customPrompt)
            : await vlm!.describeImage(imagePath);

        return ToolExecutionResult.success({
          'description': description,
          'image_path': imagePath,
          'analysis_type': 'description',
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        // Fallback to basic image analysis
        final imageInfo = await _getImageInfo(imagePath);
        return ToolExecutionResult.success({
          'description': 'Image analysis requires VLM model',
          'image_info': imageInfo,
          'analysis_type': 'basic_info',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      return ToolExecutionResult.failure('Image description failed: $e');
    }
  }

  Future<ToolExecutionResult> _analyzeImage(String imagePath, String? customPrompt) async {
    try {
      if (vlm != null) {
        final prompt = customPrompt ?? '''
        Analyze this image in detail. Identify:
        1. Main objects and their locations
        2. Text content if any
        3. Colors and visual style
        4. Context and setting
        5. Any interactive elements
        6. Overall composition and layout
        ''';

        final analysis = await vlm!.analyzeImage(imagePath, prompt: prompt);

        return ToolExecutionResult.success({
          'analysis': analysis,
          'image_path': imagePath,
          'analysis_type': 'detailed',
          'prompt_used': prompt,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        return await _basicImageAnalysis(imagePath);
      }
    } catch (e) {
      return ToolExecutionResult.failure('Image analysis failed: $e');
    }
  }

  Future<ToolExecutionResult> _extractText(String imagePath) async {
    try {
      if (vlm != null) {
        final textContent = await vlm!.extractText(imagePath);

        return ToolExecutionResult.success({
          'text_content': textContent,
          'text_count': textContent.length,
          'image_path': imagePath,
          'analysis_type': 'text_extraction',
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        // Fallback - try basic OCR or return placeholder
        return ToolExecutionResult.success({
          'text_content': ['Text extraction requires VLM model'],
          'text_count': 0,
          'image_path': imagePath,
          'analysis_type': 'text_extraction_unavailable',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      return ToolExecutionResult.failure('Text extraction failed: $e');
    }
  }

  Future<ToolExecutionResult> _findElements(String imagePath, String targetElement) async {
    try {
      if (vlm != null) {
        final prompt = '''
        Look for "$targetElement" in this image. Identify:
        1. Whether the element exists
        2. Location/position of the element
        3. Size and appearance
        4. Any text associated with it
        5. Whether it appears interactive (button, link, etc.)

        If multiple instances exist, describe each one.
        ''';

        final analysis = await vlm!.analyzeImage(imagePath, prompt: prompt);

        return ToolExecutionResult.success({
          'target_element': targetElement,
          'analysis': analysis,
          'image_path': imagePath,
          'analysis_type': 'element_search',
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        return ToolExecutionResult.failure('Element finding requires VLM model');
      }
    } catch (e) {
      return ToolExecutionResult.failure('Element finding failed: $e');
    }
  }

  Future<ToolExecutionResult> _compareImages(String imagePath1, String imagePath2) async {
    try {
      if (vlm != null) {
        final description1 = await vlm!.describeImage(imagePath1);
        final description2 = await vlm!.describeImage(imagePath2);

        // Create comparison prompt
        final comparisonPrompt = '''
        Compare these two images:

        Image 1: $description1
        Image 2: $description2

        Identify:
        1. Similarities
        2. Differences
        3. Changes between the images
        4. Which elements moved, appeared, or disappeared
        ''';

        // For now, return the individual descriptions
        // TODO: Implement proper multi-image comparison when VLM supports it
        return ToolExecutionResult.success({
          'image1_path': imagePath1,
          'image2_path': imagePath2,
          'image1_description': description1,
          'image2_description': description2,
          'comparison_method': 'sequential_analysis',
          'analysis_type': 'comparison',
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        return ToolExecutionResult.failure('Image comparison requires VLM model');
      }
    } catch (e) {
      return ToolExecutionResult.failure('Image comparison failed: $e');
    }
  }

  Future<ToolExecutionResult> _analyzeScreenshot(String screenshotPath) async {
    try {
      if (vlm != null) {
        final analysis = await vlm!.analyzeScreenshot(screenshotPath);

        return ToolExecutionResult.success({
          'screenshot_path': screenshotPath,
          'ui_analysis': analysis,
          'analysis_type': 'screenshot',
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        return await _basicScreenshotAnalysis(screenshotPath);
      }
    } catch (e) {
      return ToolExecutionResult.failure('Screenshot analysis failed: $e');
    }
  }

  Future<ToolExecutionResult> _basicImageAnalysis(String imagePath) async {
    final imageInfo = await _getImageInfo(imagePath);

    return ToolExecutionResult.success({
      'image_info': imageInfo,
      'analysis': 'Basic image information - VLM required for detailed analysis',
      'analysis_type': 'basic',
      'image_path': imagePath,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<ToolExecutionResult> _basicScreenshotAnalysis(String screenshotPath) async {
    final imageInfo = await _getImageInfo(screenshotPath);

    return ToolExecutionResult.success({
      'screenshot_path': screenshotPath,
      'image_info': imageInfo,
      'ui_analysis': {
        'description': 'Screenshot captured - VLM required for UI element analysis',
        'ui_elements': <String>[],
        'text_content': <String>[],
        'interactive_elements': <String>[],
      },
      'analysis_type': 'basic_screenshot',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> _getImageInfo(String imagePath) async {
    try {
      final file = File(imagePath);
      final fileStat = await file.stat();
      final bytes = await file.readAsBytes();

      // Try to get basic image dimensions (simplified)
      return {
        'file_size': fileStat.size,
        'file_path': imagePath,
        'exists': true,
        'byte_length': bytes.length,
        'last_modified': fileStat.modified.toIso8601String(),
      };
    } catch (e) {
      return {
        'error': 'Failed to read image info: $e',
        'exists': false,
        'file_path': imagePath,
      };
    }
  }

  Future<ToolExecutionResult> captureScreenshot({String? savePath}) async {
    try {
      // Use platform channels to capture screenshot
      const platform = MethodChannel('ukkin.agent/screenshot');

      final String? screenshotPath = await platform.invokeMethod('captureScreenshot', {
        'savePath': savePath,
      });

      if (screenshotPath != null) {
        return ToolExecutionResult.success({
          'screenshot_path': screenshotPath,
          'captured_at': DateTime.now().toIso8601String(),
          'action': 'screenshot_captured',
        });
      } else {
        return ToolExecutionResult.failure('Screenshot capture returned null path');
      }
    } catch (e) {
      return ToolExecutionResult.failure('Screenshot capture failed: $e');
    }
  }

  Future<bool> isVLMReady() async {
    if (vlm == null) return false;
    return await vlm!.isReady();
  }

  Future<List<String>> getSupportedImageFormats() async {
    return ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'];
  }
}