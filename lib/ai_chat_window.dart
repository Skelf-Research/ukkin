import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'model_download_service.dart';
import 'package:sqflite/sqflite.dart';
import 'web_view_model.dart';
import 'llm_service.dart';
import 'package:fllama/fllama.dart';

class AIChatWindow extends StatefulWidget {
  final List<WebViewModel> tabs;
  final ModelDownloadService downloadService;
  final Database database;
  final String? initialContext;

  AIChatWindow({
    required this.tabs,
    required this.downloadService,
    required this.database,
    this.initialContext,
  });

  @override
  _AIChatWindowState createState() => _AIChatWindowState();
}

class _AIChatWindowState extends State<AIChatWindow> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final String _searxngInstance = 'https://ai-tools-dev.ukkinai.com/searxng';
  LLMService? _llmService;
  bool _isProcessing = false;
  String _selectedModel = 'Online (OpenAI)';  // Default to online model
  bool _isLocalModelAvailable = false;

  @override
  void initState() {
    super.initState();
    _llmService = widget.downloadService.llmService;
    _isLocalModelAvailable = _llmService != null;
    if (_isLocalModelAvailable) {
      _selectedModel = 'Local';
    }
    _initializeChat();
  }

  void _initializeChat() {
    if (widget.initialContext != null) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Hello! I'm your AI assistant. I've analyzed the content of your current tab. How can I help you with it?",
          isUser: false,
        ));
      });
    }
  }

Future<String> _retrieveRelevantContext(String query) async {

    String tabContent = widget.initialContext ?? "";
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

      tabContent += "\n\n" + rows.take(3).map((r) => "${r['url']}: ${r['content']}").join("\n\n");
    } catch (e) {
      print('Error in BM25 search: $e');
      tabContent += "\nError retrieving context from open tabs.";
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
    
    return "Context from current tab and open tabs:\n$tabContent\n\nSearch results:\n$searchContent";
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _isProcessing) return;

    final userMessage = _messageController.text;
    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _isProcessing = true;
    });

    String relevantContext = await _retrieveRelevantContext(userMessage);

    List<Message> chatHistory = _messages.map((msg) => 
      Message(msg.isUser ? Role.user : Role.assistant, msg.text)
    ).toList();

    chatHistory.insert(0, Message(Role.system, 'You are a helpful AI assistant integrated into a web browser. Use the following context to answer the user\'s question: $relevantContext'));

    try {
      String response;
      if (_selectedModel == 'Local' && _llmService != null) {
        response = await _llmService!.generateResponse(chatHistory);
      } else {
        response = await _generateOpenAIResponse(chatHistory);
      }
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
      });
    } catch (e) {
      print('Error generating response: $e');
      setState(() {
        _messages.add(ChatMessage(text: "I'm sorry, I encountered an error while processing your request.", isUser: false));
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }

    _messageController.clear();
    _scrollToBottom();
  }

  Future<String> _generateOpenAIResponse(List<Message> chatHistory) async {
    final apiKey = 'OPENAI_API_KEY';  // Replace with your actual API key
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',  // or your preferred model
        'messages': chatHistory.map((msg) => {
          'role': msg.role.toString().split('.').last,
          'content': msg.text,
        }).toList(),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to generate response from OpenAI');
    }
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
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Chat'),
        actions: [
          if (_isLocalModelAvailable)
            DropdownButton<String>(
              value: _selectedModel,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedModel = newValue!;
                });
              },
              items: <String>['Local', 'Online (OpenAI)']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            )
          else
            Center(child: Text('Online (OpenAI)', style: TextStyle(color: Colors.white))),
        ],
      ),
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
                    enabled: !_isProcessing,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _sendMessage,
                  child: _isProcessing
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.send),
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