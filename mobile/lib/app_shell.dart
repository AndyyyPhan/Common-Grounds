// lib/app_shell.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/matching_service.dart';
import 'services/privacy_service.dart';
import 'models/user_profile.dart';
import 'pages/profile_page.dart';
import 'pages/matches_page.dart';
import 'pages/messages_page.dart';
import 'pages/settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize all services
      await LocationService.instance.initialize();
      await NotificationService.instance.initialize();
      await MatchingService.instance.initialize();
      
      // Start matching if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await MatchingService.instance.startMatching(user.uid);
      }
    } catch (e) {
      print('Error initializing services: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          HomePage(),
          MatchesPage(),
          MessagesPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser!;
    final email = u.email ?? '';
    final photo = u.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Common Grounds'),
        actions: [
          IconButton(
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
            },
            icon: const Icon(Icons.person),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async => AuthService.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<UserProfile?>(
        stream: ProfileService.instance.watchProfile(u.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snap.data;
          final displayName = profile?.displayName ?? u.displayName ?? 'Friend';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        if (photo != null)
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(photo),
                          )
                        else
                          const CircleAvatar(
                            radius: 30,
                            child: Icon(Icons.person, size: 30),
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, $displayName!',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Status Cards
                Row(
                  children: [
                    Expanded(
                      child: _StatusCard(
                        icon: Icons.location_on,
                        title: 'Location',
                        subtitle: 'Sharing enabled',
                        color: Colors.green,
                        onTap: () {
                          // Navigate to location settings
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatusCard(
                        icon: Icons.notifications,
                        title: 'Notifications',
                        subtitle: 'Active',
                        color: Colors.blue,
                        onTap: () {
                          // Navigate to notification settings
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.people,
                        title: 'Find Matches',
                        subtitle: 'Discover nearby students',
                        onTap: () {
                          // Navigate to matches page - this will be handled by bottom navigation
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.chat,
                        title: 'Messages',
                        subtitle: 'Chat with matches',
                        onTap: () {
                          // Navigate to messages page
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.edit,
                        title: 'Edit Profile',
                        subtitle: 'Update your interests',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ProfilePage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.settings,
                        title: 'Settings',
                        subtitle: 'Privacy & preferences',
                        onTap: () {
                          // Navigate to settings page
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Recent Activity
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.people_outline),
                          title: const Text('New matches nearby'),
                          subtitle: const Text('3 students with shared interests'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Navigate to matches
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: const Text('Unread messages'),
                          subtitle: const Text('2 new conversations'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Navigate to messages
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _StatusCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
    );
  }
}
