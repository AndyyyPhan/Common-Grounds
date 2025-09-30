// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'my_app_state.dart';
import 'app_shell.dart';
import 'onboarding/onboarding_page.dart';
import 'services/local_prefs.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _onboarded;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final done = await LocalPrefs.hasOnboarded();
    setState(() => _onboarded = done);
  }

  @override
  Widget build(BuildContext context) {
    final home = switch (_onboarded) {
      null => const Material(child: Center(child: CircularProgressIndicator())),
      true => const AppShell(),
      false => const OnboardingPage(),
    };

    return ChangeNotifierProvider(
      create: (_) => MyAppState(),
      child: MaterialApp(
        title: 'Common Grounds',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        routes: {
          '/app': (_) => const AppShell(),
          '/onboarding': (_) => const OnboardingPage(),
        },
        home: home,
      ),
    );
  }
}
