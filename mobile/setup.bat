@echo off
REM Common Grounds Mobile App Setup Script for Windows
REM This script helps set up the development environment

echo 🚀 Setting up Common Grounds Mobile App...

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed. Please install Flutter first:
    echo    https://docs.flutter.dev/get-started/install
    pause
    exit /b 1
)

echo ✅ Flutter is installed
flutter --version

REM Check Flutter doctor
echo 🔍 Running Flutter doctor...
flutter doctor

REM Get dependencies
echo 📦 Installing dependencies...
flutter pub get

REM Check if google-services.json exists
if not exist "android\app\google-services.json" (
    echo ⚠️  google-services.json not found in android\app\
    echo    Please add your Firebase configuration file
    echo    Download it from Firebase Console ^> Project Settings ^> Your Apps
)

REM Check if Firebase is configured
if not exist "lib\firebase_options.dart" (
    echo ⚠️  firebase_options.dart not found
    echo    Run: flutterfire configure
)

REM Create necessary directories
echo 📁 Creating necessary directories...
if not exist "android\app\src\main\res\drawable" mkdir "android\app\src\main\res\drawable"
if not exist "android\app\src\main\res\values" mkdir "android\app\src\main\res\values"

REM Check Android SDK
echo 🤖 Checking Android setup...
if defined ANDROID_HOME (
    echo ✅ Android SDK found at: %ANDROID_HOME%
) else (
    echo ⚠️  ANDROID_HOME not set. Please set up Android SDK
)

REM Run analysis
echo 🔍 Running code analysis...
flutter analyze

echo.
echo 🎉 Setup complete!
echo.
echo Next steps:
echo 1. Add your google-services.json to android\app\
echo 2. Update campus coordinates in lib\services\location_service.dart
echo 3. Run 'flutter run' to start the app
echo.
echo For more information, see README.md
pause
