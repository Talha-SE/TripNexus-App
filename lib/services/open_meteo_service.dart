import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
    int forecastDays = 7,
  }) async {
    try {
      final safeForecastDays = forecastDays.clamp(1, 16);
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
          'sunrise',
          'sunset',
        ].join(','),
        'timezone': 'auto',
        'forecast_days': safeForecastDays.toString(),
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

  Future<Map<String, dynamic>> getTripPlanningInsights({
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final cities = await searchCities(destination);
      if (cities.isEmpty) {
        return {
          'success': false,
          'message': 'Could not resolve the destination for weather insights.',
        };
      }

      final location = cities.first;
      final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
      final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
      final tripDays = normalizedEnd.difference(normalizedStart).inDays + 1;
      final requestedForecastDays = tripDays.clamp(1, 16);
      final forecastResult = await getWeatherForecast(
        latitude: location.latitude,
        longitude: location.longitude,
        forecastDays: requestedForecastDays,
      );

      if (!forecastResult['success']) {
        return forecastResult;
      }

      final forecastData = forecastResult['data'] as Map<String, dynamic>;
      final daily = (forecastData['daily'] as Map<String, dynamic>?) ?? {};
      final dates = List<String>.from(daily['time'] ?? const []);
      final weatherCodes = List<dynamic>.from(daily['weather_code'] ?? const []);
      final maxTemps = List<dynamic>.from(daily['temperature_2m_max'] ?? const []);
      final minTemps = List<dynamic>.from(daily['temperature_2m_min'] ?? const []);
      final precipitation = List<dynamic>.from(daily['precipitation_sum'] ?? const []);
      final windSpeeds = List<dynamic>.from(daily['wind_speed_10m_max'] ?? const []);

      final dateFormat = DateFormat('yyyy-MM-dd');
      final prettyDateFormat = DateFormat('EEE, MMM d');

      final weatherLines = <String>[];
      final indexedWeatherLines = <String>[];
      final coveredDates = <String>{};
      var tripDayIndex = 1;

      for (var index = 0; index < dates.length; index++) {
        final date = DateTime.tryParse(dates[index]);
        if (date == null) continue;

        final currentDate = DateTime(date.year, date.month, date.day);
        if (currentDate.isBefore(normalizedStart) || currentDate.isAfter(normalizedEnd)) {
          continue;
        }

        coveredDates.add(dateFormat.format(currentDate));

        final weatherCode = index < weatherCodes.length ? (weatherCodes[index] as num).toInt() : 0;
        final maxTemp = index < maxTemps.length ? (maxTemps[index] as num).toDouble() : 0;
        final minTemp = index < minTemps.length ? (minTemps[index] as num).toDouble() : 0;
        final rain = index < precipitation.length ? (precipitation[index] as num).toDouble() : 0;
        final wind = index < windSpeeds.length ? (windSpeeds[index] as num).toDouble() : 0;

        weatherLines.add(
          '- ${prettyDateFormat.format(currentDate)}: ${getWeatherDescription(weatherCode)} with ${maxTemp.toStringAsFixed(0)}°/${minTemp.toStringAsFixed(0)}°C, rain ${rain.toStringAsFixed(1)} mm, wind ${wind.toStringAsFixed(0)} km/h.',
        );
        indexedWeatherLines.add(
          '- Day $tripDayIndex (${prettyDateFormat.format(currentDate)}): ${getWeatherDescription(weatherCode)}, ${maxTemp.toStringAsFixed(0)}°/${minTemp.toStringAsFixed(0)}°C, rain ${rain.toStringAsFixed(1)} mm, wind ${wind.toStringAsFixed(0)} km/h.',
        );
        tripDayIndex++;
      }

      final holidayMap = await _getPublicHolidaysForRange(
        location.countryCode,
        normalizedStart.year,
        normalizedEnd.year,
      );

      final holidayLines = <String>[];
      if (holidayMap.isNotEmpty) {
        for (final entry in holidayMap) {
          final holidayDate = DateTime.tryParse(entry['date'] as String? ?? '');
          if (holidayDate == null) continue;

          final currentDate = DateTime(holidayDate.year, holidayDate.month, holidayDate.day);
          if (currentDate.isBefore(normalizedStart) || currentDate.isAfter(normalizedEnd)) {
            continue;
          }

          holidayLines.add(
            '- ${prettyDateFormat.format(currentDate)}: ${entry['localName']} (${entry['name']})',
          );
        }
      }

      final forecastCoverageNote = coveredDates.length == (normalizedEnd.difference(normalizedStart).inDays + 1)
          ? 'Weather coverage is available for the selected dates.'
          : 'Weather coverage is available for ${coveredDates.length} day(s) of the selected range; dates beyond the forecast window should be treated as guidance only.';

      return {
        'success': true,
        'locationName': location.displayName,
        'countryCode': location.countryCode,
        'weatherContext': weatherLines.isEmpty
            ? 'No weather forecast could be matched to the selected dates.'
            : weatherLines.join('\n'),
        'weatherByTripDay': indexedWeatherLines.isEmpty
            ? 'No day-by-day weather mapping is available for the selected dates.'
            : indexedWeatherLines.join('\n'),
        'calendarContext': holidayLines.isEmpty
            ? 'No public holidays or special calendar days fall within the selected range.'
            : holidayLines.join('\n'),
        'coverageNote': forecastCoverageNote,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to gather trip planning insights: $e',
      };
    }
  }

  Future<List<Map<String, dynamic>>> _getPublicHolidaysForRange(
    String? countryCode,
    int startYear,
    int endYear,
  ) async {
    if (countryCode == null || countryCode.trim().isEmpty) {
      return const [];
    }

    final holidays = <Map<String, dynamic>>[];

    for (var year = startYear; year <= endYear; year++) {
      try {
        final uri = Uri.parse('https://date.nager.at/api/v3/PublicHolidays/$year/$countryCode');
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is List) {
            holidays.addAll(decoded.whereType<Map>().map((item) => item.cast<String, dynamic>()));
          }
        }
      } catch (_) {
        continue;
      }
    }

    return holidays;
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
  final String? countryCode;
  final String? admin1; // State/Province
  final int? population;

  CityLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country,
    this.countryCode,
    this.admin1,
    this.population,
  });

  factory CityLocation.fromJson(Map<String, dynamic> json) {
    return CityLocation(
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      country: json['country'] as String?,
      countryCode: json['country_code'] as String?,
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
