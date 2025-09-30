import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../tools/tool.dart';
import '../models/task.dart';
import '../llm/llm_interface.dart';

class ScreenRecorder extends Tool with ToolValidation {
  static const MethodChannel _platform = MethodChannel('ukkin.screen/recorder');
  final VLMInterface? vlm;

  bool _isRecording = false;
  String? _currentRecordingPath;

  ScreenRecorder({this.vlm});

  @override
  String get name => 'screen_recorder';

  @override
  String get description => 'Record screen activity, take screenshots, and analyze visual interactions';

  @override
  Map<String, String> get parameters => {
        'action': 'Action: start_recording, stop_recording, take_screenshot, analyze_recording, get_frames',
        'duration': 'Recording duration in seconds',
        'output_path': 'Output file path',
        'frame_rate': 'Recording frame rate (default: 30)',
        'quality': 'Recording quality: low, medium, high',
        'include_audio': 'Include audio recording: true/false',
        'analysis_prompt': 'Custom analysis prompt for recordings',
      };

  @override
  bool canHandle(Task task) {
    return task.type == 'screen_recording' || task.type.startsWith('screen_');
  }

  @override
  Future<bool> validate(Map<String, dynamic> parameters) async {
    return validateRequired(parameters, ['action']);
  }

  @override
  Future<dynamic> execute(Map<String, dynamic> parameters) async {
    if (!await validate(parameters)) {
      throw Exception('Invalid parameters for screen recorder');
    }

    final action = parameters['action'] as String;

    try {
      switch (action) {
        case 'start_recording':
          return await _startRecording(parameters);
        case 'stop_recording':
          return await _stopRecording();
        case 'take_screenshot':
          return await _takeScreenshot(parameters['output_path']);
        case 'analyze_recording':
          return await _analyzeRecording(
            parameters['recording_path'],
            parameters['analysis_prompt'],
          );
        case 'get_frames':
          return await _extractFrames(
            parameters['recording_path'],
            parameters['frame_interval'],
          );
        case 'continuous_analysis':
          return await _startContinuousAnalysis(parameters);
        case 'stop_analysis':
          return await _stopContinuousAnalysis();
        default:
          throw Exception('Unknown screen recording action: $action');
      }
    } catch (e) {
      return ToolExecutionResult.failure('Screen recording action failed: $e');
    }
  }

  Future<ToolExecutionResult> _startRecording(Map<String, dynamic> parameters) async {
    if (_isRecording) {
      return ToolExecutionResult.failure('Recording already in progress');
    }

    try {
      final duration = parameters['duration'] as int? ?? 30;
      final frameRate = parameters['frame_rate'] as int? ?? 30;
      final quality = parameters['quality'] as String? ?? 'medium';
      final includeAudio = parameters['include_audio'] as bool? ?? false;
      final outputPath = parameters['output_path'] as String?;

      final result = await _platform.invokeMethod('startRecording', {
        'duration': duration,
        'frameRate': frameRate,
        'quality': quality,
        'includeAudio': includeAudio,
        'outputPath': outputPath,
      });

      if (result['success'] == true) {
        _isRecording = true;
        _currentRecordingPath = result['outputPath'];

        return ToolExecutionResult.success({
          'action': 'start_recording',
          'recording': true,
          'output_path': _currentRecordingPath,
          'duration': duration,
          'frame_rate': frameRate,
          'quality': quality,
          'include_audio': includeAudio,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        return ToolExecutionResult.failure('Failed to start recording: ${result['error']}');
      }
    } catch (e) {
      return ToolExecutionResult.failure('Start recording failed: $e');
    }
  }

  Future<ToolExecutionResult> _stopRecording() async {
    if (!_isRecording) {
      return ToolExecutionResult.failure('No recording in progress');
    }

    try {
      final result = await _platform.invokeMethod('stopRecording');

      if (result['success'] == true) {
        _isRecording = false;
        final recordingPath = result['outputPath'] ?? _currentRecordingPath;
        final duration = result['duration'] as double?;
        final fileSize = result['fileSize'] as int?;

        return ToolExecutionResult.success({
          'action': 'stop_recording',
          'recording': false,
          'output_path': recordingPath,
          'duration_seconds': duration,
          'file_size_bytes': fileSize,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        return ToolExecutionResult.failure('Failed to stop recording: ${result['error']}');
      }
    } catch (e) {
      _isRecording = false;
      return ToolExecutionResult.failure('Stop recording failed: $e');
    }
  }

  Future<ToolExecutionResult> _takeScreenshot(String? outputPath) async {
    try {
      final result = await _platform.invokeMethod('takeScreenshot', {
        'outputPath': outputPath,
      });

      if (result['success'] == true) {
        final screenshotPath = result['outputPath'];
        final timestamp = result['timestamp'];

        return ToolExecutionResult.success({
          'action': 'take_screenshot',
          'screenshot_path': screenshotPath,
          'timestamp': timestamp,
          'file_size': result['fileSize'],
        });
      } else {
        return ToolExecutionResult.failure('Failed to take screenshot: ${result['error']}');
      }
    } catch (e) {
      return ToolExecutionResult.failure('Take screenshot failed: $e');
    }
  }

  Future<ToolExecutionResult> _analyzeRecording(String? recordingPath, String? analysisPrompt) async {
    if (recordingPath == null) {
      return ToolExecutionResult.failure('Recording path is required');
    }

    try {
      if (vlm == null) {
        return ToolExecutionResult.failure('VLM is required for recording analysis');
      }

      // Extract key frames from the recording
      final framesResult = await _extractFrames(recordingPath, 2.0); // Every 2 seconds
      if (!framesResult.success) {
        return framesResult;
      }

      final frames = framesResult.data['frames'] as List;
      final analysisResults = <Map<String, dynamic>>[];

      final prompt = analysisPrompt ?? '''
      Analyze this screen recording frame. Identify:
      1. What app or interface is shown
      2. User interactions (taps, swipes, typing)
      3. Changes in the UI
      4. Any error states or loading indicators
      5. Overall workflow or task being performed

      Describe what's happening in this frame and any significant changes from previous frames.
      ''';

      for (int i = 0; i < frames.length; i++) {
        final frame = frames[i];
        final framePath = frame['path'] as String;
        final timestamp = frame['timestamp'] as double;

        try {
          final analysis = await vlm!.analyzeImage(framePath, prompt: prompt);

          analysisResults.add({
            'frame_index': i,
            'timestamp': timestamp,
            'frame_path': framePath,
            'analysis': analysis,
          });
        } catch (e) {
          analysisResults.add({
            'frame_index': i,
            'timestamp': timestamp,
            'frame_path': framePath,
            'error': 'Analysis failed: $e',
          });
        }
      }

      // Generate overall workflow summary
      final workflowSummary = await _generateWorkflowSummary(analysisResults);

      return ToolExecutionResult.success({
        'action': 'analyze_recording',
        'recording_path': recordingPath,
        'total_frames': frames.length,
        'frame_analyses': analysisResults,
        'workflow_summary': workflowSummary,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Analyze recording failed: $e');
    }
  }

  Future<ToolExecutionResult> _extractFrames(String? recordingPath, double? frameInterval) async {
    if (recordingPath == null) {
      return ToolExecutionResult.failure('Recording path is required');
    }

    try {
      final result = await _platform.invokeMethod('extractFrames', {
        'recordingPath': recordingPath,
        'frameInterval': frameInterval ?? 1.0,
      });

      if (result['success'] == true) {
        final frames = result['frames'] as List;

        return ToolExecutionResult.success({
          'action': 'extract_frames',
          'recording_path': recordingPath,
          'frames': frames,
          'frame_count': frames.length,
          'frame_interval': frameInterval,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        return ToolExecutionResult.failure('Failed to extract frames: ${result['error']}');
      }
    } catch (e) {
      return ToolExecutionResult.failure('Extract frames failed: $e');
    }
  }

  Future<ToolExecutionResult> _startContinuousAnalysis(Map<String, dynamic> parameters) async {
    try {
      final interval = parameters['interval'] as int? ?? 5; // seconds
      final analysisPrompt = parameters['analysis_prompt'] as String?;

      final result = await _platform.invokeMethod('startContinuousAnalysis', {
        'interval': interval,
        'analysisPrompt': analysisPrompt,
      });

      return ToolExecutionResult.success({
        'action': 'start_continuous_analysis',
        'interval_seconds': interval,
        'analysis_prompt': analysisPrompt,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Start continuous analysis failed: $e');
    }
  }

  Future<ToolExecutionResult> _stopContinuousAnalysis() async {
    try {
      final result = await _platform.invokeMethod('stopContinuousAnalysis');

      return ToolExecutionResult.success({
        'action': 'stop_continuous_analysis',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Stop continuous analysis failed: $e');
    }
  }

  Future<String> _generateWorkflowSummary(List<Map<String, dynamic>> frameAnalyses) async {
    if (vlm == null) {
      return 'VLM not available for workflow summary';
    }

    try {
      final analysisText = frameAnalyses
          .map((frame) => 'Frame ${frame['frame_index']} (${frame['timestamp']}s): ${frame['analysis']}')
          .join('\n\n');

      final summaryPrompt = '''
      Based on these frame-by-frame analyses of a screen recording, provide a comprehensive workflow summary:

      $analysisText

      Generate a summary that includes:
      1. Overall task or workflow that was performed
      2. Key steps in chronological order
      3. Apps or interfaces that were used
      4. Any errors or issues encountered
      5. Success indicators or completion status
      6. Recommendations for automation or improvement

      Keep the summary concise but comprehensive.
      ''';

      return await vlm!.generateResponse(summaryPrompt);
    } catch (e) {
      return 'Failed to generate workflow summary: $e';
    }
  }

  Future<ToolExecutionResult> recordAndAnalyzeWorkflow(
    int durationSeconds,
    String workflowDescription,
  ) async {
    try {
      // Start recording
      final startResult = await _startRecording({
        'duration': durationSeconds,
        'quality': 'high',
        'include_audio': false,
      });

      if (!startResult.success) {
        return startResult;
      }

      // Wait for recording to complete
      await Future.delayed(Duration(seconds: durationSeconds + 1));

      // Stop recording
      final stopResult = await _stopRecording();
      if (!stopResult.success) {
        return stopResult;
      }

      final recordingPath = stopResult.data['output_path'] as String;

      // Analyze the recording
      final analysisPrompt = '''
      This recording shows a user performing the following workflow: "$workflowDescription"

      Analyze each frame to understand:
      1. How well the workflow was executed
      2. Any deviations from expected behavior
      3. Opportunities for automation
      4. UI elements that were interacted with
      5. Timing and efficiency of actions
      ''';

      final analysisResult = await _analyzeRecording(recordingPath, analysisPrompt);

      return ToolExecutionResult.success({
        'workflow_description': workflowDescription,
        'recording_path': recordingPath,
        'duration_seconds': durationSeconds,
        'analysis': analysisResult.data,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Record and analyze workflow failed: $e');
    }
  }

  Future<ToolExecutionResult> compareScreenshots(String screenshot1, String screenshot2) async {
    if (vlm == null) {
      return ToolExecutionResult.failure('VLM is required for screenshot comparison');
    }

    try {
      final analysis1 = await vlm!.describeImage(screenshot1);
      final analysis2 = await vlm!.describeImage(screenshot2);

      final comparisonPrompt = '''
      Compare these two screenshots:

      Screenshot 1: $analysis1
      Screenshot 2: $analysis2

      Identify:
      1. What changed between the screenshots
      2. New UI elements that appeared
      3. Elements that disappeared
      4. State changes (loading, errors, success)
      5. User actions that might have caused the changes
      ''';

      final comparison = await vlm!.generateResponse(comparisonPrompt);

      return ToolExecutionResult.success({
        'action': 'compare_screenshots',
        'screenshot1': screenshot1,
        'screenshot2': screenshot2,
        'analysis1': analysis1,
        'analysis2': analysis2,
        'comparison': comparison,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Compare screenshots failed: $e');
    }
  }

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<bool> hasPermissions() async {
    try {
      final result = await _platform.invokeMethod('hasPermissions');
      return result['hasPermissions'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> requestPermissions() async {
    try {
      await _platform.invokeMethod('requestPermissions');
    } catch (e) {
      throw Exception('Failed to request screen recording permissions: $e');
    }
  }

  Future<Map<String, dynamic>> getRecordingSettings() async {
    try {
      final result = await _platform.invokeMethod('getRecordingSettings');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {
        'supported_qualities': ['low', 'medium', 'high'],
        'max_duration': 3600,
        'supported_formats': ['mp4'],
        'error': e.toString(),
      };
    }
  }
}