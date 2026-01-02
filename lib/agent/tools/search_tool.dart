import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'tool.dart';
import '../models/task.dart';

/// Safe search levels for web searches
enum SafeSearch { strict, moderate, off }

/// Time range filter for searches
enum Time { day, week, month, year }

class SearchTool extends Tool with ToolValidation {
  final http.Client _httpClient;

  SearchTool() : _httpClient = http.Client();

  @override
  String get name => 'search';

  @override
  String get description => 'Search the web for information using various search engines';

  @override
  Map<String, String> get parameters => {
        'query': 'Search query',
        'engine': 'Search engine: duckduckgo, bing, startpage (default: duckduckgo)',
        'max_results': 'Maximum number of results (default: 10)',
        'region': 'Search region (optional)',
        'time_range': 'Time range: day, week, month, year (optional)',
        'safe_search': 'Safe search: strict, moderate, off (default: moderate)',
      };

  @override
  bool canHandle(Task task) {
    return task.type == 'search' || task.type == 'web_search';
  }

  @override
  Future<bool> validate(Map<String, dynamic> parameters) async {
    return validateRequired(parameters, ['query']);
  }

  @override
  Future<dynamic> execute(Map<String, dynamic> parameters) async {
    if (!await validate(parameters)) {
      throw Exception('Invalid parameters for search tool');
    }

    final query = parameters['query'] as String;
    final engine = parameters['engine'] as String? ?? 'duckduckgo';
    final maxResults = int.tryParse(parameters['max_results']?.toString() ?? '10') ?? 10;
    final region = parameters['region'] as String?;
    final timeRange = parameters['time_range'] as String?;
    final safeSearch = parameters['safe_search'] as String? ?? 'moderate';

    try {
      switch (engine.toLowerCase()) {
        case 'duckduckgo':
          return await _searchDuckDuckGo(query, maxResults, region, timeRange, safeSearch);
        case 'bing':
          return await _searchBing(query, maxResults, region, timeRange, safeSearch);
        case 'startpage':
          return await _searchStartPage(query, maxResults, region, timeRange, safeSearch);
        default:
          return await _searchDuckDuckGo(query, maxResults, region, timeRange, safeSearch);
      }
    } catch (e) {
      return ToolExecutionResult.failure('Search failed: $e');
    }
  }

  Future<ToolExecutionResult> _searchDuckDuckGo(
    String query,
    int maxResults,
    String? region,
    String? timeRange,
    String safeSearch,
  ) async {
    try {
      // Use DuckDuckGo HTML search (privacy-respecting, no API key needed)
      final url = Uri.parse('https://html.duckduckgo.com/html/').replace(
        queryParameters: {
          'q': query,
          'kl': region ?? 'us-en',
          'kp': _mapSafeSearchParam(safeSearch),
          if (timeRange != null) 'df': _mapTimeRangeParam(timeRange),
        },
      );

      final response = await _httpClient.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; UkkinBot/1.0)',
      });

      if (response.statusCode == 200) {
        final searchResults = _parseDuckDuckGoResults(response.body, maxResults);
        return ToolExecutionResult.success({
          'query': query,
          'engine': 'duckduckgo',
          'results': searchResults,
          'count': searchResults.length,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        return ToolExecutionResult.failure('DuckDuckGo search HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      return ToolExecutionResult.failure('DuckDuckGo search failed: $e');
    }
  }

  List<Map<String, String>> _parseDuckDuckGoResults(String html, int maxResults) {
    final results = <Map<String, String>>[];
    final document = html_parser.parse(html);

    // Parse DuckDuckGo HTML results
    final resultElements = document.querySelectorAll('.result');
    for (final element in resultElements) {
      if (results.length >= maxResults) break;

      final titleElement = element.querySelector('.result__title a');
      final snippetElement = element.querySelector('.result__snippet');

      if (titleElement != null) {
        results.add({
          'title': titleElement.text.trim(),
          'url': titleElement.attributes['href'] ?? '',
          'description': snippetElement?.text.trim() ?? '',
          'source': 'DuckDuckGo',
        });
      }
    }
    return results;
  }

  String _mapSafeSearchParam(String safeSearch) {
    switch (safeSearch.toLowerCase()) {
      case 'strict': return '1';
      case 'off': return '-1';
      default: return '-2'; // moderate
    }
  }

  String? _mapTimeRangeParam(String? timeRange) {
    if (timeRange == null) return null;
    switch (timeRange.toLowerCase()) {
      case 'day': return 'd';
      case 'week': return 'w';
      case 'month': return 'm';
      case 'year': return 'y';
      default: return null;
    }
  }

  Future<ToolExecutionResult> _searchBing(
    String query,
    int maxResults,
    String? region,
    String? timeRange,
    String safeSearch,
  ) async {
    try {
      // Note: This would require Bing Search API key in a real implementation
      final url = 'https://www.bing.com/search?q=${Uri.encodeComponent(query)}';
      final response = await _httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Parse Bing search results from HTML
        final results = _parseBingResults(response.body, maxResults);

        return ToolExecutionResult.success({
          'query': query,
          'engine': 'bing',
          'results': results,
          'count': results.length,
          'timestamp': DateTime.now().toIso8601String(),
          'note': 'Parsed from Bing web interface - consider using Bing Search API for production',
        });
      } else {
        return ToolExecutionResult.failure('Bing search HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      return ToolExecutionResult.failure('Bing search failed: $e');
    }
  }

  Future<ToolExecutionResult> _searchStartPage(
    String query,
    int maxResults,
    String? region,
    String? timeRange,
    String safeSearch,
  ) async {
    try {
      final url = 'https://www.startpage.com/sp/search?query=${Uri.encodeComponent(query)}';
      final response = await _httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final results = _parseStartPageResults(response.body, maxResults);

        return ToolExecutionResult.success({
          'query': query,
          'engine': 'startpage',
          'results': results,
          'count': results.length,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        return ToolExecutionResult.failure('StartPage search HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      return ToolExecutionResult.failure('StartPage search failed: $e');
    }
  }

  Future<ToolExecutionResult> searchImages(String query, {int maxResults = 10}) async {
    // Image search requires JavaScript rendering - return placeholder
    // In production, consider using a headless browser or dedicated image search API
    return ToolExecutionResult.success({
      'query': query,
      'type': 'images',
      'results': <Map<String, dynamic>>[],
      'count': 0,
      'timestamp': DateTime.now().toIso8601String(),
      'note': 'Image search requires JavaScript rendering - use web browser tool for images',
    });
  }

  Future<ToolExecutionResult> searchNews(String query, {int maxResults = 10}) async {
    // Use DuckDuckGo news search via HTTP
    try {
      final url = Uri.parse('https://html.duckduckgo.com/html/').replace(
        queryParameters: {
          'q': '$query news',
          'kl': 'us-en',
          'df': 'm', // last month
        },
      );

      final response = await _httpClient.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; UkkinBot/1.0)',
      });

      if (response.statusCode == 200) {
        final newsResults = _parseDuckDuckGoResults(response.body, maxResults)
            .map((r) => {...r, 'type': 'news'})
            .toList();

        return ToolExecutionResult.success({
          'query': query,
          'type': 'news',
          'results': newsResults,
          'count': newsResults.length,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        return ToolExecutionResult.failure('News search HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      return ToolExecutionResult.failure('News search failed: $e');
    }
  }

  List<Map<String, String>> _parseBingResults(String html, int maxResults) {
    final results = <Map<String, String>>[];
    final document = html_parser.parse(html);

    // Parse Bing search results
    final resultElements = document.querySelectorAll('.b_algo');
    for (final element in resultElements) {
      if (results.length >= maxResults) break;

      final titleElement = element.querySelector('h2 a');
      final snippetElement = element.querySelector('.b_caption p');

      if (titleElement != null) {
        results.add({
          'title': titleElement.text.trim(),
          'url': titleElement.attributes['href'] ?? '',
          'description': snippetElement?.text.trim() ?? '',
          'source': 'Bing',
        });
      }
    }
    return results;
  }

  List<Map<String, String>> _parseStartPageResults(String html, int maxResults) {
    final results = <Map<String, String>>[];
    final document = html_parser.parse(html);

    // Parse StartPage search results
    final resultElements = document.querySelectorAll('.w-gl__result');
    for (final element in resultElements) {
      if (results.length >= maxResults) break;

      final titleElement = element.querySelector('.w-gl__result-title');
      final snippetElement = element.querySelector('.w-gl__description');
      final linkElement = element.querySelector('a');

      if (titleElement != null) {
        results.add({
          'title': titleElement.text.trim(),
          'url': linkElement?.attributes['href'] ?? '',
          'description': snippetElement?.text.trim() ?? '',
          'source': 'StartPage',
        });
      }
    }
    return results;
  }

  @override
  void dispose() {
    _httpClient.close();
  }
}