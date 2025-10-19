#!/bin/bash

# Common Grounds Mobile App Setup Script
# This script helps set up the development environment

echo "🚀 Setting up Common Grounds Mobile App..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first:"
    echo "   https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo "✅ Flutter is installed: $(flutter --version | head -n 1)"

# Check Flutter doctor
echo "🔍 Running Flutter doctor..."
flutter doctor

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get

# Check if google-services.json exists
if [ ! -f "android/app/google-services.json" ]; then
    echo "⚠️  google-services.json not found in android/app/"
    echo "   Please add your Firebase configuration file"
    echo "   Download it from Firebase Console > Project Settings > Your Apps"
fi

# Check if Firebase is configured
if [ ! -f "lib/firebase_options.dart" ]; then
    echo "⚠️  firebase_options.dart not found"
    echo "   Run: flutterfire configure"
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p android/app/src/main/res/drawable
mkdir -p android/app/src/main/res/values

# Check Android SDK
echo "🤖 Checking Android setup..."
if [ -d "$ANDROID_HOME" ]; then
    echo "✅ Android SDK found at: $ANDROID_HOME"
else
    echo "⚠️  ANDROID_HOME not set. Please set up Android SDK"
fi

# Run analysis
echo "🔍 Running code analysis..."
flutter analyze

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Add your google-services.json to android/app/"
echo "2. Update campus coordinates in lib/services/location_service.dart"
echo "3. Run 'flutter run' to start the app"
echo ""
echo "For more information, see README.md"
