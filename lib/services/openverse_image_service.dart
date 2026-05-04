import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenverseImageAsset {
  final String title;
  final String thumbnailUrl;
  final String imageUrl;
  final String sourceUrl;
  final String creator;
  final String license;
  final String attribution;

  const OpenverseImageAsset({
    required this.title,
    required this.thumbnailUrl,
    required this.imageUrl,
    required this.sourceUrl,
    required this.creator,
    required this.license,
    required this.attribution,
  });
}

class OpenverseImageService {
  static const String _baseUrl = 'https://api.openverse.org/v1/images/';
  static final Map<String, OpenverseImageAsset?> _cache = {};

  Future<OpenverseImageAsset?> searchBestImage(
    String query, {
    String? fallbackQuery,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return null;

    final cacheKey = normalizedQuery.toLowerCase();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    final asset = await _fetchBestMatch(normalizedQuery);
    if (asset != null) {
      _cache[cacheKey] = asset;
      return asset;
    }

    if (fallbackQuery != null && fallbackQuery.trim().isNotEmpty) {
      final fallbackKey = fallbackQuery.trim().toLowerCase();
      if (_cache.containsKey(fallbackKey)) {
        return _cache[fallbackKey];
      }

      final fallbackAsset = await _fetchBestMatch(fallbackQuery.trim());
      _cache[fallbackKey] = fallbackAsset;
      return fallbackAsset;
    }

    _cache[cacheKey] = null;
    return null;
  }

  Future<OpenverseImageAsset?> _fetchBestMatch(String query) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?q=${Uri.encodeComponent(query)}&page_size=5&license_type=all-cc&filter_dead=true&category=photograph&size=large',
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>?) ?? const [];
      if (results.isEmpty) return null;

      for (final result in results) {
        if (result is! Map<String, dynamic>) continue;

        final thumbnailUrl = (result['thumbnail'] ?? '').toString().trim();
        final imageUrl = (result['url'] ?? '').toString().trim();
        final sourceUrl = (result['foreign_landing_url'] ?? '').toString().trim();

        if (thumbnailUrl.isEmpty && imageUrl.isEmpty) continue;

        return OpenverseImageAsset(
          title: (result['title'] ?? query).toString().trim(),
          thumbnailUrl: thumbnailUrl.isNotEmpty ? thumbnailUrl : imageUrl,
          imageUrl: imageUrl.isNotEmpty ? imageUrl : thumbnailUrl,
          sourceUrl: sourceUrl,
          creator: (result['creator'] ?? 'Openverse source').toString().trim(),
          license: (result['license'] ?? 'open license').toString().trim(),
          attribution: (result['attribution'] ?? '').toString().trim(),
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}