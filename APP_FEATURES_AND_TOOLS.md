# TripNexus - App Features and Tools Documentation

## 📱 Application Overview
**Name:** TripNexus  
**Version:** 1.0.0+1  
**Description:** A modern tourism application with AI-powered features for travelers and travel advisors.

---

## 🎯 Core Features

### 1. **Authentication System**
- **User Registration**
  - Tourist registration
  - Travel Advisor registration
  - Travel Agency registration
  - Form validation with email, password, phone number
  - Secure password hashing (SHA-256)
  
- **User Login**
  - Email and password authentication
  - Session persistence
  - Auto-login functionality
  - Secure token storage

- **Session Management**
  - Persistent user sessions using SharedPreferences
  - Automatic logout functionality
  - User profile data caching

### 2. **Tourist Dashboard Features**

#### Home Tab
- Welcome header with personalized greeting
- Quick action buttons for:
  - Create new trip
  - View all trips
  - Scan landmarks
  - Browse packages
  - AI trip planner
  - Saved landmarks
  - Search advisors
- AI-powered features section
- Recent trips overview
- Real-time weather information
- Travel news updates

#### Trips Management
- Create new trips with:
  - Trip name and description
  - Start and end dates (date picker)
  - Destination selection
  - Activity list management
  - Budget planning
  - AI-powered activity recommendations
  - Weather forecast integration
- View all trips in a list
- Trip details and editing
- Trip deletion

#### Explore Tab
- Search and filter travel advisors
- View advisor profiles
- Browse travel packages
- Package details and descriptions
- Package booking system
- Chat with advisors

#### Weather Tab
- Current weather for multiple cities
- 5-day weather forecast
- Hourly weather updates
- Weather search with autocomplete
- City weather comparison
- Save favorite cities
- Auto-refresh weather data
- Weather alerts/warnings
- UV index and wind speed
- Sunrise/sunset times

#### News Tab
- Travel-related news feed
- RSS feed integration (Google News)
- News categories:
  - Travel alerts
  - Safety updates
  - General travel news
- News article preview
- External links to full articles
- Save news queries
- Real-time news updates

#### Profile Tab
- User profile information
- Profile image upload
- Edit profile details
- Account settings
- Theme toggle (Light/Dark mode)
- Logout functionality

### 3. **AI-Powered Features**

#### AI Trip Planner
- Integrated Mistral AI for trip planning
- Input parameters:
  - Destination
  - Trip duration (days)
  - Budget range
  - Personal interests
  - Travel style preferences
- Generated trip plan includes:
  - Day-by-day itinerary
  - Activity recommendations
  - Budget breakdown
  - Local tips and advice
  - Best times to visit
- Save generated plans to database
- View saved trip plans
- Share trip plans
- Formatted markdown rendering

#### Landmark Scanner/Recognition
- Camera integration for taking photos
- Gallery image selection
- AI-powered landmark recognition using Mistral Vision Model
- Landmark information includes:
  - Landmark name
  - Location (city, country)
  - Historical significance
  - Key highlights
  - Best time to visit
  - Interesting facts
  - Visitor tips
- Save recognized landmarks
- View saved landmarks library
- Delete saved landmarks
- Share landmark information

### 4. **Advisor Dashboard Features**

#### Home Tab
- Advisor welcome section
- Statistics overview:
  - Total packages
  - Active bookings
  - Monthly earnings
  - Customer ratings
- Quick action buttons:
  - Create package
  - View bookings
  - Manage packages
  - View messages
- Getting started tips
- Performance insights

#### Bookings Management
- View all package bookings
- Booking filters:
  - All bookings
  - Pending bookings
  - Accepted bookings
  - Rejected bookings
  - Completed bookings
- Booking details:
  - Customer information
  - Package details
  - Booking date
  - Number of people
  - Total price
- Accept/Reject booking requests
- Mark bookings as completed
- Customer contact information

#### Packages Management
- Create new travel packages with:
  - Package name
  - Description
  - Price
  - Duration
  - Included services
  - Image gallery
  - Terms and conditions
- Edit existing packages
- Delete packages
- View package performance
- Package status (Active/Inactive)

#### Messages
- Chat system for customer communication
- View all conversations
- Unread message indicators
- Real-time messaging
- Message history

#### Analytics Tab
- Booking statistics
- Revenue tracking
- Performance metrics
- Customer feedback

#### Profile Tab
- Advisor profile management
- Business information
- Expertise and specializations
- Language preferences
- Contact details
- Rating and reviews

### 5. **Notification System**
- Local push notifications
- Notification categories:
  - Weather alerts
  - News updates
  - Booking updates
  - Trip reminders
  - System notifications
- In-app notification panel
- Unread notification counter
- Notification history
- Mark as read/unread
- Delete notifications
- Interactive notification overlays

### 6. **Additional Features**
- **DID Verification System** (Digital Identity)
- **Package Chat Interface** for customer-advisor communication
- **Search Functionality** for advisors and packages
- **Image Upload and Management**
- **Location Services** for nearby attractions
- **Geocoding** for address lookup
- **Pull-to-Refresh** on all data screens
- **Skeleton Loading States** (Shimmer effect)
- **Animated Transitions** between screens
- **Custom Drawer Navigation**
- **Bottom Navigation Bar** (floating design)

---

## 🛠️ Technologies & Tools

### **Frontend Framework**
- **Flutter SDK** (v3.10.0+)
  - Cross-platform mobile app development
  - Material Design components
  - Cupertino (iOS-style) widgets

### **Programming Language**
- **Dart** (v3.10.0+)

### **State Management**
- **Provider** (v6.1.2)
  - Reactive state management
  - Dependency injection

### **Backend & Database**
- **MongoDB Atlas**
  - Cloud-hosted NoSQL database
  - Collections:
    - users
    - trips
    - packages
    - bookings
    - saved_landmarks
    - saved_trip_plans
    - package_messages
  - **mongo_dart** (v0.10.3) - MongoDB driver for Dart

### **AI & Machine Learning**
- **Mistral AI API**
  - API Key: Integrated
  - Models used:
    - **mistral-medium-latest** - Vision model for landmark recognition
    - **mistral-small-latest** - Trip planning and recommendations
  - Features:
    - Image analysis
    - Natural language processing
    - Trip itinerary generation

### **API Integrations**

#### Weather API
- **OpenWeatherMap API**
  - Current weather data
  - 5-day forecast
  - Hourly forecasts
  - Weather alerts

#### News API
- **Google News RSS Feed**
  - Travel news aggregation
  - RSS XML parsing
  - Real-time news updates

### **HTTP & Networking**
- **http** (v1.2.2) - Basic HTTP requests
- **dio** (v5.7.0) - Advanced HTTP client with interceptors

### **Local Storage**
- **shared_preferences** (v2.3.3)
  - Key-value storage
  - User preferences
  - Cache management
  - Session persistence
  
- **flutter_secure_storage** (v9.2.2)
  - Encrypted local storage
  - Secure credential storage
  - Token management

- **sqflite** (v2.4.1)
  - Local SQLite database
  - Notification storage
  - Offline data caching

### **Image Handling**
- **image_picker** (v1.1.2)
  - Camera integration
  - Gallery access
  - Image compression
  
- **cached_network_image** (v3.4.1)
  - Image caching
  - Progressive loading
  - Placeholder support

### **Location Services**
- **geolocator** (v13.0.2)
  - GPS location tracking
  - Distance calculations
  - Location permissions
  
- **geocoding** (v3.0.0)
  - Address to coordinates conversion
  - Reverse geocoding
  - Location search

### **UI/UX Libraries**

#### Typography
- **google_fonts** (v6.2.1)
  - Custom font integration
  - Dynamic font loading

#### Graphics
- **flutter_svg** (v2.0.10)
  - SVG image rendering
  - Vector graphics support

#### Loading Indicators
- **flutter_spinkit** (v5.2.1)
  - Animated loading spinners
  - Multiple spinner styles
  
- **shimmer** (v3.0.0)
  - Skeleton loading effect
  - Placeholder animations

#### Animations
- **animations** (v2.0.11)
  - Page transitions
  - Shared element transitions
  - Container transforms

### **Notifications**
- **flutter_local_notifications** (v18.0.1)
  - Local push notifications
  - Scheduled notifications
  - Notification channels
  - Custom notification actions
  
- **timezone** (v0.9.4)
  - Timezone management
  - Scheduled notification timing

### **Utilities**

#### Date & Time
- **intl** (v0.20.2)
  - Date formatting
  - Number formatting
  - Internationalization support

#### Data Serialization
- **json_annotation** (v4.9.0)
  - JSON serialization
  - Model generation
  
- **json_serializable** (v6.8.0) - Dev dependency
- **build_runner** (v2.4.13) - Dev dependency

#### Cryptography
- **crypto** (v3.0.5)
  - Password hashing (SHA-256)
  - Encryption utilities
  - Secure data handling

#### URL Handling
- **url_launcher** (v6.3.2)
  - Open external URLs
  - Email links
  - Phone number dialing
  - Map navigation

#### XML Parsing
- **xml** (v6.6.1)
  - RSS feed parsing
  - XML document handling

#### File System
- **path_provider** (v2.1.5)
  - Access device directories
  - Cache directory management
  - App document storage

### **Development Tools**
- **flutter_test** - Unit and widget testing
- **flutter_lints** (v6.0.0) - Code quality and style checking
- **analysis_options.yaml** - Linting configuration

### **Platform Support**
- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

---

## 📊 Data Models

### User Model
- User ID (ObjectId)
- Full name
- Email
- Phone number
- User role (Tourist/Advisor/Agency)
- Business name (for advisors)
- Description
- Expertise areas
- Address and country
- Languages spoken
- Profile image
- Created date
- DID verification status

### Trip Model
- Trip ID
- User ID (owner)
- Trip name
- Description
- Destination
- Start date
- End date
- Budget
- Activities list
- Status
- Created date

### Package Model
- Package ID
- Advisor ID (creator)
- Package name
- Description
- Price
- Duration
- Included services
- Exclusions
- Terms and conditions
- Images
- Rating
- Reviews
- Created date
- Status (Active/Inactive)

### Booking Model
- Booking ID
- Package ID
- Tourist ID
- Advisor ID
- Number of people
- Total price
- Booking date
- Start date
- Status (Pending/Accepted/Rejected/Completed)
- Special requests
- Created date

### Notification Model
- Notification ID
- Title
- Body/Content
- Type (Weather/News/Booking/Trip/System)
- Category
- Priority
- Read status
- Timestamp
- Action data

### Saved Landmark Model
- Landmark ID
- User ID
- Landmark name
- Location
- Description
- Highlights
- Best time to visit
- Interesting facts
- Tips
- Image path
- Saved date

### Saved Trip Plan Model
- Plan ID
- User ID
- Destination
- Duration
- Budget
- Interests
- Generated plan (markdown)
- Created date

---

## 🎨 UI/UX Features

### Theme System
- **Light Theme**
  - Bright, clean interface
  - High contrast for readability
  
- **Dark Theme**
  - OLED-friendly dark colors
  - Reduced eye strain
  - Color(0xFF0F172A) background

- **Theme Persistence**
  - Saves user preference
  - Auto-applies on app launch

### Design Elements
- **Modern Material Design 3**
- **Glassmorphism Effects**
  - Frosted glass backgrounds
  - Backdrop blur filters
  
- **Gradient Overlays**
- **Custom Card Designs**
- **Floating Navigation Bar**
- **Custom Drawer Menu**
- **Pull-to-Refresh Indicators**
- **Skeleton Loading Screens**
- **Smooth Page Transitions**
- **Haptic Feedback**
- **Animated Icons and Buttons**
- **Responsive Layout**
- **Safe Area Handling**

### Typography
- Google Fonts integration
- Consistent text styles
- Dynamic font scaling
- Readable font sizes

### Color Scheme
- Primary: Blue (#2196F3)
- Secondary: Orange (#FF9800)
- Accent: Green (#4CAF50)
- Error: Red (#F44336)
- Background: Light Grey (#F5F5F5)
- Card: White (#FFFFFF)

---

## 🔐 Security Features

1. **Password Hashing**
   - SHA-256 encryption
   - Secure password storage

2. **Secure Storage**
   - Flutter Secure Storage for sensitive data
   - Encrypted local storage

3. **Authentication Tokens**
   - Session token management
   - Automatic token refresh

4. **MongoDB Security**
   - Connection string encryption
   - Authentication required
   - SSL/TLS enabled

5. **API Key Protection**
   - Environment-based configuration
   - Secure API key storage

---

## 📁 Project Structure

```
lib/
├── main.dart                      # App entry point
├── config/
│   └── app_config.dart           # API keys, MongoDB config, theme colors
├── models/
│   ├── user_model.dart
│   ├── trip_model.dart
│   ├── package_model.dart
│   ├── notification_model.dart
│   ├── news_model.dart
│   ├── saved_landmark_model.dart
│   └── saved_trip_plan_model.dart
├── services/
│   ├── auth_service.dart          # Authentication logic
│   ├── mongodb_service.dart       # Database operations
│   ├── mistral_service.dart       # AI integration
│   ├── weather_service.dart       # Weather API
│   ├── open_meteo_service.dart    # Alternative weather service
│   ├── package_service.dart       # Package management
│   ├── notification_service.dart  # Local notifications
│   ├── weather_notification_service.dart
│   └── news_notification_service.dart
├── screens/
│   ├── auth/
│   │   ├── welcome_screen.dart
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── tourist/
│   │   ├── tourist_dashboard.dart
│   │   ├── ai_trip_planner_screen.dart
│   │   ├── landmark_scanner_screen.dart
│   │   ├── create_trip_screen.dart
│   │   ├── trips_list_screen.dart
│   │   ├── weather_screen.dart
│   │   ├── news_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── edit_profile_screen.dart
│   │   ├── advisor_packages_browse_screen.dart
│   │   ├── package_details_screen.dart
│   │   ├── package_chat_screen.dart
│   │   ├── advisors_search_screen.dart
│   │   ├── saved_landmarks_screen.dart
│   │   ├── saved_trip_plans_screen.dart
│   │   └── did_verification_screen.dart
│   ├── advisor/
│   │   ├── advisor_dashboard.dart
│   │   ├── create_package_screen.dart
│   │   ├── advisor_packages_screen.dart
│   │   ├── advisor_messages_screen.dart
│   │   └── advisor_profile_screen.dart
│   ├── common/
│   │   └── notification_panel_screen.dart
│   └── settings/
├── widgets/
│   ├── custom_drawer.dart
│   ├── in_app_notification.dart
│   └── formatted_text.dart
├── utils/
│   └── app_theme.dart
└── providers/
    (Empty - currently using direct service calls)
```

---

## 🚀 Key Capabilities

### For Tourists
✅ AI-powered trip planning  
✅ Landmark recognition using camera  
✅ Create and manage trips  
✅ Browse and book travel packages  
✅ Real-time weather updates  
✅ Travel news and alerts  
✅ Chat with travel advisors  
✅ Save favorite landmarks  
✅ Profile customization  
✅ Push notifications  

### For Travel Advisors
✅ Create and manage travel packages  
✅ View and manage bookings  
✅ Accept/reject booking requests  
✅ Chat with customers  
✅ Business analytics  
✅ Profile and business information  
✅ Earnings tracking  
✅ Customer reviews  

### AI Features
✅ Natural language trip planning  
✅ Image-based landmark recognition  
✅ Personalized recommendations  
✅ Activity suggestions based on interests  
✅ Budget-aware itinerary generation  

---

## 📈 Performance Optimizations

- **Image Caching** - Reduces network calls
- **Lazy Loading** - Loads data on demand
- **Efficient State Management** - Provider pattern
- **Database Indexing** - Fast MongoDB queries
- **Connection Pooling** - Reuses MongoDB connections
- **Shimmer Loading** - Improves perceived performance
- **Background Data Refresh** - Auto-updates weather and news
- **Optimized Images** - Compressed and sized appropriately

---

## 🌐 Network Features

- Automatic retry on failure
- Connection status monitoring
- Offline mode support (cached data)
- Background data synchronization
- API rate limiting handling
- Error handling and user feedback

---

## 📱 Platform-Specific Configurations

### Android
- `build.gradle.kts` - Build configuration
- Minimum SDK: 21 (Android 5.0)
- Target SDK: Latest
- Permissions: Camera, Location, Internet, Storage

### iOS
- `Info.plist` - App permissions
- iOS 12.0+
- Camera, Location, Photo Library access

---

## 🎯 Future Enhancement Possibilities
*(Not currently implemented, but infrastructure ready)*

- Real-time location tracking
- Group trip planning
- Social features (share trips)
- Payment gateway integration
- Multi-language support
- Voice-guided tours
- AR landmark overlay
- Offline maps
- Trip expense tracking
- Travel insurance integration

---

## 📝 Notes

- All sensitive credentials are stored in `app_config.dart`
- MongoDB connection uses SSL/TLS encryption
- Images are stored locally and paths saved to database
- Notifications use local storage for persistence
- Weather data refreshes every 30 minutes
- News updates every 2 hours
- AI requests are rate-limited by Mistral API

---

**Last Updated:** March 1, 2026  
**App Version:** 1.0.0+1  
**Flutter SDK:** 3.10.0+  
**Dart SDK:** 3.10.0+
