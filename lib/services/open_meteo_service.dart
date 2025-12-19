import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenMeteoService {
  static OpenMeteoService? _instance;
  
  OpenMeteoService._();
  
  static OpenMeteoService getInstance() {
    _instance ??= OpenMeteoService._();
    return _instance!;
  }

  // Geocoding API to search cities
  Future<List<CityLocation>> searchCities(String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      final url = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(query)}&count=10&language=en&format=json'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['results'] != null) {
          return (data['results'] as List)
              .map((item) => CityLocation.fromJson(item))
              .toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error searching cities: $e');
      return [];
    }
  }

  // Get weather forecast
  Future<Map<String, dynamic>> getWeatherForecast({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final params = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': [
          'temperature_2m',
          'precipitation',
          'weather_code',
          'apparent_temperature',
          'is_day',
          'wind_speed_10m',
          'wind_direction_10m',
          'rain',
          'snowfall',
          'showers',
          'relative_humidity_2m',
          'cloud_cover',
          'uv_index',
        ].join(','),
        'hourly': [
          'temperature_2m',
          'relative_humidity_2m',
          'apparent_temperature',
          'precipitation_probability',
          'precipitation',
          'showers',
          'cloud_cover',
          'snowfall',
          'snow_depth',
          'rain',
          'wind_speed_10m',
          'wind_direction_10m',
          'uv_index',
          'weather_code',
        ].join(','),
        'daily': [
          'temperature_2m_max',
          'temperature_2m_min',
          'precipitation_sum',
          'precipitation_probability_max',
          'wind_speed_10m_max',
          'uv_index_max',
          'weather_code',
        ].join(','),
        'timezone': 'auto',
        'forecast_days': '7',
      };

      final uri = Uri.https(
        'api.open-meteo.com',
        '/v1/forecast',
        params,
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch weather data: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching weather: $e',
      };
    }
  }

  String getWeatherDescription(int weatherCode) {
    switch (weatherCode) {
      case 0:
        return 'Clear sky';
      case 1:
      case 2:
      case 3:
        return 'Partly cloudy';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 56:
      case 57:
        return 'Freezing drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 66:
      case 67:
        return 'Freezing rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 77:
        return 'Snow grains';
      case 80:
      case 81:
      case 82:
        return 'Rain showers';
      case 85:
      case 86:
        return 'Snow showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with hail';
      default:
        return 'Unknown';
    }
  }

  String getWeatherIcon(int weatherCode, bool isDay) {
    if (weatherCode == 0) {
      return isDay ? '☀️' : '🌙';
    } else if (weatherCode >= 1 && weatherCode <= 3) {
      return isDay ? '⛅' : '☁️';
    } else if (weatherCode >= 45 && weatherCode <= 48) {
      return '🌫️';
    } else if (weatherCode >= 51 && weatherCode <= 57) {
      return '🌦️';
    } else if (weatherCode >= 61 && weatherCode <= 67) {
      return '🌧️';
    } else if (weatherCode >= 71 && weatherCode <= 77) {
      return '❄️';
    } else if (weatherCode >= 80 && weatherCode <= 86) {
      return '🌨️';
    } else if (weatherCode >= 95) {
      return '⛈️';
    }
    return '🌤️';
  }

  String getWindDirection(int degrees) {
    if (degrees >= 337.5 || degrees < 22.5) return 'N';
    if (degrees >= 22.5 && degrees < 67.5) return 'NE';
    if (degrees >= 67.5 && degrees < 112.5) return 'E';
    if (degrees >= 112.5 && degrees < 157.5) return 'SE';
    if (degrees >= 157.5 && degrees < 202.5) return 'S';
    if (degrees >= 202.5 && degrees < 247.5) return 'SW';
    if (degrees >= 247.5 && degrees < 292.5) return 'W';
    if (degrees >= 292.5 && degrees < 337.5) return 'NW';
    return 'N';
  }
}

class CityLocation {
  final String name;
  final double latitude;
  final double longitude;
  final String? country;
  final String? admin1; // State/Province
  final int? population;

  CityLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country,
    this.admin1,
    this.population,
  });

  factory CityLocation.fromJson(Map<String, dynamic> json) {
    return CityLocation(
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      country: json['country'] as String?,
      admin1: json['admin1'] as String?,
      population: json['population'] as int?,
    );
  }

  String get displayName {
    final parts = <String>[name];
    if (admin1 != null) parts.add(admin1!);
    if (country != null) parts.add(country!);
    return parts.join(', ');
  }
}
