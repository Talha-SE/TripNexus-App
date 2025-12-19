# TripNexus Quick Start Script
# Run this script to check if everything is ready

Write-Host "================================" -ForegroundColor Cyan
Write-Host "   TripNexus Setup Checker" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check Flutter
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
$flutterVersion = flutter --version 2>&1 | Select-String -Pattern "Flutter" | Select-Object -First 1
if ($flutterVersion) {
    Write-Host "✓ Flutter is installed: $flutterVersion" -ForegroundColor Green
} else {
    Write-Host "✗ Flutter not found. Please install Flutter first." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Check if in correct directory
Write-Host "Checking project directory..." -ForegroundColor Yellow
if (Test-Path ".\pubspec.yaml") {
    Write-Host "✓ Running in project directory" -ForegroundColor Green
} else {
    Write-Host "✗ Not in project directory. Please run this script from tourism_app folder" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Check dependencies
Write-Host "Checking dependencies..." -ForegroundColor Yellow
if (Test-Path ".\pubspec.lock") {
    Write-Host "✓ Dependencies installed" -ForegroundColor Green
} else {
    Write-Host "! Dependencies not installed. Running flutter pub get..." -ForegroundColor Yellow
    flutter pub get
}

Write-Host ""

# Check configuration file
Write-Host "Checking configuration..." -ForegroundColor Yellow
$configContent = Get-Content ".\lib\config\app_config.dart" -Raw

if ($configContent -match "YOUR_MONGODB_ATLAS_CONNECTION_STRING") {
    Write-Host "⚠ MongoDB connection string not configured" -ForegroundColor Red
    Write-Host "  Please update lib/config/app_config.dart" -ForegroundColor Yellow
} else {
    Write-Host "✓ MongoDB connection string configured" -ForegroundColor Green
}

if ($configContent -match "YOUR_MISTRAL_API_KEY") {
    Write-Host "⚠ Mistral API key not configured" -ForegroundColor Red
    Write-Host "  Please update lib/config/app_config.dart" -ForegroundColor Yellow
} else {
    Write-Host "✓ Mistral API key configured" -ForegroundColor Green
}

if ($configContent -match "YOUR_WEATHER_API_KEY") {
    Write-Host "⚠ Weather API key not configured" -ForegroundColor Red
    Write-Host "  Please update lib/config/app_config.dart" -ForegroundColor Yellow
} else {
    Write-Host "✓ Weather API key configured" -ForegroundColor Green
}

Write-Host ""

# Check for devices
Write-Host "Checking for available devices..." -ForegroundColor Yellow
$devices = flutter devices 2>&1
if ($devices -match "No devices detected") {
    Write-Host "⚠ No devices or emulators detected" -ForegroundColor Yellow
    Write-Host "  Please start an emulator or connect a device" -ForegroundColor Yellow
} else {
    Write-Host "✓ Device(s) available:" -ForegroundColor Green
    flutter devices | Select-String -Pattern "•" | ForEach-Object { Write-Host "  $_" -ForegroundColor Cyan }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Setup Check Complete!" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Configure API keys in lib/config/app_config.dart" -ForegroundColor White
Write-Host "2. Start an emulator or connect a device" -ForegroundColor White
Write-Host "3. Run: flutter run" -ForegroundColor White
Write-Host ""
Write-Host "For detailed setup instructions, see:" -ForegroundColor Yellow
Write-Host "  - README.md (Quick start)" -ForegroundColor White
Write-Host "  - ../SETUP_GUIDE.md (Complete guide)" -ForegroundColor White
Write-Host ""
