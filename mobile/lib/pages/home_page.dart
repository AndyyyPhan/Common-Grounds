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
import '../models/user_profile.dart';
import 'profile_setup_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    this.onNavigateToTab,
  });

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
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final profile = snapshot.data;
            if (profile == null) {
              return const Center(child: Text('Profile not found'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                // Refresh profile data
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView(
                padding: AppSpacing.screenPadding,
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // Welcome header
                  _buildWelcomeHeader(context, profile),
                  const SizedBox(height: AppSpacing.xl),

                  // Quick stats
                  _buildQuickStats(context),
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
                    if (profile.classYear != null) 'Class of ${profile.classYear}',
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
  Widget _buildQuickStats(BuildContext context) {
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
          child: _StatCard(
            icon: Icons.interests_outlined,
            label: 'Matches',
            value: '5', // Students with common interests nearby
            sublabel: 'similar',
            color: AppColors.secondary,
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
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.my_location,
                label: 'Refresh Location',
                onTap: () {
                  // TODO: Manually trigger location update
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location updated! Looking for nearby students...')),
                  );
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
          // TODO: Show real matched students here
          // For now, show placeholder
          AppCard(
            padding: AppSpacing.lg,
            child: Column(
              children: [
                Icon(
                  Icons.radar,
                  size: 64,
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Scanning for nearby students...',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'We\'ll notify you when we find students with similar interests nearby',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.info,
                      ),
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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
          Icon(
            icon,
            color: AppColors.primary,
            size: AppSpacing.iconLg,
          ),
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
