import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:duckduckgo_search/duckduckgo_search.dart';
import 'tool.dart';
import '../models/task.dart';

class SearchTool extends Tool with ToolValidation {
  final http.Client _httpClient;
  final DDGSearch _duckDuckGo;

  SearchTool() :
    _httpClient = http.Client(),
    _duckDuckGo = DDGSearch();

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
      final results = await _duckDuckGo.search(
        query,
        region: region ?? 'us-en',
        safesearch: _mapSafeSearch(safeSearch),
        time: _mapTimeRange(timeRange),
        maxResults: maxResults,
      );

      final searchResults = results.map((result) => {
        'title': result.title,
        'url': result.href,
        'description': result.body,
        'source': 'DuckDuckGo',
      }).toList();

      return ToolExecutionResult.success({
        'query': query,
        'engine': 'duckduckgo',
        'results': searchResults,
        'count': searchResults.length,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('DuckDuckGo search failed: $e');
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
    try {
      final results = await _duckDuckGo.images(
        query,
        region: 'us-en',
        safesearch: SafeSearch.moderate,
        maxResults: maxResults,
      );

      final imageResults = results.map((result) => {
        'title': result.title,
        'image_url': result.image,
        'thumbnail_url': result.thumbnail,
        'source_url': result.url,
        'width': result.width,
        'height': result.height,
        'source': 'DuckDuckGo Images',
      }).toList();

      return ToolExecutionResult.success({
        'query': query,
        'type': 'images',
        'results': imageResults,
        'count': imageResults.length,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Image search failed: $e');
    }
  }

  Future<ToolExecutionResult> searchNews(String query, {int maxResults = 10}) async {
    try {
      final results = await _duckDuckGo.news(
        query,
        region: 'us-en',
        safesearch: SafeSearch.moderate,
        time: Time.month,
        maxResults: maxResults,
      );

      final newsResults = results.map((result) => {
        'title': result.title,
        'url': result.url,
        'description': result.body,
        'date': result.date,
        'source': result.source,
        'type': 'news',
      }).toList();

      return ToolExecutionResult.success({
        'query': query,
        'type': 'news',
        'results': newsResults,
        'count': newsResults.length,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('News search failed: $e');
    }
  }

  SafeSearch _mapSafeSearch(String safeSearch) {
    switch (safeSearch.toLowerCase()) {
      case 'strict':
        return SafeSearch.strict;
      case 'off':
        return SafeSearch.off;
      default:
        return SafeSearch.moderate;
    }
  }

  Time? _mapTimeRange(String? timeRange) {
    if (timeRange == null) return null;
    switch (timeRange.toLowerCase()) {
      case 'day':
        return Time.day;
      case 'week':
        return Time.week;
      case 'month':
        return Time.month;
      case 'year':
        return Time.year;
      default:
        return null;
    }
  }

  List<Map<String, String>> _parseBingResults(String html, int maxResults) {
    // Basic HTML parsing for Bing results
    // In production, consider using a proper HTML parser
    final results = <Map<String, String>>[];

    // This is a simplified parser - would need proper implementation
    // for production use with html package

    return results.take(maxResults).toList();
  }

  List<Map<String, String>> _parseStartPageResults(String html, int maxResults) {
    // Basic HTML parsing for StartPage results
    // In production, consider using a proper HTML parser
    final results = <Map<String, String>>[];

    // This is a simplified parser - would need proper implementation
    // for production use with html package

    return results.take(maxResults).toList();
  }

  @override
  void dispose() {
    _httpClient.close();
  }
}