# Common Grounds - Mobile App

A privacy-first mobile app for college students to connect based on shared interests and proximity.

## 🎯 Project Overview

Common Grounds helps college students find and connect with nearby peers who share similar interests. The app uses coarse location data and interest matching to facilitate meaningful connections while maintaining user privacy and safety.

### Key Features

- **Privacy-First Design**: Coarse location sharing, mutual consent, and comprehensive privacy controls
- **Interest-Based Matching**: Connect with students who share your hobbies and interests
- **Proximity Detection**: Find matches within 50 meters using geofencing
- **In-App Messaging**: Secure 1:1 chat with matched users
- **Push Notifications**: Get notified when potential matches are nearby
- **Privacy Controls**: Granular settings for location precision, data sharing, and notifications

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Android Studio / VS Code
- Firebase project with Authentication, Firestore, and Cloud Messaging enabled
- Google Sign-In configured
- Android device or emulator (API level 21+)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd capstone-blue-4/mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Ensure `google-services.json` is in `android/app/`
   - Verify Firebase configuration in `lib/firebase_options.dart`

4. **Update campus coordinates**
   - Edit `lib/services/location_service.dart`
   - Update `_campusLat`, `_campusLng`, and `_campusRadius` for your campus

5. **Run the app**
   ```bash
   flutter run
   ```

## 📱 App Structure

### Core Services

- **AuthService**: Google Sign-In authentication
- **LocationService**: GPS tracking and geofencing
- **NotificationService**: Push notifications and local alerts
- **MatchingService**: Interest matching and proximity detection
- **MessagingService**: In-app chat functionality
- **PrivacyService**: Privacy settings and data controls
- **ProfileService**: User profile management

### Key Models

- **UserProfile**: User information and interests
- **Match**: Match between two users
- **Chat**: Chat conversation
- **Message**: Individual chat message
- **PrivacySettings**: User privacy preferences

### Pages

- **HomePage**: Dashboard with status and quick actions
- **MatchesPage**: View and interact with matches
- **MessagesPage**: Chat conversations
- **SettingsPage**: Privacy and app settings
- **ProfilePage**: User profile management

## 🔧 Configuration

### Android Permissions

The app requires the following permissions (already configured):

- `ACCESS_FINE_LOCATION` - For precise location tracking
- `ACCESS_COARSE_LOCATION` - For approximate location
- `ACCESS_BACKGROUND_LOCATION` - For background location updates
- `POST_NOTIFICATIONS` - For push notifications
- `INTERNET` - For network communication

### Firebase Setup

1. **Authentication**
   - Enable Google Sign-In
   - Configure OAuth consent screen
   - Add your app's SHA-1 fingerprint

2. **Firestore Database**
   - Create collections: `users`, `matches`, `chats`, `messages`, `privacy_settings`
   - Set up security rules for data protection

3. **Cloud Messaging**
   - Enable FCM for push notifications
   - Configure notification channels

### Campus Configuration

Update the campus boundaries in `lib/services/location_service.dart`:

```dart
// Replace with your campus coordinates
static const double _campusLat = 40.7128; // Your campus latitude
static const double _campusLng = -74.0060; // Your campus longitude
static const double _campusRadius = 1000; // Campus radius in meters
```

## 🧪 Testing

### Unit Tests

```bash
flutter test
```

### Integration Tests

```bash
flutter test integration_test/
```

### Manual Testing Checklist

#### Authentication
- [ ] Google Sign-In works correctly
- [ ] User profile creation after sign-in
- [ ] Sign-out functionality

#### Location Services
- [ ] Location permission requests
- [ ] GPS tracking accuracy
- [ ] Background location updates
- [ ] Campus boundary detection

#### Matching System
- [ ] Interest-based matching
- [ ] Proximity detection (50m radius)
- [ ] Match notifications
- [ ] Wave/pass functionality

#### Messaging
- [ ] Chat creation after mutual match
- [ ] Message sending/receiving
- [ ] Real-time updates
- [ ] Message read status

#### Privacy Controls
- [ ] Location sharing toggle
- [ ] Notification settings
- [ ] Profile visibility controls
- [ ] Data sharing preferences

### Performance Testing

```bash
# Run with performance overlay
flutter run --profile

# Check for memory leaks
flutter run --trace-startup
```

## 🚀 Building for Production

### Android APK

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

### Android App Bundle (Recommended)

```bash
flutter build appbundle --release
```

### Signing Configuration

1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties`:
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=<path-to-keystore>
   ```

3. Update `android/app/build.gradle.kts` signing configuration

## 📊 Analytics & Monitoring

### Firebase Analytics

The app includes Firebase Analytics for:
- User engagement tracking
- Feature usage statistics
- Error monitoring
- Performance metrics

### Privacy Compliance

- **GDPR Compliance**: Data deletion functionality
- **COPPA Compliance**: Age verification for college students
- **Transparent Data Usage**: Clear privacy settings and explanations

## 🔒 Security Features

- **Data Encryption**: All data encrypted in transit and at rest
- **Privacy by Design**: Minimal data collection
- **User Control**: Granular privacy settings
- **Secure Authentication**: Google OAuth 2.0
- **Location Privacy**: Coarse location sharing only

## 🐛 Troubleshooting

### Common Issues

1. **Location not working**
   - Check device location settings
   - Verify app permissions
   - Test on physical device (emulator may have issues)

2. **Notifications not received**
   - Check notification permissions
   - Verify FCM configuration
   - Test on physical device

3. **Firebase connection issues**
   - Verify `google-services.json` is correct
   - Check Firebase project configuration
   - Ensure internet connectivity

4. **Build errors**
   - Run `flutter clean`
   - Run `flutter pub get`
   - Check Flutter and Dart versions

### Debug Mode

```bash
# Enable debug logging
flutter run --debug

# Check logs
flutter logs
```

## 📈 Future Enhancements

- [ ] Group chat functionality
- [ ] Event-based matching
- [ ] Advanced recommendation algorithms
- [ ] Cross-platform iOS support
- [ ] Offline mode support
- [ ] Advanced privacy controls

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Team

- **Kevin Arleen** (xsu4ju) - Backend & Matching Logic
- **Andy Phan** (tmq6ed) - Authentication & Privacy
- **Sanjay Karunamoorthy** (vmw8vr) - UI/UX & Notifications

## 📞 Support

For technical support or questions:
- Create an issue in the repository
- Contact the development team
- Check the troubleshooting section above

---

**Made with ❤️ for college students**
