# TripNexus - Features Summary

## 📱 App Overview
**TripNexus** - AI-powered tourism application for travelers and travel advisors  
**Version:** 1.0.0+1 | **Framework:** Flutter 3.10.0+ | **Language:** Dart 3.10.0+

---

## 🎯 Core Features by Dashboard

### 👤 Tourist Dashboard

#### 1. **Authentication & Profile**
- User registration and login with email/password
- Session management with auto-login
- Profile editing with image upload
- Light/Dark theme toggle
- **Tools:** `shared_preferences`, `flutter_secure_storage`, `crypto` (SHA-256), `image_picker`

#### 2. **AI Trip Planner** 🤖
- Generate personalized trip itineraries using AI
- Input: destination, duration, budget, interests
- Output: Day-by-day plans, activities, budget breakdown, local tips
- Save and view generated plans
- **Tools:** `Mistral AI API` (mistral-small-latest), `mongodb_service`, `formatted_text` widget

#### 3. **Landmark Scanner** 📸
- Take photo or select from gallery
- AI-powered landmark recognition and analysis
- Get landmark name, location, history, highlights, facts, and tips
- Save recognized landmarks to library
- **Tools:** `Mistral AI API` (mistral-medium-latest vision model), `image_picker`, `path_provider`, `mongodb_service`

#### 4. **Trip Management**
- Create trips with dates, destination, activities, budget
- AI-powered activity recommendations
- Weather forecast integration for trip planning
- View, edit, and delete trips
- **Tools:** `mongodb_service`, `mistral_service`, `weather_service`, `intl` (date formatting)

#### 5. **Weather Forecast** ☀️
- Current weather and 5-day forecast
- Search cities with autocomplete
- Save multiple favorite cities
- Hourly updates, UV index, wind speed, sunrise/sunset
- Auto-refresh every 30 minutes
- **Tools:** `OpenWeatherMap API`, `weather_service`, `open_meteo_service`, `geolocator`, `geocoding`

#### 6. **Travel News Feed** 📰
- Real-time travel news and alerts
- RSS feed from Google News
- Categories: travel alerts, safety updates, general news
- Save custom news queries
- Opens articles in browser
- **Tools:** `xml` parser, `http`, `url_launcher`, `news_notification_service`

#### 7. **Package Browsing & Booking**
- Browse travel packages from advisors
- View package details (price, duration, services, images)
- Book packages with date and number of people
- Chat with advisors about packages
- Track booking status
- **Tools:** `mongodb_service`, `package_service`, `cached_network_image`

#### 8. **Advisor Search**
- Search and filter travel advisors
- View advisor profiles, ratings, expertise
- Contact advisors directly
- **Tools:** `mongodb_service`, `package_service`

#### 9. **Notifications** 🔔
- Local push notifications for weather, news, bookings, trips
- In-app notification panel with unread counter
- Interactive notification overlays
- Mark as read/unread, delete notifications
- **Tools:** `flutter_local_notifications`, `timezone`, `sqflite`, `notification_service`

---

### 🎫 Advisor Dashboard

#### 1. **Authentication & Profile**
- Advisor/Agency registration and login
- Business profile management
- Expertise, languages, contact details
- Ratings and reviews display
- **Tools:** `shared_preferences`, `flutter_secure_storage`, `crypto`, `image_picker`

#### 2. **Statistics Overview** 📊
- Total packages count
- Active bookings count
- Monthly earnings tracker
- Customer ratings summary
- Real-time dashboard metrics
- **Tools:** `mongodb_service`, `package_service`

#### 3. **Package Management**
- Create travel packages with:
  - Name, description, price, duration
  - Included services and exclusions
  - Terms and conditions
  - Image gallery
- Edit and delete packages
- Toggle package active/inactive status
- View package performance metrics
- **Tools:** `package_service`, `mongodb_service`, `image_picker`, `cached_network_image`

#### 4. **Bookings Management** 📋
- View all package bookings with filters:
  - All, Pending, Accepted, Rejected, Completed
- Booking details: customer info, package, dates, price
- Accept or reject booking requests
- Mark bookings as completed
- Customer contact information
- Real-time booking updates
- **Tools:** `package_service`, `mongodb_service`, `url_launcher`

#### 5. **Messaging System** 💬
- Chat with customers about packages
- View all conversations
- Unread message indicators
- Real-time messaging
- Message history and timestamps
- **Tools:** `mongodb_service`, `package_service`

#### 6. **Analytics Dashboard**
- Booking statistics and trends
- Revenue tracking
- Performance metrics
- Customer feedback analysis
- **Tools:** `mongodb_service`, `package_service`

---

## 🛠️ Technology Stack

### Core Technologies
| Technology | Version | Purpose |
|------------|---------|---------|
| **Flutter** | 3.10.0+ | Cross-platform UI framework |
| **Dart** | 3.10.0+ | Programming language |
| **MongoDB Atlas** | Cloud | NoSQL database with 7 collections |
| **Mistral AI** | API | AI for trip planning & image recognition |
| **OpenWeatherMap** | API | Weather data and forecasts |

### Key Flutter Packages (21 Total)

#### State & Data Management
- `provider` (6.1.2) - State management
- `mongo_dart` (0.10.3) - MongoDB driver
- `shared_preferences` (2.3.3) - Local key-value storage
- `flutter_secure_storage` (9.2.2) - Encrypted storage
- `sqflite` (2.4.1) - Local SQLite database

#### Networking & APIs
- `http` (1.2.2) - HTTP requests
- `dio` (5.7.0) - Advanced HTTP client
- `xml` (6.6.1) - RSS feed parsing

#### AI & Services
- `crypto` (3.0.5) - Password hashing
- Custom `mistral_service` - AI integration

#### UI/UX
- `google_fonts` (6.2.1) - Typography
- `flutter_svg` (2.0.10) - Vector graphics
- `shimmer` (3.0.0) - Loading skeletons
- `flutter_spinkit` (5.2.1) - Loading indicators
- `animations` (2.0.11) - Smooth transitions

#### Media & Location
- `image_picker` (1.1.2) - Camera & gallery
- `cached_network_image` (3.4.1) - Image caching
- `geolocator` (13.0.2) - GPS location
- `geocoding` (3.0.0) - Address conversion

#### Notifications & Utilities
- `flutter_local_notifications` (18.0.1) - Push notifications
- `timezone` (0.9.4) - Time management
- `intl` (0.20.2) - Date/number formatting
- `url_launcher` (6.3.2) - Open URLs/emails
- `path_provider` (2.1.5) - File system access

---

## 📊 Database Collections (MongoDB)

1. **users** - User accounts (tourists, advisors, agencies)
2. **trips** - Tourist trip plans
3. **packages** - Advisor travel packages
4. **bookings** - Package booking records
5. **saved_landmarks** - Tourist landmark library
6. **saved_trip_plans** - AI-generated trip plans
7. **package_messages** - Chat messages

---

## 🎨 Design Features

### UI/UX Elements
- **Material Design 3** with custom theme
- **Glassmorphism** effects with backdrop blur
- **Gradient overlays** and custom cards
- **Floating bottom navigation** bar
- **Shimmer loading** states
- **Smooth page transitions** and animations
- **Responsive layout** for all screen sizes
- **Pull-to-refresh** on all data screens

### Theme System
- **Light Theme** - Clean, bright interface
- **Dark Theme** - OLED-friendly (0xFF0F172A)
- **Theme persistence** - Saves user preference
- **System colors:**
  - Primary: Blue #2196F3
  - Secondary: Orange #FF9800
  - Accent: Green #4CAF50

---

## 🔐 Security Features

✅ SHA-256 password hashing  
✅ Encrypted local storage for credentials  
✅ MongoDB SSL/TLS encryption  
✅ Secure API key storage  
✅ Session token management  

---

## 📈 Performance Optimizations

- Image caching with `cached_network_image`
- Lazy loading for data lists
- MongoDB connection pooling
- Background data refresh (weather: 30min, news: 2hrs)
- Shimmer loading for perceived speed
- Optimized image compression

---

## 🚀 Key Differentiators

### AI-Powered Features
1. **Smart Trip Planning** - Mistral AI generates personalized itineraries
2. **Visual Landmark Recognition** - Identify landmarks from photos
3. **Intelligent Recommendations** - Context-aware activity suggestions

### Real-Time Services
1. **Live Weather** - 5-day forecasts with hourly updates
2. **Travel News** - Automated RSS feed aggregation
3. **Instant Notifications** - Weather alerts, news, booking updates

### Dual-Role Platform
1. **Tourist Mode** - Trip planning, booking, AI assistance
2. **Advisor Mode** - Package creation, booking management, analytics

---

## 📱 Platform Support
✅ Android (API 21+) | ✅ iOS (12.0+) | ✅ Web | ✅ Windows | ✅ macOS | ✅ Linux

---

**Last Updated:** March 2, 2026  
**Total Features:** 15+ major features  
**Flutter Packages:** 21 dependencies  
**AI Models:** 2 (Mistral Medium + Small)  
**APIs Integrated:** 3 (Mistral, OpenWeatherMap, Google News)
