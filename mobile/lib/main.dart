import 'package:flutter/material.dart';
import 'app_shell.dart';
import 'onboarding/onboarding_page.dart';
import 'services/local_prefs.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'pages/sign_in_page.dart';
import 'services/profile_service.dart';
import 'models/user_profile.dart';
import 'pages/profile_setup_page.dart';
import 'services/messaging_service.dart';
import 'services/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Common Grounds',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      routes: {
        '/app': (_) => const AppShell(),
        '/onboarding': (_) => const OnboardingPage(),
        '/signin': (_) => const SignInPage(),
      },
      home: const BootstrapGate(),
    );
  }
}

/// Decides: Onboarding -> SignIn -> AppShell (or ProfileSetup if incomplete)
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

  Future<void> _load() async {
    _onboarded = await LocalPrefs.hasOnboarded();
    if (mounted) setState(() {});
  }

  /// Initialize FCM and location services for the authenticated user
  Future<void> _initUserServices(String uid) async {
    // Initialize FCM for push notifications
    await MessagingService.instance.initForUser(uid);

    // Initialize location tracking (will request permissions)
    // Don't fail if location permission is denied - user can enable later
    await LocationService.instance.initForUser(uid);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboarded == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_onboarded == false) return const OnboardingPage();

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
