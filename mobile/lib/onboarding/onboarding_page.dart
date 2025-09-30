import 'package:flutter/material.dart';
import '../services/local_prefs.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () async {
            await LocalPrefs.setOnboarded(true);
            if (!context.mounted) return;
            Navigator.of(context).pushReplacementNamed('/signin');
          },
          child: const Text('Get started'),
        ),
      ),
    );
  }
}
