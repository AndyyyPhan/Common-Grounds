import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/location_service.dart';
import 'profile_setup_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return StreamBuilder<UserProfile?>(
      stream: ProfileService.instance.watchProfile(user.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            appBar: _AppBar(title: 'My Profile'),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: const _AppBar(title: 'My Profile'),
            body: Center(child: Text('Error loading profile: ${snap.error}')),
          );
        }
        final profile = snap.data;
        if (profile == null) {
          return Scaffold(
            appBar: const _AppBar(title: 'My Profile'),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No profile found.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      final fallback = UserProfile(
                        uid: user.uid,
                        displayName: user.displayName,
                        photoUrl: user.photoURL,
                        bio: null,
                        classYear: null,
                        major: null,
                        interests: const [],
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      if (!context.mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProfileSetupPage(profile: fallback),
                        ),
                      );
                    },
                    child: const Text('Create profile'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: _AppBar(
            title: 'My Profile',
            actions: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileSetupPage(profile: profile),
                    ),
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              // Force a one-time fetch to refresh cache
              await FirebaseFirestore.instance
                  .doc('users/${profile.uid}')
                  .get(const GetOptions(source: Source.server));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: (profile.photoUrl != null)
                          ? NetworkImage(profile.photoUrl!)
                          : null,
                      child: (profile.photoUrl == null)
                          ? const Icon(Icons.person, size: 36)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.displayName ?? 'Friend',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            FirebaseAuth.instance.currentUser?.email ?? '',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _KV('Major', profile.major),
                _KV('Class year', profile.classYear),
                if ((profile.bio ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Bio',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(profile.bio!),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Interests',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (profile.interests.isEmpty)
                  const Text('No interests selected yet.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in profile.interests)
                        Chip(label: Text(tag)),
                    ],
                  ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _LocationSettings(profile: profile),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LocationSettings extends StatefulWidget {
  final UserProfile profile;
  const _LocationSettings({required this.profile});

  @override
  State<_LocationSettings> createState() => _LocationSettingsState();
}

class _LocationSettingsState extends State<_LocationSettings> {
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    final location = widget.profile.location;
    final isVisible = location?.isVisible ?? false;
    final lastUpdated = location?.lastUpdated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, size: 20, color: Colors.black54),
            const SizedBox(width: 8),
            const Text(
              'Location Sharing',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Share my location',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Help nearby students with similar interests find you',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isVisible,
                      onChanged: _isToggling
                          ? null
                          : (value) async {
                              setState(() => _isToggling = true);
                              // Capture ScaffoldMessenger before async gap
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await LocationService.instance
                                    .setLocationVisibility(
                                  widget.profile.uid,
                                  value,
                                );
                                if (mounted && value) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Location sharing enabled',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isToggling = false);
                                }
                              }
                            },
                    ),
                  ],
                ),
                if (lastUpdated != null) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        'Last updated: ${_formatTimestamp(lastUpdated)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
                if (isVisible) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      // Capture ScaffoldMessenger before async gap
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await LocationService.instance.refreshLocation();
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Location refreshed'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Error refreshing: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh now'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your exact location is never shared. We use coarse location data to find nearby students within approximately 1-2km.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  const _AppBar({required this.title, this.actions});
  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title), actions: actions);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _KV extends StatelessWidget {
  final String label;
  final String? value;
  const _KV(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value!)),
        ],
      ),
    );
  }
}
