import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'model_download_service.dart';
import 'ai_chat_window.dart';
import 'package:sqflite/sqflite.dart';
import 'browser_state.dart';

class BrowserHome extends StatelessWidget {
  final Database database;

  BrowserHome({required this.database});

  @override
  Widget build(BuildContext context) {
    final browserState = Provider.of<BrowserState>(context);
    final addressBarController = TextEditingController(text: browserState.currentTab.url);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: addressBarController,
          decoration: InputDecoration(
            hintText: 'Search or type URL',
            border: InputBorder.none,
          ),
          onSubmitted: (value) {
            _loadUrl(browserState.currentTab.controller, value);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {},
          ),
        ],
      ),
      body: browserState.tabs.isNotEmpty
          ? WebViewWidget(controller: browserState.currentTab.controller)
          : Center(child: Text('No tabs open')),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                if (browserState.tabs.isNotEmpty) {
                  browserState.currentTab.controller.goBack();
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: () {
                if (browserState.tabs.isNotEmpty) {
                  browserState.currentTab.controller.goForward();
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                if (browserState.tabs.isNotEmpty) {
                  browserState.currentTab.controller.reload();
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.tab),
              onPressed: () => _openTabNavigator(context, browserState),
            ),
            IconButton(
              icon: Icon(Icons.chat_bubble_outline),
              onPressed: () => _openAIChat(context, browserState, database),
            ),
          ],
        ),
      ),
    );
  }

  void _loadUrl(WebViewController controller, String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('.')) {
        url = 'http://$url';
      } else {
        url = 'https://duckduckgo.com/?q=${Uri.encodeComponent(url)}';
      }
    }
    controller.loadRequest(Uri.parse(url));
  }

  void _openAIChat(BuildContext context, BrowserState browserState, Database database) async {
    String? pageContent;
    if (browserState.tabs.isNotEmpty) {
      pageContent = await browserState.currentTab.controller.runJavaScriptReturningResult('document.body.innerText') as String?;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: AIChatWindow(
            tabs: browserState.tabs,
            downloadService: Provider.of<ModelDownloadService>(context, listen: false),
            database: database,
            initialContext: pageContent,
          ),
        ),
      ),
    );
  }

  void _openTabNavigator(BuildContext context, BrowserState browserState) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          child: Column(
            children: [
              AppBar(
                title: Text('Tabs'),
                actions: [
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      browserState.addNewTab();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: browserState.tabs.length,
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      onTap: () => browserState.switchToTab(index),
                      child: Card(
                        child: Column(
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Center(child: Text(browserState.tabs[index].title.isNotEmpty ? browserState.tabs[index].title[0] : 'N')),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: Icon(Icons.close),
                                      onPressed: () => browserState.closeTab(index),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                browserState.tabs[index].title,
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
        ),
      ),
    );
  }
}
