import 'package:flutter/material.dart';
import 'package:fllama/fllama.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'model_download_service.dart';
import 'package:sqflite/sqflite.dart';
import 'web_view_model.dart';  // Add this import
import 'dart:io';


class AIChatWindow extends StatefulWidget {
  final List<WebViewModel> tabs;
  final ModelDownloadService downloadService;
  final Database database;

  AIChatWindow({required this.tabs, required this.downloadService, required this.database});

  @override
  _AIChatWindowState createState() => _AIChatWindowState();
}

class _AIChatWindowState extends State<AIChatWindow> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  String? _modelPath;
  String? _mmprojPath;
  String _downloadStatus = '';
  final String _searxngInstance = 'https://ai-tools-dev.ukkinai.com/searxng'; // Replace with your SearXNG instance URL

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _listenToDownloadStatus();
  }

  void _listenToDownloadStatus() {
    widget.downloadService.statusStream.listen((status) {
      setState(() {
        _downloadStatus = status;
      });
    });
  }

Future<void> _initializeModel() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    _modelPath = '${appDocDir.path}/stablelm-zephyr-3b.Q4_K_M.gguf';
    _mmprojPath = '${appDocDir.path}/stable-lm-3b.mmproj';
    
    bool modelExists = await File(_modelPath!).exists();
    bool mmprojExists = await File(_mmprojPath!).exists();

    if (!modelExists || !mmprojExists) {
      print('Model or mmproj file not found. Initiating download...');
      widget.downloadService.downloadModel();
    } else if (!await widget.downloadService.checkModelStatus()) {
      print('Model status check failed. Reinitiating download...');
      widget.downloadService.downloadModel();
    } else {
      print('Model files found and status check passed.');
    }
  }

  Future<String> _retrieveRelevantContext(String query) async {
    String tabContent = "";
    String searchContent = "";

    // Implement BM25 search using SQLite
    try {
      var rows = await widget.database.query(
        'page_content',
        columns: [
          'url',
          'content',
          'bm25(page_content) as rank',
        ],
        where: 'page_content MATCH ?',
        whereArgs: [query],
      );

      rows.sort((a, b) => (b['rank'] as num).compareTo(a['rank'] as num));

      tabContent = rows.take(3).map((r) => "${r['url']}: ${r['content']}").join("\n\n");
    } catch (e) {
      print('Error in BM25 search: $e');
      tabContent = "Error retrieving context from open tabs.";
    }
    
    // Perform SearXNG search
    try {
      final response = await http.get(
        Uri.parse('$_searxngInstance/search?q=${Uri.encodeComponent(query)}&format=json')
      );

      if (response.statusCode == 200) {
        final searchResults = json.decode(response.body);
        searchContent = (searchResults['results'] as List)
          .take(3)
          .map((r) => "${r['title']}: ${r['content']}")
          .join("\n\n");
      } else {
        throw Exception('Failed to load search results');
      }
    } catch (e) {
      print('Error in SearXNG search: $e');
      searchContent = "Error retrieving search results.";
    }
    
    return "Context from open tabs:\n$tabContent\n\nSearch results:\n$searchContent";
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text;
    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
    });

    String relevantContext = await _retrieveRelevantContext(userMessage);

    List<Message> chatHistory = _messages.map((msg) => 
      Message(msg.isUser ? Role.user : Role.assistant, msg.text)
    ).toList();

    chatHistory.insert(0, Message(Role.system, 'You are a helpful AI assistant integrated into a web browser. Use the following context to answer the user\'s question: $relevantContext'));

    String latestResult = "";

    final request = OpenAiRequest(
      maxTokens: 256,
      messages: chatHistory,
      numGpuLayers: 99,
      modelPath: _modelPath!,
      mmprojPath: "",
      frequencyPenalty: 0.0,
      presencePenalty: 1.1,
      topP: 1.0,
      contextSize: 2048,
      temperature: 0.7,
      logger: (log) {
        print('[llama.cpp] $log');
      },
    );

    await fllamaChat(request, (response, done) {
      setState(() {
        latestResult = response;
        if (done) {
          _messages.add(ChatMessage(text: latestResult.trim(), isUser: false));
        }
      });
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.downloadService.isModelReady) {
      return Scaffold(
        appBar: AppBar(title: Text('AI Chat')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Downloading AI model...'),
              SizedBox(height: 10),
              Text(_downloadStatus),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('AI Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}