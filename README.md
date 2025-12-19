# TripNexus - Modern Tourism Mobile Application

## 🌟 Overview
TripNexus is a modern, AI-powered tourism mobile application built with Flutter for Android. It features user role-based dashboards (Tourist, Individual Advisor, Travel Agency), AI-powered recommendations, landmark recognition, weather integration, and trip management.

## 📱 Features

### Core Features
- ✅ User Authentication (Login/Register) with role selection
- ✅ Three user roles: Tourist, Individual Advisor, Travel Agency
- ✅ Role-specific dashboards with bottom navigation
- ✅ Modern Material 3 design with Google Fonts
- 🤖 Mistral AI Integration for recommendations and landmark recognition
- ☁️ Weather Integration with OpenWeatherMap API
- 🗄️ MongoDB Atlas for cloud database

## 🚀 Quick Start

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Configure API Keys** in `lib/config/app_config.dart`:
   - MongoDB Atlas connection string
   - Mistral AI API key
   - OpenWeatherMap API key

3. **Run the app**
   ```bash
   flutter run
   ```

## 📝 Configuration Required

Before running the app, update `lib/config/app_config.dart` with your API credentials:
- MongoDB Atlas connection string
- Mistral AI API key (from https://mistral.ai/)
- OpenWeatherMap API key (from https://openweathermap.org/)

For detailed setup instructions, API setup guides, and full documentation, see the comprehensive README in the project root
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
