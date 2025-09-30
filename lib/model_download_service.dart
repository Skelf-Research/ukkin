import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'llm_service.dart';
import 'config.dart';
import 'exceptions.dart';

class ModelDownloadService with ChangeNotifier {
  String _downloadStatus = '';
  String get downloadStatus => _downloadStatus;

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  bool _isModelReady = false;
  bool get isModelReady => _isModelReady;

  LLMService? _llmService;
  LLMService? get llmService => _llmService;

  String getHuggingFaceUrl(
      {required String repoId, required String filename, String? revision, String? subfolder}) {
    const String defaultEndpoint = 'https://huggingface.co';
    const String defaultRevision = 'main';
    final String encodedRevision = Uri.encodeComponent(revision ?? defaultRevision);
    final String encodedFilename = Uri.encodeComponent(filename);
    final String? encodedSubfolder = subfolder != null ? Uri.encodeComponent(subfolder) : null;
    final String fullPath = encodedSubfolder != null ? '$encodedSubfolder/$encodedFilename' : encodedFilename;
    final String url = '$defaultEndpoint/$repoId/resolve/$encodedRevision/$fullPath';
    return url;
  }

  Future<String> getModelPath() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return '${appDocDir.path}/${ModelConfig.filename}';
  }

  Future<bool> isModelDownloaded() async {
    try {
      final modelPath = await getModelPath();
      return await File(modelPath).exists();
    } catch (e) {
      return false;
    }
  }

  Future<void> downloadModel() async {
    if (_isDownloading) return;
    _isDownloading = true;
    _updateStatus('Starting download...');

    try {
      final modelPath = await getModelPath();

      if (await isModelDownloaded()) {
        _updateStatus('Model already downloaded');
        await _initializeLLMService(modelPath);
        return;
      }

      final url = getHuggingFaceUrl(repoId: ModelConfig.repoId, filename: ModelConfig.filename);

      _updateStatus('Downloading model...');
      final response = await http.get(Uri.parse(url)).timeout(Duration(minutes: 5));

      if (response.statusCode != 200) {
        throw ModelDownloadException('Failed to download model: ${response.statusCode}');
      }

      final file = File(modelPath);
      final totalBytes = int.parse(response.headers['content-length'] ?? '0');
      int receivedBytes = 0;

      final sink = file.openWrite();
      final bytes = response.bodyBytes;
      final chunkSize = 1024 * 8; // 8KB chunks

      for (var i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        final chunk = bytes.sublist(i, end);
        sink.add(chunk);
        receivedBytes += chunk.length;
        final progress = (receivedBytes / totalBytes * 100).toStringAsFixed(2);
        _updateStatus('Downloading: $progress%');
      }

      await sink.close();
      _updateStatus('Download completed');
      await _initializeLLMService(modelPath);
    } on SocketException {
      _updateStatus('Error: No internet connection');
    } on FileSystemException {
      _updateStatus('Error: Not enough storage space');
    } on TimeoutException {
      _updateStatus('Error: Download timed out');
    } on ModelDownloadException catch (e) {
      _updateStatus('Error: $e');
    } catch (e) {
      _updateStatus('An unknown error occurred: $e');
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  Future<void> _initializeLLMService(String modelPath) async {
    try {
      _llmService = LLMService();
      await _llmService!.initialize(modelPath: modelPath);
      _updateStatus('LLM Service initialized');
      _isModelReady = true;
    } catch (e) {
      _updateStatus('Error initializing LLM Service: $e');
      _llmService = null;
      _isModelReady = false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> checkModelStatus() async {
    if (await isModelDownloaded()) {
      final modelPath = await getModelPath();
      if (_llmService == null) {
        await _initializeLLMService(modelPath);
      }
      _isModelReady = _llmService != null;
    } else {
      _isModelReady = false;
    }
    notifyListeners();
    return _isModelReady;
  }

  void _updateStatus(String status) {
    _downloadStatus = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _llmService?.dispose();
    super.dispose();
  }
}
