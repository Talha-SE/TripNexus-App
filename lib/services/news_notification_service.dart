import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import '../models/notification_model.dart';

class NewsNotificationService {
  static NewsNotificationService? _instance;
  static NewsNotificationService getInstance() {
    _instance ??= NewsNotificationService._();
    return _instance!;
  }

  NewsNotificationService._();

  final _notificationService = NotificationService.getInstance();
  Timer? _updateTimer;
  List<String> _savedQueries = [];
  Set<String> _seenNewsIds = {};

  Future<void> initialize() async {
    await _loadSavedQueries();
    await _loadSeenNews();
    _startPeriodicUpdates();
  }

  Future<void> _loadSavedQueries() async {
    final prefs = await SharedPreferences.getInstance();
    _savedQueries = prefs.getStringList('saved_news_queries') ?? [];
    
    // Add default queries if empty
    if (_savedQueries.isEmpty) {
      _savedQueries = ['Travel Safety', 'Travel News'];
      await _saveSavedQueries();
    }
  }

  Future<void> _saveSavedQueries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_news_queries', _savedQueries);
  }

  Future<void> _loadSeenNews() async {
    final prefs = await SharedPreferences.getInstance();
    final seenList = prefs.getStringList('seen_news_ids') ?? [];
    _seenNewsIds = seenList.toSet();
  }

  Future<void> _saveSeenNews() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('seen_news_ids', _seenNewsIds.toList());
  }

  Future<void> addNewsQuery(String query) async {
    if (!_savedQueries.contains(query)) {
      _savedQueries.add(query);
      await _saveSavedQueries();
      await _checkNewsForQuery(query);
    }
  }

  void _startPeriodicUpdates() {
    _updateTimer?.cancel();
    // Check for news every 2 hours
    _updateTimer = Timer.periodic(const Duration(hours: 2), (timer) {
      _checkAllNews();
    });
    // Initial check
    _checkAllNews();
  }

  Future<void> _checkAllNews() async {
    final prefs = await SharedPreferences.getInstance();
    final newsEnabled = prefs.getBool('news_notifications') ?? true;
    
    if (!newsEnabled) return;

    for (var query in _savedQueries) {
      await _checkNewsForQuery(query);
    }
  }

  Future<void> _checkNewsForQuery(String query) async {
    try {
      final searchQuery = '$query travel destination';
      final response = await http.get(
        Uri.parse('https://news.google.com/rss/search?q=${Uri.encodeComponent(searchQuery)}&hl=en-US&gl=US&ceid=US:en'),
      );

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        // Get the latest 3 news items
        final latestItems = items.take(3);

        for (var item in latestItems) {
          final title = item.getElement('title')?.innerText ?? '';
          final link = item.getElement('link')?.innerText ?? '';
          final description = item.getElement('description')?.innerText ?? '';
          final source = item.getElement('source')?.innerText ?? 'Google News';
          
          // Create a unique ID for this news item
          final newsId = '${title}_$link'.hashCode.toString();

          // Check if we've already notified about this news
          if (!_seenNewsIds.contains(newsId)) {
            _seenNewsIds.add(newsId);
            await _saveSeenNews();

            // Send notification
            await _notificationService.showNotification(
              title: '🗞️ $source',
              body: title,
              type: NotificationType.news,
              data: {
                'link': link,
                'description': description,
                'source': source,
                'query': query,
              },
            );
          }
        }
      }
    } catch (e) {
      print('Error checking news for $query: $e');
    }
  }

  Future<void> manualCheck() async {
    await _checkAllNews();
  }

  void dispose() {
    _updateTimer?.cancel();
  }
}
