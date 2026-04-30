class AppConfig {
  // MongoDB Configuration
  // MongoDB Atlas connection (user-provided)
  static const String mongoDbConnectionString =
      'mongodb://rtalhaonline_db_user:VFQm6yonboNbUmNB@ac-afcbzu8-shard-00-00.weglya2.mongodb.net:27017,ac-afcbzu8-shard-00-01.weglya2.mongodb.net:27017,ac-afcbzu8-shard-00-02.weglya2.mongodb.net:27017/tripnexus_db?authSource=admin&replicaSet=atlas-54r3ls-shard-0&tls=true';
  static const String databaseName = 'tripnexus_db';

  // Collections
  static const String usersCollection = 'users';
  static const String tripsCollection = 'trips';
  static const String advisorsCollection = 'advisors';
  static const String bookingsCollection = 'bookings';
  static const String packagesCollection = 'packages';
  static const String blockchainReviewsCollection = 'blockchain_reviews';

  // Mistral AI Configuration
  static const String mistralApiKey = 'm4zp8gXR8wPsxhNmOmjbW07kAEYAaYhR';
  static const String mistralBaseUrl = 'https://api.mistral.ai/v1';
  static const String mistralLandmarkModel =
      'mistral-medium-latest'; // For image analysis (vision model)
  static const String mistralTripPlanModel =
      'mistral-small-latest'; // Optimized for low latency and high throughput

  // Weather API Configuration
  static const String weatherApiKey = 'YOUR_WEATHER_API_KEY';
  static const String weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';

  // App Theme Colors
  static const int primaryColor = 0xFF2196F3;
  static const int secondaryColor = 0xFFFF9800;
  static const int accentColor = 0xFF4CAF50;
  static const int errorColor = 0xFFF44336;
  static const int backgroundColor = 0xFFF5F5F5;
  static const int cardColor = 0xFFFFFFFF;
  static const int textPrimaryColor = 0xFF212121;
  static const int textSecondaryColor = 0xFF757575;
}
