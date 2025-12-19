import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class WeatherService {
  static WeatherService? _instance;

  WeatherService._();

  static WeatherService getInstance() {
    _instance ??= WeatherService._();
    return _instance!;
  }

  Future<Map<String, dynamic>> getCurrentWeather(String city) async {
    try {
      final url = Uri.parse(
        '${AppConfig.weatherBaseUrl}/weather?q=$city&appid=${AppConfig.weatherApiKey}&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'temperature': data['main']['temp'],
          'feelsLike': data['main']['feels_like'],
          'humidity': data['main']['humidity'],
          'description': data['weather'][0]['description'],
          'icon': data['weather'][0]['icon'],
          'windSpeed': data['wind']['speed'],
          'city': data['name'],
          'country': data['sys']['country'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch weather data',
        };
      }
    } catch (e) {
      print('Weather API Error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getForecast(String city, {int days = 5}) async {
    try {
      final url = Uri.parse(
        '${AppConfig.weatherBaseUrl}/forecast?q=$city&appid=${AppConfig.weatherApiKey}&units=metric&cnt=${days * 8}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> forecastList = data['list'];
        
        final forecast = forecastList.map((item) {
          return {
            'dateTime': item['dt_txt'],
            'temperature': item['main']['temp'],
            'description': item['weather'][0]['description'],
            'icon': item['weather'][0]['icon'],
            'humidity': item['main']['humidity'],
            'windSpeed': item['wind']['speed'],
          };
        }).toList();

        return {
          'success': true,
          'city': data['city']['name'],
          'country': data['city']['country'],
          'forecast': forecast,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch forecast data',
        };
      }
    } catch (e) {
      print('Weather Forecast Error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getWeatherAlerts(String city) async {
    try {
      // Get coordinates first
      final currentWeather = await getCurrentWeather(city);
      if (!currentWeather['success']) {
        return currentWeather;
      }

      // In a real implementation, you would use the coordinates to fetch alerts
      // For now, we'll return a mock response
      return {
        'success': true,
        'alerts': [],
        'message': 'No active weather alerts',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch weather alerts: $e',
      };
    }
  }

  String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  String getWeatherRecommendation(double temperature, String description) {
    if (temperature > 30) {
      return 'Hot weather! Stay hydrated and wear sunscreen.';
    } else if (temperature > 20) {
      return 'Pleasant weather! Perfect for outdoor activities.';
    } else if (temperature > 10) {
      return 'Mild weather. Bring a light jacket.';
    } else {
      return 'Cold weather. Dress warmly!';
    }
  }
}
