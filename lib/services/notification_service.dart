import 'dart:convert';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import '../models/notification_model.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService getInstance() {
    _instance ??= NotificationService._();
    return _instance!;
  }

  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final List<AppNotification> _notificationList = [];
  final List<Function(AppNotification)> _listeners = [];
  AppNotification? _pendingNotification;

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Check if app was launched from notification
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await _notifications.getNotificationAppLaunchDetails();
    
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payload = notificationAppLaunchDetails?.notificationResponse?.payload;
      if (payload != null) {
        final data = jsonDecode(payload);
        _pendingNotification = AppNotification.fromJson(data);
      }
    }

    await _requestPermissions();
    await _loadNotifications();
  }

  AppNotification? get pendingNotification => _pendingNotification;

  void clearPendingNotification() {
    _pendingNotification = null;
  }

  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      final data = jsonDecode(payload);
      final notification = AppNotification.fromJson(data);
      _notifyListeners(notification);
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if notifications are enabled
    final pushEnabled = prefs.getBool('push_notifications') ?? true;
    if (!pushEnabled) return;

    // Check specific notification type settings
    if (type == NotificationType.weather) {
      final weatherEnabled = prefs.getBool('weather_notifications') ?? true;
      if (!weatherEnabled) return;
    } else if (type == NotificationType.news) {
      final newsEnabled = prefs.getBool('news_notifications') ?? true;
      if (!newsEnabled) return;
    }

    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );

    _notificationList.insert(0, notification);
    await _saveNotifications();
    _notifyListeners(notification);

    // Show system notification
    await _showSystemNotification(notification);
  }

  Future<void> _showSystemNotification(AppNotification notification) async {
    final androidDetails = AndroidNotificationDetails(
      notification.type.name,
      notification.type.name.toUpperCase(),
      channelDescription: 'Notifications for ${notification.type.name}',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(notification.body),
      icon: _getIconForType(notification.type),
      color: Color(0xFF2196F3), // Primary brand color
      ledColor: Color(0xFF2196F3),
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(notification.toJson()),
    );
  }

  String _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.weather:
        return '@drawable/ic_weather';
      case NotificationType.news:
        return '@drawable/ic_news';
      case NotificationType.trip:
        return '@drawable/ic_trip';
      case NotificationType.advisor:
        return '@drawable/ic_advisor';
      default:
        return '@mipmap/ic_launcher';
    }
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = _notificationList
        .take(50) // Keep only last 50 notifications
        .map((n) => jsonEncode(n.toJson()))
        .toList();
    await prefs.setStringList('app_notifications', notificationsJson);
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getStringList('app_notifications') ?? [];
    _notificationList.clear();
    _notificationList.addAll(
      notificationsJson
          .map((json) => AppNotification.fromJson(jsonDecode(json)))
          .toList(),
    );
  }

  void addListener(Function(AppNotification) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(AppNotification) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(AppNotification notification) {
    for (var listener in _listeners) {
      listener(notification);
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notificationList.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notificationList[index].isRead = true;
      await _saveNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    for (var notification in _notificationList) {
      notification.isRead = true;
    }
    await _saveNotifications();
  }

  Future<void> deleteNotification(String id) async {
    _notificationList.removeWhere((n) => n.id == id);
    await _saveNotifications();
  }

  Future<void> clearAll() async {
    _notificationList.clear();
    await _saveNotifications();
    await _notifications.cancelAll();
  }

  List<AppNotification> get notifications =>
      List.unmodifiable(_notificationList);

  int get unreadCount =>
      _notificationList.where((n) => !n.isRead).length;
}
