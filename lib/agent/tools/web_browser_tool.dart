import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'tool.dart';
import '../models/task.dart';

class WebBrowserTool extends Tool with ToolValidation {
  final WebViewController? _webViewController;
  final http.Client _httpClient;

  WebBrowserTool({WebViewController? webViewController})
      : _webViewController = webViewController,
        _httpClient = http.Client();

  @override
  String get name => 'web_browser';

  @override
  String get description => 'Navigate web pages, extract content, and interact with web elements';

  @override
  Map<String, String> get parameters => {
        'url': 'URL to navigate to',
        'action': 'Action to perform: navigate, extract_content, get_links, screenshot, click, type',
        'selector': 'CSS selector for element interaction (optional)',
        'text': 'Text to type (for type action)',
        'wait_for': 'Element to wait for before proceeding (optional)',
      };

  @override
  bool canHandle(Task task) {
    return task.type == 'web_browser' || task.type.startsWith('web_');
  }

  @override
  Future<bool> validate(Map<String, dynamic> parameters) async {
    if (!validateRequired(parameters, ['action'])) return false;

    final action = parameters['action'] as String;
    switch (action) {
      case 'navigate':
        return validateRequired(parameters, ['url']) && validateUrl(parameters['url']);
      case 'extract_content':
      case 'get_links':
      case 'screenshot':
        return true;
      case 'click':
      case 'type':
        return validateRequired(parameters, ['selector']);
      default:
        return false;
    }
  }

  @override
  Future<dynamic> execute(Map<String, dynamic> parameters) async {
    if (!await validate(parameters)) {
      throw Exception('Invalid parameters for web browser tool');
    }

    final action = parameters['action'] as String;

    try {
      switch (action) {
        case 'navigate':
          return await _navigate(parameters['url']);
        case 'extract_content':
          return await _extractContent(parameters['url']);
        case 'get_links':
          return await _getLinks(parameters['url']);
        case 'screenshot':
          return await _takeScreenshot();
        case 'click':
          return await _clickElement(parameters['selector']);
        case 'type':
          return await _typeText(parameters['selector'], parameters['text']);
        case 'search':
          return await _search(parameters['query'], parameters['search_engine'] ?? 'duckduckgo');
        default:
          throw Exception('Unknown action: $action');
      }
    } catch (e) {
      return ToolExecutionResult.failure('Web browser action failed: $e');
    }
  }

  Future<ToolExecutionResult> _navigate(String url) async {
    try {
      if (_webViewController != null) {
        await _webViewController!.loadRequest(Uri.parse(url));
        await Future.delayed(Duration(seconds: 2)); // Wait for page load
        return ToolExecutionResult.success({'url': url, 'status': 'navigated'});
      } else {
        final response = await _httpClient.get(Uri.parse(url));
        return ToolExecutionResult.success({
          'url': url,
          'status_code': response.statusCode,
          'content_length': response.body.length,
        });
      }
    } catch (e) {
      return ToolExecutionResult.failure('Navigation failed: $e');
    }
  }

  Future<ToolExecutionResult> _extractContent(String? url) async {
    try {
      String content;
      String title = '';

      if (_webViewController != null) {
        content = await _webViewController!.runJavaScriptReturningResult(
          'document.body.innerText'
        ) as String;
        title = await _webViewController!.runJavaScriptReturningResult(
          'document.title'
        ) as String;
      } else if (url != null) {
        final response = await _httpClient.get(Uri.parse(url));
        final document = html_parser.parse(response.body);
        content = document.body?.text ?? '';
        title = document.querySelector('title')?.text ?? '';
      } else {
        throw Exception('No URL provided and no active web view');
      }

      return ToolExecutionResult.success({
        'title': title,
        'content': content,
        'length': content.length,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Content extraction failed: $e');
    }
  }

  Future<ToolExecutionResult> _getLinks(String? url) async {
    try {
      List<Map<String, String>> links = [];

      if (_webViewController != null) {
        final linksJson = await _webViewController!.runJavaScriptReturningResult('''
          JSON.stringify(Array.from(document.links).map(link => ({
            text: link.textContent.trim(),
            href: link.href,
            title: link.title || ''
          })))
        ''') as String;
        final linksList = jsonDecode(linksJson) as List;
        links = linksList.map((link) => Map<String, String>.from(link)).toList();
      } else if (url != null) {
        final response = await _httpClient.get(Uri.parse(url));
        final document = html_parser.parse(response.body);
        final linkElements = document.querySelectorAll('a[href]');

        links = linkElements.map((element) => {
          'text': element.text.trim(),
          'href': element.attributes['href'] ?? '',
          'title': element.attributes['title'] ?? '',
        }).toList();
      }

      return ToolExecutionResult.success({
        'links': links,
        'count': links.length,
      });
    } catch (e) {
      return ToolExecutionResult.failure('Link extraction failed: $e');
    }
  }

  Future<ToolExecutionResult> _takeScreenshot() async {
    try {
      if (_webViewController == null) {
        return ToolExecutionResult.failure('Screenshot requires active web view');
      }

      // Note: WebView screenshot functionality would need platform-specific implementation
      return ToolExecutionResult.success({
        'message': 'Screenshot functionality requires platform-specific implementation',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Screenshot failed: $e');
    }
  }

  Future<ToolExecutionResult> _clickElement(String selector) async {
    try {
      if (_webViewController == null) {
        return ToolExecutionResult.failure('Element interaction requires active web view');
      }

      await _webViewController!.runJavaScript('''
        const element = document.querySelector('$selector');
        if (element) {
          element.click();
        } else {
          throw new Error('Element not found: $selector');
        }
      ''');

      return ToolExecutionResult.success({
        'action': 'clicked',
        'selector': selector,
      });
    } catch (e) {
      return ToolExecutionResult.failure('Click failed: $e');
    }
  }

  Future<ToolExecutionResult> _typeText(String selector, String text) async {
    try {
      if (_webViewController == null) {
        return ToolExecutionResult.failure('Element interaction requires active web view');
      }

      await _webViewController!.runJavaScript('''
        const element = document.querySelector('$selector');
        if (element) {
          element.value = '$text';
          element.dispatchEvent(new Event('input', { bubbles: true }));
        } else {
          throw new Error('Element not found: $selector');
        }
      ''');

      return ToolExecutionResult.success({
        'action': 'typed',
        'selector': selector,
        'text': text,
      });
    } catch (e) {
      return ToolExecutionResult.failure('Type failed: $e');
    }
  }

  Future<ToolExecutionResult> _search(String query, String searchEngine) async {
    try {
      String searchUrl;
      switch (searchEngine.toLowerCase()) {
        case 'duckduckgo':
          searchUrl = 'https://duckduckgo.com/?q=${Uri.encodeComponent(query)}';
          break;
        case 'bing':
          searchUrl = 'https://www.bing.com/search?q=${Uri.encodeComponent(query)}';
          break;
        case 'startpage':
          searchUrl = 'https://www.startpage.com/sp/search?query=${Uri.encodeComponent(query)}';
          break;
        default:
          searchUrl = 'https://duckduckgo.com/?q=${Uri.encodeComponent(query)}';
      }

      final navigationResult = await _navigate(searchUrl);
      if (navigationResult.success) {
        final contentResult = await _extractContent(null);
        return ToolExecutionResult.success({
          'query': query,
          'search_engine': searchEngine,
          'url': searchUrl,
          'content': contentResult.data,
        });
      } else {
        return navigationResult;
      }
    } catch (e) {
      return ToolExecutionResult.failure('Search failed: $e');
    }
  }

  Future<ToolExecutionResult> waitForElement(String selector, {Duration? timeout}) async {
    try {
      if (_webViewController == null) {
        return ToolExecutionResult.failure('Element waiting requires active web view');
      }

      final timeoutMs = (timeout ?? Duration(seconds: 10)).inMilliseconds;

      await _webViewController!.runJavaScript('''
        return new Promise((resolve, reject) => {
          const timeout = setTimeout(() => {
            reject(new Error('Timeout waiting for element: $selector'));
          }, $timeoutMs);

          const checkElement = () => {
            const element = document.querySelector('$selector');
            if (element) {
              clearTimeout(timeout);
              resolve(true);
            } else {
              setTimeout(checkElement, 100);
            }
          };

          checkElement();
        });
      ''');

      return ToolExecutionResult.success({
        'action': 'element_found',
        'selector': selector,
      });
    } catch (e) {
      return ToolExecutionResult.failure('Wait for element failed: $e');
    }
  }

  @override
  void dispose() {
    _httpClient.close();
  }
}