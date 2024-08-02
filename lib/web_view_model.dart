import 'package:webview_flutter/webview_flutter.dart';

class WebViewModel {
  final String url;
  final bool isIncognito;
  String title;
  String? content;
  String? thumbnailUrl;
  late final WebViewController controller;

  WebViewModel({
    required this.url,
    required this.isIncognito,
    this.title = 'New Tab',
    this.content,
    this.thumbnailUrl,
  }) {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            title = await controller.getTitle() ?? 'No Title';
            thumbnailUrl = 'https://via.placeholder.com/150?text=${Uri.encodeComponent(title)}';
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  void cleanup() {
    // Perform any necessary cleanup for the WebViewController
    controller.removeJavaScriptChannel('Toaster');
    // Add any other cleanup operations specific to your implementation
  }
}