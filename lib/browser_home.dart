import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'model_download_service.dart';
import 'ai_chat_window.dart';
import 'package:sqflite/sqflite.dart';
import 'web_view_model.dart';

class BrowserHome extends StatefulWidget {
  final ModelDownloadService downloadService;
  final Database database;

  BrowserHome({required this.downloadService, required this.database});

  @override
  _BrowserHomeState createState() => _BrowserHomeState();
}

class _BrowserHomeState extends State<BrowserHome> {
  List<WebViewModel> _tabs = [];
  int _currentTabIndex = 0;
  bool _isIncognito = false;
  bool _isLowDataMode = false;
  TextEditingController _addressBarController = TextEditingController();
  List<String> _urlSuggestions = [];

  @override
  void initState() {
    super.initState();
    _addNewTab();
    widget.downloadService.checkModelStatus().then((isReady) {
      if (!isReady) {
        widget.downloadService.downloadModel();
      }
    });
  }

  @override
  void dispose() {
    _addressBarController.dispose();
    for (var tab in _tabs) {
      tab.cleanup();
    }
    _tabs.clear();
    super.dispose();
  }

  void _addNewTab({String url = 'https://www.google.com'}) {
    setState(() {
      _tabs.add(WebViewModel(url: url, isIncognito: _isIncognito));
      _currentTabIndex = _tabs.length - 1;
    });
  }

  void _closeTab(int index) {
    setState(() {
      _tabs.removeAt(index);
      if (_currentTabIndex >= _tabs.length) {
        _currentTabIndex = _tabs.length - 1;
      }
    });
  }

  void _switchToTab(int index) {
    setState(() {
      _currentTabIndex = index;
    });
    Navigator.pop(context); // Close the tab gallery
  }

  void _toggleIncognito() {
    setState(() {
      _isIncognito = !_isIncognito;
    });
  }

  void _toggleLowDataMode() {
    setState(() {
      _isLowDataMode = !_isLowDataMode;
    });
  }

  void _openAIChat() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: AIChatWindow(tabs: _tabs, downloadService: widget.downloadService, database: widget.database),
        ),
      ),
    );
  }

  void _openTabNavigator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              color: Colors.white,
              child: Column(
                children: [
                  AppBar(
                    title: Text('Tabs'),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          _addNewTab();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _tabs.length,
                      itemBuilder: (BuildContext context, int index) {
                        return GestureDetector(
                          onTap: () => _switchToTab(index),
                          child: Card(
                            child: Column(
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Image.network(
                                        _tabs[index].thumbnailUrl ?? 'https://via.placeholder.com/150?text=No+Thumbnail',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: IconButton(
                                          icon: Icon(Icons.close),
                                          onPressed: () => _closeTab(index),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    _tabs[index].title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addToHistory(String url, String title) async {
    if (!_isIncognito) {
      await widget.database.insert(
        'history',
        {
          'url': url,
          'title': title,
          'timestamp': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  void _loadUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (Uri.tryParse(url)?.hasScheme ?? false) {
        url = 'http://$url';
      } else {
        url = 'https://duckduckgo.com/?q=${Uri.encodeComponent(url)}';
      }
    }
    _tabs[_currentTabIndex].controller.loadRequest(Uri.parse(url));
  }

  void _updateUrlSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _urlSuggestions = [];
      });
      return;
    }

    final results = await widget.database.query(
      'history',
      where: 'url LIKE ? OR title LIKE ?',
      whereArgs: ['%$input%', '%$input%'],
      orderBy: 'timestamp DESC',
      limit: 5,
    );

    setState(() {
      _urlSuggestions = results.map((e) => e['url'] as String).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppBar(
            title: Text('Ukkin'),
            actions: [
              IconButton(
                icon: Icon(Icons.tab),
                onPressed: _openTabNavigator,
              ),
              IconButton(
                icon: Icon(_isIncognito ? Icons.visibility_off : Icons.visibility),
                onPressed: _toggleIncognito,
              ),
              IconButton(
                icon: Icon(_isLowDataMode ? Icons.data_saver_on : Icons.data_saver_off),
                onPressed: _toggleLowDataMode,
              ),
              IconButton(
                icon: Icon(Icons.chat),
                onPressed: _openAIChat,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    if (_tabs.isNotEmpty) {
                      _tabs[_currentTabIndex].controller.goBack();
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () {
                    if (_tabs.isNotEmpty) {
                      _tabs[_currentTabIndex].controller.goForward();
                    }
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _addressBarController,
                    decoration: InputDecoration(
                      hintText: 'Enter URL or search terms',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _updateUrlSuggestions,
                    onSubmitted: (value) {
                      _loadUrl(value);
                      _addressBarController.clear();
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    if (_tabs.isNotEmpty) {
                      _tabs[_currentTabIndex].controller.reload();
                    }
                  },
                ),
              ],
            ),
          ),
          if (_urlSuggestions.isNotEmpty)
            Container(
              height: 200,
              child: ListView.builder(
                itemCount: _urlSuggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_urlSuggestions[index]),
                    onTap: () {
                      _loadUrl(_urlSuggestions[index]);
                      _addressBarController.clear();
                      setState(() {
                        _urlSuggestions = [];
                      });
                    },
                  );
                },
              ),
            ),
          Expanded(
            child: _tabs.isNotEmpty
                ? WebViewWidget(controller: _tabs[_currentTabIndex].controller)
                : Center(child: Text('No tabs open')),
          ),
        ],
      ),
    );
  }
}

class BrowserWebView extends StatefulWidget {
  final WebViewModel tab;
  final bool isLowDataMode;
  final Function(String, String) onPageFinished;

  BrowserWebView({
    required this.tab,
    required this.isLowDataMode,
    required this.onPageFinished,
  });

  @override
  _BrowserWebViewState createState() => _BrowserWebViewState();
}

class _BrowserWebViewState extends State<BrowserWebView> {
  @override
  void initState() {
    super.initState();
    widget.tab.controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            final title = await widget.tab.controller.getTitle() ?? 'No Title';
            widget.tab.title = title;
            widget.onPageFinished(url, title);
            // Set a placeholder thumbnail URL
            widget.tab.thumbnailUrl = 'https://via.placeholder.com/150?text=${Uri.encodeComponent(title)}';
            setState(() {}); // Trigger a rebuild to update the UI
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.tab.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: widget.tab.controller);
  }
}