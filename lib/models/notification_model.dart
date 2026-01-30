enum NotificationType {
  weather,
  news,
  trip,
  advisor,
  system,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.data,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.index,
        'timestamp': timestamp.toIso8601String(),
        'data': data,
        'isRead': isRead ? 1 : 0,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'],
        title: json['title'],
        body: json['body'],
        type: NotificationType.values[json['type']],
        timestamp: DateTime.parse(json['timestamp']),
        data: json['data'],
        isRead: json['isRead'] == 1,
      );
}
