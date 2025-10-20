// lib/app_shell.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'services/chat_service.dart';
import 'models/user_profile.dart';
import 'models/chat_models.dart';
import 'pages/profile_page.dart';
import 'pages/conversations_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser!;

    return StreamBuilder<UserProfile?>(
      stream: ProfileService.instance.watchProfile(u.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = snap.data;
        final displayName = profile?.displayName ?? u.displayName ?? 'Friend';

        final pages = [
          _HomePage(displayName: displayName, photoUrl: u.photoURL),
          const ConversationsPage(),
          const ProfilePage(),
        ];

        return Scaffold(
          appBar: _currentIndex == 0 ? _AppBar() : null,
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: _BottomNav(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            userId: u.uid,
          ),
        );
      },
    );
  }
}

class _HomePage extends StatelessWidget {
  final String displayName;
  final String? photoUrl;

  const _HomePage({
    required this.displayName,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (photoUrl != null)
            CircleAvatar(
              radius: 36,
              backgroundImage: NetworkImage(photoUrl!),
            ),
          const SizedBox(height: 12),
          Text('Hi, $displayName', style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 24),
          const Text('Welcome to Common Grounds!'),
          const SizedBox(height: 8),
          const Text('Find nearby students and start connecting.'),
        ],
      ),
    );
  }
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Common Grounds'),
      actions: [
        IconButton(
          tooltip: 'Sign out',
          onPressed: () async => AuthService.instance.signOut(),
          icon: const Icon(Icons.logout),
        ),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String userId;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Conversation>>(
      stream: ChatService.instance.watchUserConversations(userId),
      builder: (context, snapshot) {
        // Calculate total unread messages
        int totalUnread = 0;
        if (snapshot.hasData) {
          for (var conversation in snapshot.data!) {
            totalUnread += conversation.getUnreadCountForUser(userId);
          }
        }

        return BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: totalUnread > 0
                  ? Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.chat),
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              totalUnread > 99 ? '99+' : totalUnread.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Icon(Icons.chat),
              label: 'Messages',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        );
      },
    );
  }
}
