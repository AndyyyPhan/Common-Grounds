# Common Grounds

## Project Description

Common Grounds is a Flutter-based mobile application designed to help students connect with each other based on proximity and shared interests. The app uses location-based matching to find nearby students with similar academic interests, hobbies, and study preferences, making it easier for students to form study groups, find study partners, and build meaningful connections on campus.

### Key Features

- **Proximity-Based Matching**: Automatically finds students nearby using real-time location tracking
- **Interest-Based Matching**: Connects users based on shared interests, majors, and class years
- **Wave System**: Users can "wave" at potential matches to express interest
- **Real-Time Messaging**: Chat with matched users directly within the app
- **Profile Customization**: Create detailed profiles with interests, vibe tags, and study preferences
- **Push Notifications**: Get notified about new matches, waves, and messages
- **Google Maps Integration**: Interactive location picker for precise location sharing
- **Dark Mode Support**: Beautiful UI with light and dark theme options

## Team Members

- **Andy Phan** - tmq6ed
- **Kevin Arleen** - xsu4ju
- **Sanjay Karunamoorthy** - vmw8vr

## Builds and Downloads

### Android APK
- **Release APK**: 
  - Primary location: `releases/CommonGrounds-release.apk` (52.9 MB)
  - Build location: `mobile/build/app/outputs/flutter-apk/app-release.apk`
  - Built successfully and ready for distribution
  - SHA1 checksum: `a47a310eaf3345fd172b8edc89c1ca35561b8086`
- **Debug APK**: Available at `mobile/build/app/outputs/flutter-apk/app-debug.apk`


### Building the App

To build the Android APK:
```bash
cd mobile
flutter build apk --release
```

The APK will be located at: `mobile/build/app/outputs/flutter-apk/app-release.apk`

To build for iOS:
```bash
cd mobile
flutter build ios --release
```

## Installation Instructions

### Prerequisites

1. **Flutter SDK** (version 3.35.5 or compatible)
   - Download from [flutter.dev](https://flutter.dev/docs/get-started/install)
   - Ensure Flutter is added to your PATH

2. **Android Studio** (for Android development)
   - Download from [developer.android.com](https://developer.android.com/studio)
   - Install Android SDK and required tools

3. **Xcode** (for iOS development - macOS only)
   - Available on the Mac App Store

4. **Firebase Account**
   - The app uses Firebase for authentication, database, and cloud functions
   - Firebase project: `blue4-commongrounds`

5. **Google Maps API Key** (optional but recommended)
   - See `mobile/GOOGLE_MAPS_SETUP.md` for detailed setup instructions

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd capstone-blue-4
   ```

2. **Navigate to the mobile directory**
   ```bash
   cd mobile
   ```

3. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

4. **Configure Firebase**
   - The Firebase configuration files are already included in the project
   - Ensure you have access to the Firebase project: `blue4-commongrounds`
   - Firebase configuration is located in:
     - Android: `mobile/android/app/google-services.json`
     - iOS: `mobile/ios/Runner/GoogleService-Info.plist` (if available)

5. **Set up Google Maps (Optional)**
   - Follow the instructions in `mobile/GOOGLE_MAPS_SETUP.md`
   - Add your Google Maps API key to `mobile/android/app/src/main/AndroidManifest.xml`

6. **Run the app**
   ```bash
   flutter run
   ```

### Additional Setup

#### Firebase Cloud Functions
If you need to set up or deploy cloud functions:
```bash
cd mobile/functions
npm install
firebase deploy --only functions
```
See `mobile/CLOUD_FUNCTIONS_SETUP.md` for more details.

#### Firebase Emulators (for local development)
```bash
cd mobile
firebase emulators:start
```

## User Accounts for Testing
Username: commmonask3@gmail.com
Password: Commonask3$$$

### Creating Test Accounts
1. Launch the app
2. Tap "Sign in with Google" or "Sign in with Apple"
3. Complete the profile setup:
   - Add your display name
   - Select interests
   - Add vibe tags
   - Set your location (optional)
   - Add bio, major, and class year (optional)

## Usage Instructions

### Getting Started

1. **Sign In**
   - Open the app
   - Choose to sign in with Google or Apple
   - Grant necessary permissions (location, notifications)

2. **Complete Your Profile**
   - Add your display name and photo
   - Select your interests from the available categories
   - Choose vibe tags that describe your study style and personality
   - Optionally add your major, class year, and bio
   - Set your location (you can use GPS or pick on map)

3. **Discover Matches**
   - The Home tab shows nearby students with similar interests
   - View their profiles, interests, and compatibility scores
   - Use the search radius slider to adjust how far to search

4. **Wave at Matches**
   - Tap the "Wave" button on a user's profile to express interest
   - If they wave back, you'll get a mutual match!
   - View your waves and matches in the Waves tab

5. **Chat with Matches**
   - Once you have a mutual match, you can start chatting
   - Access conversations from the Messages tab
   - Send messages, photos, and react to messages

6. **Update Your Profile**
   - Go to the Profile tab to edit your information
   - Update your location, interests, or vibe tags anytime
   - Change your search radius to find more or fewer matches

### Key Features Explained

- **Home Tab**: Discover nearby students, view quick stats, and see potential matches
- **Waves Tab**: View all your sent and received waves, and manage mutual matches
- **Messages Tab**: Chat with your matches in real-time
- **Profile Tab**: Edit your profile, update location, and adjust settings

### Tips for Best Experience

- Keep your location updated for accurate matching
- Add multiple interests to increase match potential
- Use vibe tags to find study partners with compatible study styles
- Respond to waves promptly to build connections
- Update your profile regularly to keep it fresh

## Technical Details

### Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Authentication, Cloud Functions, Cloud Messaging)
- **State Management**: Riverpod
- **Location Services**: Geolocator, Google Maps Flutter
- **Authentication**: Firebase Auth (Google Sign-In, Apple Sign-In)

### Project Structure

```
mobile/
├── lib/
│   ├── core/           # Theme, widgets, constants
│   ├── models/         # Data models
│   ├── pages/          # App screens
│   ├── services/       # Business logic and Firebase services
│   ├── utils/          # Utility functions
│   └── widgets/        # Reusable widgets
├── android/            # Android-specific code
├── ios/                # iOS-specific code
├── functions/          # Firebase Cloud Functions
└── dataconnect/        # Firebase Data Connect schema
```

### Firebase Services Used

- **Firebase Authentication**: User sign-in (Google, Apple)
- **Cloud Firestore**: User profiles, messages, waves, matches
- **Firebase Cloud Messaging**: Push notifications
- **Firebase Storage**: Profile photos and media
- **Firebase Cloud Functions**: Server-side matching and processing
- **Firebase Data Connect**: GraphQL-based data layer (experimental)

## Development

### Running Tests
```bash
cd mobile
flutter test
```

### Code Analysis
```bash
cd mobile
flutter analyze
```

### Format Code
```bash
cd mobile
dart format .
```

## Documentation

Additional documentation is available in the `mobile/` directory:
- `GOOGLE_MAPS_SETUP.md` - Google Maps API setup guide
- `CLOUD_FUNCTIONS_SETUP.md` - Cloud Functions setup and deployment
- `LOCATION_TESTING_GUIDE.md` - Location feature testing guide
- `LOCATION_PICKER_DEBUG.md` - Location picker debugging tips

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2025 Andy Phan, Kevin Arleen, Sanjay Karunamoorthy

## Contact

For questions or issues, please contact the development team or open an issue in the repository.
