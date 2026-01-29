enum NewsType {
  general,
  warning,
  event,
}

class NewsItem {
  final String title;
  final String link;
  final String pubDate;
  final String description;
  final String source;
  final NewsType type;

  NewsItem({
    required this.title,
    required this.link,
    required this.pubDate,
    required this.description,
    required this.source,
    required this.type,
  });

  factory NewsItem.fromXml(Map<String, String> map, NewsType type) {
    return NewsItem(
      title: map['title'] ?? '',
      link: map['link'] ?? '',
      pubDate: map['pubDate'] ?? '',
      description: map['description'] ?? '',
      source: map['source'] ?? '',
      type: type,
    );
  }
}
