class AppConfig {
  // MongoDB Configuration
  // MongoDB Atlas connection (user-provided)
  static const String mongoDbConnectionString = 'mongodb+srv://rtalhaonline_db_user:VFQm6yonboNbUmNB@cluster0.weglya2.mongodb.net/?appName=Cluster0';
  static const String databaseName = 'tripnexus_db';
  
  // Collections
  static const String usersCollection = 'users';
  static const String tripsCollection = 'trips';
  static const String advisorsCollection = 'advisors';
  static const String bookingsCollection = 'bookings';
  static const String packagesCollection = 'packages';
  
  // Mistral AI Configuration
  static const String mistralApiKey = 'm4zp8gXR8wPsxhNmOmjbW07kAEYAaYhR';
  static const String mistralBaseUrl = 'https://api.mistral.ai/v1';
  static const String mistralLandmarkModel = 'pixtral-12b-2409'; // For image analysis (vision model)
  static const String mistralTripPlanModel = 'mistral-large-latest'; // For trip planning
  
  // Weather API Configuration
  static const String weatherApiKey = 'YOUR_WEATHER_API_KEY';
  static const String weatherBaseUrl = 'https://api.openweathermap.org/data/2.5';
  
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
