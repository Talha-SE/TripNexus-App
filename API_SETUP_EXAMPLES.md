# API Configuration Examples

This document provides example configurations and common patterns for setting up the TripNexus APIs.

## 📝 Configuration File Location

File: `lib/config/app_config.dart`

## 1️⃣ MongoDB Atlas Configuration

### Example Connection String
```dart
static const String mongoDbConnectionString = 
  'mongodb+srv://tripnexus_user:MySecurePassword123@cluster0.abc123.mongodb.net/?retryWrites=true&w=majority';
```

### Connection String Format
```
mongodb+srv://[username]:[password]@[cluster-url]/[database-name]?retryWrites=true&w=majority
```

### Common MongoDB Atlas Errors

**Error: "Authentication failed"**
```dart
// Solution: Check username and password
// Make sure there are no special characters that need encoding
// Example: If password is "Pass@123", encode @ as %40
static const String mongoDbConnectionString = 
  'mongodb+srv://user:Pass%40123@cluster0.abc123.mongodb.net/?retryWrites=true&w=majority';
```

**Error: "IP not whitelisted"**
```dart
// Solution: In MongoDB Atlas dashboard:
// 1. Go to Network Access
// 2. Click "Add IP Address"
// 3. Add 0.0.0.0/0 (for development) or your specific IP
```

### Database Collections Setup

After connecting, create these collections in MongoDB Atlas:
- `users` - User accounts and profiles
- `trips` - Trip planning data
- `advisors` - Advisor profiles and services
- `bookings` - Booking records
- `packages` - Travel packages offered by advisors

## 2️⃣ Mistral AI Configuration

### Example Configuration
```dart
static const String mistralApiKey = 'sk_test_1234567890abcdefghijklmnopqrstuvwxyz';
static const String mistralBaseUrl = 'https://api.mistral.ai/v1';
static const String mistralModel = 'mistral-small-latest';
```

### Supported Models
- `mistral-small-latest` - Recommended, supports vision
- `mistral-medium-latest` - More powerful, higher cost
- `mistral-large-latest` - Most capable, highest cost

### Testing Mistral API

You can test your API key using curl:
```bash
curl https://api.mistral.ai/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "model": "mistral-small-latest",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### Mistral API Usage Examples

**1. Travel Recommendations**
```dart
final mistral = MistralService.getInstance();
final result = await mistral.getTripRecommendations(
  destination: 'Paris, France',
  interests: 'Art, Museums, Food',
  duration: 5,
  budget: '\$2000',
);

print(result['message']); // AI-generated recommendations
```

**2. Landmark Recognition**
```dart
// First, get image as base64
final imageBytes = await imageFile.readAsBytes();
final base64Image = base64Encode(imageBytes);

// Then analyze with Mistral
final result = await mistral.analyzeLandmarkImage(base64Image);
print(result['analysis']); // Landmark information
```

**3. Eco-Friendly Recommendations**
```dart
final ecoTips = await mistral.getEcoFriendlyRecommendations('Bali, Indonesia');
print(ecoTips['message']); // Sustainable travel options
```

### Mistral API Rate Limits (Check current limits on dashboard)
- Free tier: Limited requests per month
- Pay-as-you-go: Based on tokens used
- Monitor usage in Mistral dashboard

## 3️⃣ OpenWeatherMap Configuration

### Example Configuration
```dart
static const String weatherApiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
static const String weatherBaseUrl = 'https://api.openweathermap.org/data/2.5';
```

### Testing Weather API

Test in browser or curl:
```
https://api.openweathermap.org/data/2.5/weather?q=London&appid=YOUR_API_KEY&units=metric
```

Expected response:
```json
{
  "weather": [{"description": "clear sky"}],
  "main": {
    "temp": 15.5,
    "humidity": 65
  },
  "name": "London"
}
```

### Weather API Usage Examples

**1. Current Weather**
```dart
final weather = WeatherService.getInstance();
final current = await weather.getCurrentWeather('Tokyo');

if (current['success']) {
  print('Temperature: ${current['temperature']}°C');
  print('Conditions: ${current['description']}');
  print('Humidity: ${current['humidity']}%');
}
```

**2. 5-Day Forecast**
```dart
final forecast = await weather.getForecast('New York', days: 5);

if (forecast['success']) {
  for (var day in forecast['forecast']) {
    print('${day['dateTime']}: ${day['temperature']}°C');
  }
}
```

**3. Weather Icon**
```dart
final iconUrl = weather.getWeatherIconUrl(current['icon']);
// Use in Image.network(iconUrl)
```

### Weather API Rate Limits
- Free tier: 60 calls/minute, 1,000,000 calls/month
- Includes: Current weather, 5-day forecast
- Does NOT include: Hourly forecast (paid only)

## 🔒 Security Best Practices

### DO ✅
```dart
// 1. Use environment-specific configurations
class AppConfig {
  static const String environment = String.fromEnvironment('ENV', defaultValue: 'dev');
  
  static String get mongoDbConnectionString {
    return environment == 'prod' 
      ? 'mongodb+srv://prod_connection...'
      : 'mongodb+srv://dev_connection...';
  }
}

// 2. Validate API responses
if (result['success'] && result['data'] != null) {
  // Use data
} else {
  // Handle error
}

// 3. Add timeout to HTTP requests
final response = await http.get(url).timeout(
  const Duration(seconds: 10),
  onTimeout: () => throw TimeoutException('Request timed out'),
);
```

### DON'T ❌
```dart
// 1. Don't hardcode sensitive data in code
// BAD:
const password = "MyPassword123";

// 2. Don't commit API keys to version control
// Add to .gitignore:
# lib/config/app_config.dart

// 3. Don't ignore errors
try {
  await someApiCall();
} catch (e) {
  // DON'T just print, handle properly
}
```

## 🧪 Testing API Connections

### Quick Test Function

Add to your app for testing (remove in production):

```dart
// lib/utils/api_test.dart
class APITester {
  static Future<void> testAllAPIs() async {
    print('Testing APIs...\n');
    
    // Test MongoDB
    try {
      final mongo = await MongoDBService.getInstance();
      print('✓ MongoDB: ${mongo.isConnected ? "Connected" : "Failed"}');
    } catch (e) {
      print('✗ MongoDB Error: $e');
    }
    
    // Test Mistral AI
    try {
      final mistral = MistralService.getInstance();
      final result = await mistral.sendChatMessage('Hello');
      print('✓ Mistral AI: ${result['success'] ? "Working" : "Failed"}');
    } catch (e) {
      print('✗ Mistral AI Error: $e');
    }
    
    // Test Weather API
    try {
      final weather = WeatherService.getInstance();
      final result = await weather.getCurrentWeather('London');
      print('✓ Weather API: ${result['success'] ? "Working" : "Failed"}');
    } catch (e) {
      print('✗ Weather API Error: $e');
    }
  }
}

// Call from main.dart or a test screen:
await APITester.testAllAPIs();
```

## 📊 Monitoring API Usage

### Track API Calls
```dart
class APIMetrics {
  static int mistralCalls = 0;
  static int weatherCalls = 0;
  static int mongoCalls = 0;
  
  static void logMistralCall() {
    mistralCalls++;
    print('Mistral API calls today: $mistralCalls');
  }
  
  static void reset() {
    mistralCalls = 0;
    weatherCalls = 0;
    mongoCalls = 0;
  }
}

// Use in services
await mistral.sendChatMessage(message);
APIMetrics.logMistralCall();
```

## 🌍 Example: Complete User Journey

### 1. User Registration
```dart
// User signs up
final authService = await AuthService.getInstance();
final result = await authService.register(
  email: 'tourist@example.com',
  password: 'SecurePass123',
  fullName: 'John Doe',
  phoneNumber: '+1234567890',
  role: UserRole.tourist,
);

// Data stored in MongoDB 'users' collection
```

### 2. Planning a Trip
```dart
// Get AI recommendations
final mistral = MistralService.getInstance();
final recommendations = await mistral.getTripRecommendations(
  destination: 'Paris',
  interests: 'Art, History',
  duration: 5,
);

// Check weather
final weather = WeatherService.getInstance();
final forecast = await weather.getForecast('Paris', days: 5);

// Save trip to MongoDB
final trip = TripModel(
  userId: currentUser.id!,
  title: 'Paris Adventure',
  destination: 'Paris, France',
  startDate: DateTime.now().add(Duration(days: 30)),
  endDate: DateTime.now().add(Duration(days: 35)),
  aiRecommendations: recommendations['message'],
  weatherInfo: jsonEncode(forecast),
);

final tripCollection = mongoService.getTripsCollection();
await tripCollection.insertOne(trip.toJson());
```

### 3. Landmark Recognition
```dart
// User takes photo of Eiffel Tower
final imageFile = await ImagePicker().pickImage(source: ImageSource.camera);
final bytes = await imageFile!.readAsBytes();
final base64Image = base64Encode(bytes);

// Analyze with Mistral AI
final result = await mistral.analyzeLandmarkImage(base64Image);

// Display result
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Landmark Identified'),
    content: Text(result['analysis']),
  ),
);
```

## ❗ Troubleshooting

### MongoDB Issues

**Can't connect:**
1. Check connection string format
2. Verify username/password
3. Whitelist IP in Atlas
4. Check internet connection

**Slow queries:**
1. Add indexes to collections
2. Limit query results
3. Use projection to select specific fields

### Mistral AI Issues

**401 Unauthorized:**
- API key incorrect or expired
- Check for extra spaces in key

**Rate limit exceeded:**
- Wait before retrying
- Implement request queuing
- Upgrade plan if needed

**Response too slow:**
- Reduce max_tokens
- Use faster model
- Implement caching

### Weather API Issues

**API key not working immediately:**
- Wait 10-120 minutes after creation
- Check activation email

**City not found:**
- Use proper city name format
- Try "City,CountryCode" (e.g., "Paris,FR")

**Rate limit:**
- Free tier: 60 calls/minute
- Implement caching
- Use forecast instead of multiple current weather calls

## 📚 Additional Resources

### MongoDB
- [Connection String Format](https://docs.mongodb.com/manual/reference/connection-string/)
- [Atlas Documentation](https://docs.atlas.mongodb.com/)

### Mistral AI
- [API Documentation](https://docs.mistral.ai/api/)
- [Model Comparison](https://docs.mistral.ai/getting-started/models/)

### OpenWeatherMap
- [API Documentation](https://openweathermap.org/api)
- [Weather Conditions](https://openweathermap.org/weather-conditions)

---

## ✅ Final Checklist

Before running the app:

- [ ] MongoDB Atlas cluster created
- [ ] Database user created with read/write permissions
- [ ] IP address whitelisted (0.0.0.0/0 for dev)
- [ ] MongoDB connection string updated in app_config.dart
- [ ] Mistral AI account created
- [ ] Mistral API key generated
- [ ] Mistral API key updated in app_config.dart
- [ ] OpenWeatherMap account created
- [ ] Weather API key generated and activated
- [ ] Weather API key updated in app_config.dart
- [ ] All API keys tested
- [ ] No special characters issues in connection strings

Run `flutter analyze` to check for configuration errors!
