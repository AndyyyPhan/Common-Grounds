/// Home Page - Main landing page for Common Grounds
///
/// Shows:
/// - Welcome message with user's name
/// - Quick stats (nearby students, common interests, etc.)
/// - Discover section with potential connections
/// - Quick actions (find people, update location, etc.)
library;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/avatar.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/loading_indicator.dart';
import '../services/profile_service.dart';
import '../services/proximity_service.dart';
import '../services/location_service.dart';
import '../services/wave_service.dart';
import '../models/user_profile.dart';
import '../models/wave_models.dart';
import '../utils/chat_utils.dart';
import 'profile_setup_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.onNavigateToTab});

  /// Callback to navigate to a specific tab (0=Home, 1=Messages, 2=Profile)
  final void Function(int tabIndex)? onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<UserProfile?>(
          stream: ProfileService.instance.watchProfile(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingIndicator(message: 'Loading your profile...');
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final profile = snapshot.data;
            if (profile == null) {
              return const Center(child: Text('Profile not found'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                // Clear proximity cache to force fresh data
                ProximityService.instance.clearCache();

                // Refresh location in Firestore
                await LocationService.instance.refreshLocation();

                // Wait for Firestore to propagate
                await Future.delayed(const Duration(milliseconds: 500));

                // Refresh matches
                await ProximityService.instance.refreshMatches(profile);
              },
              child: ListView(
                padding: AppSpacing.screenPadding,
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // Welcome header
                  _buildWelcomeHeader(context, profile),
                  const SizedBox(height: AppSpacing.xl),

                  // Quick stats (live counts)
                  _buildQuickStats(context, user.uid),
                  const SizedBox(height: AppSpacing.xl),

                  // Quick actions
                  _buildQuickActions(context, profile),
                  const SizedBox(height: AppSpacing.xl),

                  // Discover section
                  _buildDiscoverSection(context, profile),
                  const SizedBox(height: AppSpacing.xl),

                  // Tips card
                  _buildTipsCard(context),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Welcome header with user name and avatar
  Widget _buildWelcomeHeader(BuildContext context, UserProfile profile) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return Row(
      children: [
        AppAvatar(
          imageUrl: profile.photoUrl,
          displayName: profile.displayName,
          size: AppSpacing.avatarLg,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).brightness == Brightness.light
                      ? AppColors.textSecondaryLight
                      : AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.displayName ?? 'Student',
                style: Theme.of(context).textTheme.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (profile.classYear != null || profile.major != null) ...[
                const SizedBox(height: 4),
                Text(
                  [
                    if (profile.major != null) profile.major,
                    if (profile.classYear != null)
                      'Class of ${profile.classYear}',
                  ].join(' • '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Quick stats cards - Shows discovery insights
  Widget _buildQuickStats(BuildContext context, String userId) {
    // TODO: Get real stats from Firestore
    // - Nearby: Count of students within proximity (e.g., 1km radius)
    // - Common Interests: Number of students with matching interests
    // - Active Now: Students online/active in the past hour

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.location_on_outlined,
            label: 'Nearby',
            value: '12', // Count of students within ~1km
            sublabel: 'students',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StreamBuilder<List<MutualMatch>>(
            stream: WaveService.instance.watchMutualMatches(userId),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return _StatCard(
                icon: Icons.interests_outlined,
                label: 'Matches',
                value: '$count',
                sublabel: 'mutual',
                color: AppColors.secondary,
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.online_prediction,
            label: 'Active',
            value: '3', // Students active now
            sublabel: 'online',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  /// Quick action buttons
  Widget _buildQuickActions(BuildContext context, UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.my_location,
                label: 'Refresh Location',
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);

                  // Clear ALL caches first
                  ProximityService.instance.clearCache();

                  // Update location in Firestore
                  await LocationService.instance.refreshLocation();

                  // Wait a moment for Firestore to propagate
                  await Future.delayed(const Duration(milliseconds: 500));

                  // Force refresh matches with cleared cache
                  await ProximityService.instance.refreshMatches(profile);

                  if (context.mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Location updated! Refreshing nearby students...',
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ActionButton(
                icon: Icons.person_add_outlined,
                label: 'Edit Interests',
                onTap: () async {
                  // Navigate directly to profile setup page to edit interests
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileSetupPage(profile: profile),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Discover section - Shows auto-matched students nearby
  Widget _buildDiscoverSection(BuildContext context, UserProfile profile) {
    // TODO: Fetch nearby users with similar interests from Firestore
    // Query: users within geohash radius + matching interests
    final hasInterests = profile.interests.isNotEmpty;
    final hasLocation = profile.location?.isVisible ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Students Near You',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Auto-matched by interests',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.light
                        ? AppColors.textSecondaryLight
                        : AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Show appropriate state
        if (!hasLocation)
          AppCard(
            child: EmptyState(
              icon: Icons.location_off_outlined,
              title: 'Location sharing is off',
              message:
                  'Enable location sharing to discover students studying nearby!',
              actionLabel: 'Enable Location',
              onAction: () async {
                // Navigate directly to profile setup to enable location
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileSetupPage(profile: profile),
                  ),
                );
              },
            ),
          )
        else if (!hasInterests)
          AppCard(
            child: EmptyState(
              icon: Icons.interests_outlined,
              title: 'Add your interests',
              message:
                  'Tell us what you\'re passionate about to find students with similar interests!',
              actionLabel: 'Add Interests',
              onAction: () async {
                // Navigate directly to profile setup to add interests
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileSetupPage(profile: profile),
                  ),
                );
              },
            ),
          )
        else
          // Show real matched students
          StreamBuilder<List<ProximityMatch>>(
            stream: ProximityService.instance.watchNearbyMatches(profile),
            builder: (context, snapshot) {
              print('🏠 HOME PAGE: StreamBuilder triggered');
              print(
                '🏠 HOME PAGE: Connection state: ${snapshot.connectionState}',
              );
              print('🏠 HOME PAGE: Has data: ${snapshot.hasData}');
              print('🏠 HOME PAGE: Has error: ${snapshot.hasError}');
              if (snapshot.hasError) {
                print('🏠 HOME PAGE: Error: ${snapshot.error}');
              }
              if (snapshot.hasData) {
                print('🏠 HOME PAGE: Matches count: ${snapshot.data!.length}');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return AppCard(
                  padding: AppSpacing.lg,
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Finding nearby students...',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final matches = snapshot.data ?? [];

              if (matches.isEmpty) {
                return AppCard(
                  padding: AppSpacing.lg,
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No nearby matches found',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Try refreshing your location or adding more interests',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: () async {
                          await LocationService.instance.refreshLocation();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Location'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FilledButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          print(
                            '🧪 TEST: Manually triggering proximity search',
                          );
                          print(
                            '🧪 TEST: Current profile: ${profile.displayName}',
                          );
                          print(
                            '🧪 TEST: Location visible: ${profile.location?.isVisible}',
                          );
                          print(
                            '🧪 TEST: Location coords: ${profile.location?.latitude}, ${profile.location?.longitude}',
                          );
                          print('🧪 TEST: Interests: ${profile.interests}');
                          final matches = await ProximityService.instance
                              .refreshMatches(profile);
                          print('🧪 TEST: Found ${matches.length} matches');
                          if (context.mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Test: Found ${matches.length} matches',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.bug_report),
                        label: const Text('Test Search'),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  for (final match in matches.take(3)) // Show top 3 matches
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _buildMatchCard(context, match),
                    ),
                  if (matches.length > 3)
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to full matches list
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${matches.length - 3} more matches available',
                            ),
                          ),
                        );
                      },
                      child: Text('View ${matches.length - 3} more matches'),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  /// Build a match card for displaying a proximity match
  Widget _buildMatchCard(BuildContext context, ProximityMatch match) {
    final user = match.userProfile;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? const Icon(Icons.person, size: 24)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'Student',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        match.formattedDistance,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.favorite,
                        size: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${match.matchPercentage}% match',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Common interests
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: match.commonInterests.take(3).map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          interest,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.primary,
                                fontSize: 10,
                              ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Wave/Chat button - check mutual match status
            FutureBuilder<bool>(
              future: WaveService.instance.checkMutualMatch(
                currentUser.uid,
                user.uid,
              ),
              builder: (context, snapshot) {
                // Debug logging
                if (snapshot.hasError) {
                  debugPrint(
                    '❌ Error checking mutual match: ${snapshot.error}',
                  );
                }
                if (snapshot.hasData) {
                  debugPrint(
                    '🔍 Mutual match check for ${user.displayName}: ${snapshot.data}',
                  );
                }

                final hasMutualMatch = snapshot.data ?? false;

                if (hasMutualMatch) {
                  // Both waved - show chat button
                  return IconButton(
                    onPressed: () async {
                      await ChatUtils.startConversationWith(context, user.uid);
                    },
                    icon: const Icon(Icons.chat_bubble),
                    tooltip: 'Start conversation',
                    color: AppColors.primary,
                  );
                } else {
                  // No mutual match yet - show wave button
                  return FutureBuilder<WaveRequest?>(
                    future: WaveService.instance.getWaveTo(
                      currentUser.uid,
                      user.uid,
                    ),
                    builder: (context, waveSnapshot) {
                      final existingWave = waveSnapshot.data;

                      if (existingWave != null &&
                          existingWave.status == WaveStatus.pending) {
                        // Already waved - show pending state
                        return IconButton(
                          onPressed: null,
                          icon: const Icon(Icons.back_hand),
                          tooltip: 'Wave sent',
                          color: AppColors.textSecondaryLight,
                        );
                      } else {
                        // Can wave - show wave button
                        return IconButton(
                          onPressed: () async {
                            await _handleWave(context, currentUser.uid, user);
                          },
                          icon: const Icon(Icons.back_hand_outlined),
                          tooltip: 'Wave to connect',
                          color: AppColors.primary,
                        );
                      }
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Handle sending a wave to another user
  Future<void> _handleWave(
    BuildContext context,
    String currentUserId,
    UserProfile otherUser,
  ) async {
    try {
      // Get current user profile
      final currentUserProfile = await ProfileService.instance.getProfile(
        currentUserId,
      );
      if (currentUserProfile == null) {
        throw Exception('Could not load your profile');
      }

      // Create profile maps
      final currentUserProfileMap = {
        'displayName': currentUserProfile.displayName,
        'photoUrl': currentUserProfile.photoUrl,
      };

      final otherUserProfileMap = {
        'displayName': otherUser.displayName,
        'photoUrl': otherUser.photoUrl,
      };

      // Send wave
      final waveId = await WaveService.instance.sendWave(
        senderId: currentUserId,
        receiverId: otherUser.uid,
        senderProfile: currentUserProfileMap,
        receiverProfile: otherUserProfileMap,
      );

      if (waveId != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Wave sent to ${otherUser.displayName ?? "student"}!',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already waved at this person'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send wave: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Tips card - Helpful hints about how the app works
  Widget _buildTipsCard(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Icon(
              Icons.info_outline,
              color: AppColors.info,
              size: AppSpacing.iconLg,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How it works',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: AppColors.info),
                ),
                const SizedBox(height: 4),
                Text(
                  'Common Grounds automatically finds students nearby with similar interests. You\'ll get notified when there\'s a potential match!',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat card widget
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.sublabel,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? sublabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: AppSpacing.sm,
      child: Column(
        children: [
          Icon(icon, color: color, size: AppSpacing.iconMd),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          if (sublabel != null)
            Text(
              sublabel!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context).brightness == Brightness.light
                    ? AppColors.textSecondaryLight
                    : AppColors.textSecondaryDark,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

/// Action button widget
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: AppSpacing.md,
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: AppSpacing.iconLg),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
