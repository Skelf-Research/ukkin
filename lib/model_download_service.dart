import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ModelDownloadService {
  static final ModelDownloadService _instance = ModelDownloadService._internal();
  factory ModelDownloadService() => _instance;
  ModelDownloadService._internal();

  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  bool _isModelReady = false;
  bool get isModelReady => _isModelReady;

  Future<void> downloadModel() async {
    if (_isDownloading) return;
    _isDownloading = true;

    final appDocDir = await getApplicationDocumentsDirectory();
    final modelPath = '${appDocDir.path}/stablelm-zephyr-3b.Q4_K_M.gguf';
    final mmprojPath = '${appDocDir.path}/stable-lm-3b.mmproj';

    final receivePort = ReceivePort();
    await Isolate.spawn(
      _downloadModelIsolate, 
      {
        'sendPort': receivePort.sendPort,
        'modelPath': modelPath,
        'mmprojPath': mmprojPath,
      }
    );

    receivePort.listen((message) {
      if (message is String) {
        _statusController.add(message);
        if (message == 'Download completed') {
          _isDownloading = false;
          _isModelReady = true;
          receivePort.close();
        } else if (message.startsWith('Error')) {
          _isDownloading = false;
          receivePort.close();
        }
      }
    });
  }

  Future<bool> checkModelStatus() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final modelPath = '${appDocDir.path}/stablelm-zephyr-3b.Q4_K_M.gguf';
    final mmprojPath = '${appDocDir.path}/stable-lm-3b.mmproj';

    _isModelReady = await File(modelPath).exists() && await File(mmprojPath).exists();
    return _isModelReady;
  }

  static void _downloadModelIsolate(Map<String, dynamic> args) async {
    final SendPort sendPort = args['sendPort'];
    final String modelPath = args['modelPath'];
    final String mmprojPath = args['mmprojPath'];

    try {
      await _downloadFile(
        'https://huggingface.co/telosnex/fllama/resolve/main/stablelm-zephyr-3b.Q4_K_M.gguf',
        modelPath,
        sendPort,
      );
      await _downloadFile(
        'https://huggingface.co/sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2/resolve/main/pytorch_model.bin',
        mmprojPath,
        sendPort,
      );
      sendPort.send('Download completed');
    } catch (e) {
      sendPort.send('Error during download: $e');
    }
  }

  static Future<void> _downloadFile(String url, String savePath, SendPort sendPort) async {
    final response = await http.get(Uri.parse(url));
    final file = File(savePath);
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
      sendPort.send('Downloading: $progress%');
    }

    await sink.close();
  }

  void dispose() {
    _statusController.close();
  }
}