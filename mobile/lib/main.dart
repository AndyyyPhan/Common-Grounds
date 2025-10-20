import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// App imports
import 'app_shell.dart';
import 'onboarding/onboarding_page.dart';
import 'services/local_prefs.dart';
import 'firebase_options.dart';
import 'pages/sign_in_page.dart';
import 'services/profile_service.dart';
import 'models/user_profile.dart';
import 'pages/profile_setup_page.dart';
import 'services/messaging_service.dart';
import 'services/location_service.dart';

// Design system imports
import 'core/theme/app_theme.dart';

/// Main entry point for the Common Grounds app.
///
/// Initializes Firebase and wraps the app with Riverpod's ProviderScope
/// for state management throughout the application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Wrap the app with ProviderScope for Riverpod state management
  runApp(const ProviderScope(child: MyApp()));
}

/// Root widget of the Common Grounds application.
///
/// Configures the MaterialApp with our custom theme system that includes:
/// - Light and dark mode support
/// - Consistent color palette (jade green primary)
/// - Typography system with proper text styles
/// - Spacing and layout constants
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Common Grounds',
      debugShowCheckedModeBanner: false,

      // Apply custom theme with light/dark mode support
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Follows system preference
      // Named routes for navigation
      routes: {
        '/app': (_) => const AppShell(),
        '/onboarding': (_) => const OnboardingPage(),
        '/signin': (_) => const SignInPage(),
      },

      // Bootstrap gate handles initial routing logic
      home: const BootstrapGate(),
    );
  }
}

/// Bootstrap Gate - Authentication and Profile Flow Manager
///
/// This widget handles the initial routing logic for the app:
/// 1. Check if user has completed onboarding
/// 2. Check if user is authenticated with Firebase
/// 3. Check if user has completed their profile
/// 4. Initialize user services (FCM, location tracking)
/// 5. Route to appropriate screen based on state
///
/// Flow: Onboarding → Sign In → Profile Setup → App Shell
class BootstrapGate extends StatefulWidget {
  const BootstrapGate({super.key});

  @override
  State<BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<BootstrapGate> {
  bool? _onboarded;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Load onboarding state from local storage
  Future<void> _load() async {
    _onboarded = await LocalPrefs.hasOnboarded();
    if (mounted) setState(() {});
  }

  /// Initialize FCM and location services for the authenticated user.
  ///
  /// This is called once the user is authenticated to set up:
  /// - Firebase Cloud Messaging (FCM) for push notifications
  /// - Location tracking for proximity-based features
  ///
  /// Note: Location permission denial doesn't block the app -
  /// users can enable it later in settings.
  Future<void> _initUserServices(String uid) async {
    try {
      // Initialize FCM for push notifications
      await MessagingService.instance.initForUser(uid);
    } catch (e) {
      debugPrint('FCM initialization failed (non-critical): $e');
    }

    try {
      // Initialize location tracking (will request permissions)
      // Don't fail if location permission is denied
      await LocationService.instance.initForUser(uid);
    } catch (e) {
      debugPrint('Location service initialization failed (non-critical): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading onboarding state
    if (_onboarded == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show onboarding if not completed
    if (_onboarded == false) {
      return const OnboardingPage();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (authSnap.hasError) {
          return Scaffold(
            body: Center(child: Text('Auth error: ${authSnap.error}')),
          );
        }

        final user = authSnap.data;
        if (user == null) return const SignInPage();

        // Ensure there's a profile doc, then watch it.
        return FutureBuilder<void>(
          future: _initUserServices(user.uid),
          builder: (context, initSnap) {
            if (initSnap.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            // If init fails, don't block the app—just continue
            // (you can show a snackbar/toast elsewhere if desired)
            if (initSnap.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Service init error: ${initSnap.error}'),
                ),
              );
            }

            return StreamBuilder<UserProfile?>(
              stream: ProfileService.instance.watchProfile(user.uid),
              builder: (context, profSnap) {
                if (profSnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (profSnap.hasError) {
                  return Scaffold(
                    body: Center(
                      child: Text('Profile load error: ${profSnap.error}'),
                    ),
                  );
                }
                final profile = profSnap.data;
                if (profile == null || !profile.isComplete) {
                  return ProfileSetupPage(
                    profile:
                        profile ??
                        UserProfile(
                          uid: user.uid,
                          displayName: user.displayName,
                          photoUrl: user.photoURL,
                          bio: null,
                          classYear: null,
                          major: null,
                          interests: const [],
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                  );
                }
                return const AppShell();
              },
            );
          },
        );
      },
    );
  }
}
