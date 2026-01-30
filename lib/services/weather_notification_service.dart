import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'open_meteo_service.dart';
import 'notification_service.dart';
import '../models/notification_model.dart';

class WeatherNotificationService {
  static WeatherNotificationService? _instance;
  static WeatherNotificationService getInstance() {
    _instance ??= WeatherNotificationService._();
    return _instance!;
  }

  WeatherNotificationService._();

  final _meteoService = OpenMeteoService.getInstance();
  final _notificationService = NotificationService.getInstance();
  Timer? _updateTimer;
  List<SavedWeatherCity> _savedCities = [];

  Future<void> initialize() async {
    await _loadSavedCities();
    _startPeriodicUpdates();
  }

  Future<void> _loadSavedCities() async {
    final prefs = await SharedPreferences.getInstance();
    final citiesJson = prefs.getStringList('saved_weather_cities') ?? [];
    _savedCities = citiesJson
        .map((json) => SavedWeatherCity.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> addCity(CityLocation city) async {
    if (_savedCities.length >= 3) {
      _savedCities.removeAt(0); // Remove oldest
    }

    final savedCity = SavedWeatherCity(
      name: city.displayName,
      latitude: city.latitude,
      longitude: city.longitude,
      addedAt: DateTime.now(),
    );

    _savedCities.add(savedCity);
    await _saveCities();
    await _fetchWeatherForCity(savedCity);
  }

  Future<void> removeCity(int index) async {
    if (index >= 0 && index < _savedCities.length) {
      _savedCities.removeAt(index);
      await _saveCities();
    }
  }

  Future<void> _saveCities() async {
    final prefs = await SharedPreferences.getInstance();
    final citiesJson =
        _savedCities.map((city) => jsonEncode(city.toJson())).toList();
    await prefs.setStringList('saved_weather_cities', citiesJson);
  }

  List<SavedWeatherCity> get savedCities => List.unmodifiable(_savedCities);

  void _startPeriodicUpdates() {
    _updateTimer?.cancel();
    // Update every hour
    _updateTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _updateAllCities();
    });
  }

  Future<void> _updateAllCities() async {
    for (var city in _savedCities) {
      await _fetchWeatherForCity(city);
    }
  }

  Future<void> refreshCity(int index) async {
    if (index >= 0 && index < _savedCities.length) {
      await _fetchWeatherForCity(_savedCities[index]);
    }
  }

  Future<void> _fetchWeatherForCity(SavedWeatherCity city) async {
    try {
      final result = await _meteoService.getWeatherForecast(
        latitude: city.latitude,
        longitude: city.longitude,
      );

      if (result['success']) {
        city.lastWeatherData = result['data'];
        city.lastUpdated = DateTime.now();
        await _saveCities();
        
        // Check if weather notifications are enabled
        final prefs = await SharedPreferences.getInstance();
        final notificationsEnabled =
            prefs.getBool('weather_notifications') ?? true;

        if (notificationsEnabled) {
          _showWeatherNotification(city);
        }
      }
    } catch (e) {
      print('Error fetching weather for ${city.name}: $e');
    }
  }

  void _showWeatherNotification(SavedWeatherCity city) {
    if (city.lastWeatherData != null) {
      final temp = city.lastWeatherData!['current']['temperature_2m'];
      final weatherCode = city.lastWeatherData!['current']['weather_code'];
      final description = _getWeatherDescription(weatherCode);
      
      _notificationService.showNotification(
        title: '🌤️ Weather Update - ${city.name}',
        body: '$temp°C - $description',
        type: NotificationType.weather,
        data: {
          'city': city.name,
          'temperature': temp,
          'weather_code': weatherCode,
          'latitude': city.latitude,
          'longitude': city.longitude,
        },
      );
    }
  }

  String _getWeatherDescription(int code) {
    if (code == 0) return 'Clear sky';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 67) return 'Rainy';
    if (code <= 77) return 'Snowy';
    if (code <= 82) return 'Showers';
    if (code <= 86) return 'Snow showers';
    return 'Thunderstorm';
  }

  void dispose() {
    _updateTimer?.cancel();
  }
}

class SavedWeatherCity {
  final String name;
  final double latitude;
  final double longitude;
  DateTime addedAt;
  DateTime? lastUpdated;
  Map<String, dynamic>? lastWeatherData;

  SavedWeatherCity({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.addedAt,
    this.lastUpdated,
    this.lastWeatherData,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'addedAt': addedAt.toIso8601String(),
        'lastUpdated': lastUpdated?.toIso8601String(),
        'lastWeatherData': lastWeatherData,
      };

  factory SavedWeatherCity.fromJson(Map<String, dynamic> json) =>
      SavedWeatherCity(
        name: json['name'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        addedAt: DateTime.parse(json['addedAt']),
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'])
            : null,
        lastWeatherData: json['lastWeatherData'],
      );
}
