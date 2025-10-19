import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/privacy_service.dart';
import '../models/privacy_settings.dart';
import 'profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final PrivacyService _privacyService = PrivacyService.instance;
  final AuthService _authService = AuthService.instance;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: StreamBuilder<PrivacySettings?>(
        stream: _privacyService.watchPrivacySettings(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = snapshot.data;
          if (settings == null) {
            return const Center(
              child: Text('Error loading settings'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Section
              _SettingsSection(
                title: 'Profile',
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Edit Profile'),
                    subtitle: const Text('Update your information and interests'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Privacy Section
              _SettingsSection(
                title: 'Privacy & Safety',
                children: [
                  SwitchListTile(
                    title: const Text('Location Sharing'),
                    subtitle: const Text('Allow app to use your location for matching'),
                    value: settings.locationSharingEnabled,
                    onChanged: (value) {
                      _privacyService.updateLocationSharing(user.uid, value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Notifications'),
                    subtitle: const Text('Receive notifications for matches and messages'),
                    value: settings.notificationsEnabled,
                    onChanged: (value) {
                      _privacyService.updateNotifications(user.uid, value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Profile Visibility'),
                    subtitle: const Text('Allow others to see your profile'),
                    value: settings.profileVisible,
                    onChanged: (value) {
                      _privacyService.updateProfileVisibility(user.uid, value);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('Location Precision'),
                    subtitle: Text(_getLocationPrecisionText(settings.locationPrecision)),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showLocationPrecisionDialog(settings),
                  ),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Daily Match Limit'),
                    subtitle: Text('${settings.maxDailyMatches} matches per day'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showMatchLimitDialog(settings),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Data Sharing Section
              _SettingsSection(
                title: 'Data Sharing',
                children: [
                  SwitchListTile(
                    title: const Text('Share Interests'),
                    subtitle: const Text('Show your interests to potential matches'),
                    value: settings.shareInterests,
                    onChanged: (value) {
                      _privacyService.updateDataSharing(
                        user.uid,
                        shareInterests: value,
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Share Class Year'),
                    subtitle: const Text('Show your graduation year'),
                    value: settings.shareClassYear,
                    onChanged: (value) {
                      _privacyService.updateDataSharing(
                        user.uid,
                        shareClassYear: value,
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Share Major'),
                    subtitle: const Text('Show your academic major'),
                    value: settings.shareMajor,
                    onChanged: (value) {
                      _privacyService.updateDataSharing(
                        user.uid,
                        shareMajor: value,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Account Section
              _SettingsSection(
                title: 'Account',
                children: [
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('Privacy Summary'),
                    subtitle: const Text('View your privacy settings summary'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showPrivacySummary(settings),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                    subtitle: const Text('Permanently delete your account and data'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showDeleteAccountDialog(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Sign Out
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showSignOutDialog(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ),

              const SizedBox(height: 32),

              // App Info
              Center(
                child: Column(
                  children: [
                    Text(
                      'Common Grounds v1.0.0',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Made with ❤️ for college students',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getLocationPrecisionText(double precision) {
    if (precision <= 0.2) return 'Very Precise (within ~20m)';
    if (precision <= 0.4) return 'Precise (within ~50m)';
    if (precision <= 0.6) return 'Medium (within ~100m)';
    if (precision <= 0.8) return 'Coarse (within ~200m)';
    return 'Very Coarse (within ~500m)';
  }

  void _showLocationPrecisionDialog(PrivacySettings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Precision'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose how precise your location sharing should be:'),
            const SizedBox(height: 16),
            Slider(
              value: settings.locationPrecision,
              min: 0.0,
              max: 1.0,
              divisions: 5,
              label: _getLocationPrecisionText(settings.locationPrecision),
              onChanged: (value) {
                setState(() {
                  // Update local state for immediate feedback
                });
                _privacyService.updateLocationPrecision(
                  FirebaseAuth.instance.currentUser!.uid,
                  value,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showMatchLimitDialog(PrivacySettings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Match Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set the maximum number of matches you want per day:'),
            const SizedBox(height: 16),
            Slider(
              value: settings.maxDailyMatches.toDouble(),
              min: 1.0,
              max: 20.0,
              divisions: 19,
              label: '${settings.maxDailyMatches} matches',
              onChanged: (value) {
                setState(() {
                  // Update local state for immediate feedback
                });
                _privacyService.updateDailyMatchLimit(
                  FirebaseAuth.instance.currentUser!.uid,
                  value.round(),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySummary(PrivacySettings settings) async {
    final summary = await _privacyService.getPrivacySummary(
      FirebaseAuth.instance.currentUser!.uid,
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Privacy Summary'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _PrivacySummaryItem(
                  title: 'Location Sharing',
                  value: summary['locationSharing'] == true ? 'Enabled' : 'Disabled',
                ),
                _PrivacySummaryItem(
                  title: 'Notifications',
                  value: summary['notifications'] == true ? 'Enabled' : 'Disabled',
                ),
                _PrivacySummaryItem(
                  title: 'Profile Visibility',
                  value: summary['profileVisible'] == true ? 'Visible' : 'Hidden',
                ),
                _PrivacySummaryItem(
                  title: 'Location Precision',
                  value: _getLocationPrecisionText(summary['locationPrecision'] ?? 0.5),
                ),
                _PrivacySummaryItem(
                  title: 'Daily Match Limit',
                  value: '${summary['maxDailyMatches']} matches',
                ),
                _PrivacySummaryItem(
                  title: 'Share Interests',
                  value: summary['shareInterests'] == true ? 'Yes' : 'No',
                ),
                _PrivacySummaryItem(
                  title: 'Share Class Year',
                  value: summary['shareClassYear'] == true ? 'Yes' : 'No',
                ),
                _PrivacySummaryItem(
                  title: 'Share Major',
                  value: summary['shareMajor'] == true ? 'Yes' : 'No',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _authService.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmationDialog();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text(
          'Type "DELETE" to confirm account deletion:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion feature coming soon'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _PrivacySummaryItem extends StatelessWidget {
  final String title;
  final String value;

  const _PrivacySummaryItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
