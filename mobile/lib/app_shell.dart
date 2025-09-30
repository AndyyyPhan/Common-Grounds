// lib/app_shell.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'pages/profile_page.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;
    final displayName = u?.displayName ?? 'Friend';
    final email = u?.email ?? '';
    final photo = u?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Common Grounds'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await AuthService.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            tooltip: 'My Profile',
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (photo != null)
              CircleAvatar(radius: 36, backgroundImage: NetworkImage(photo)),
            const SizedBox(height: 12),
            Text('Hi, $displayName', style: const TextStyle(fontSize: 20)),
            if (email.isNotEmpty) Text(email),
            const SizedBox(height: 24),
            const Text('This is your main app shell.'),
          ],
        ),
      ),
    );
  }
}
