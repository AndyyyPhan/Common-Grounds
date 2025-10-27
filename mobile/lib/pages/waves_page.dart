/// Waves Page - Manage wave requests and see mutual matches
///
/// Shows:
/// - Incoming waves (people who waved at you)
/// - Outgoing waves (people you waved at)
/// - Mutual matches (both waved)
library;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/loading_indicator.dart';
import '../services/wave_service.dart';
import '../models/wave_models.dart';
import '../utils/chat_utils.dart';

class WavesPage extends StatelessWidget {
  const WavesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Waves'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Received', icon: Icon(Icons.inbox)),
              Tab(text: 'Sent', icon: Icon(Icons.send)),
              Tab(text: 'Matched', icon: Icon(Icons.favorite)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _IncomingWavesTab(userId: user.uid),
            _OutgoingWavesTab(userId: user.uid),
            _MutualMatchesTab(userId: user.uid),
          ],
        ),
      ),
    );
  }
}

/// Tab showing incoming waves (waves received from others)
class _IncomingWavesTab extends StatelessWidget {
  const _IncomingWavesTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WaveRequest>>(
      stream: WaveService.instance.watchIncomingWaves(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator(message: 'Loading waves...');
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final waves = snapshot.data ?? [];

        if (waves.isEmpty) {
          return const EmptyState(
            icon: Icons.back_hand_outlined,
            title: 'No waves yet',
            message: 'When someone waves at you, they\'ll appear here!',
          );
        }

        return ListView.builder(
          padding: AppSpacing.screenPadding,
          itemCount: waves.length,
          itemBuilder: (context, index) {
            final wave = waves[index];
            return _buildIncomingWaveCard(context, wave);
          },
        );
      },
    );
  }

  Widget _buildIncomingWaveCard(BuildContext context, WaveRequest wave) {
    final senderName =
        wave.senderProfile['displayName'] as String? ?? 'Someone';
    final senderPhoto = wave.senderProfile['photoUrl'] as String?;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundImage: senderPhoto != null
                  ? NetworkImage(senderPhoto)
                  : null,
              child: senderPhoto == null
                  ? const Icon(Icons.person, size: 28)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$senderName waved at you!',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wave.timeAgo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Accept button
                IconButton(
                  onPressed: () async {
                    final matchId = await WaveService.instance.acceptWave(
                      wave.id,
                    );
                    if (matchId != null && context.mounted) {
                      // Show celebration modal!
                      await _showMatchCelebration(
                        context,
                        senderName,
                        senderPhoto,
                        wave.senderId,
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle),
                  color: AppColors.success,
                  tooltip: 'Wave back',
                ),

                // Decline button
                IconButton(
                  onPressed: () async {
                    final success = await WaveService.instance.declineWave(
                      wave.id,
                    );
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Wave declined')),
                      );
                    }
                  },
                  icon: const Icon(Icons.close),
                  color: AppColors.error,
                  tooltip: 'Decline',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show "It's a Match!" celebration modal
  Future<void> _showMatchCelebration(
    BuildContext context,
    String matchName,
    String? matchPhoto,
    String matchUserId,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MatchCelebrationDialog(
        matchName: matchName,
        matchPhoto: matchPhoto,
        matchUserId: matchUserId,
      ),
    );
  }
}

/// Animated celebration dialog for mutual matches
class _MatchCelebrationDialog extends StatefulWidget {
  const _MatchCelebrationDialog({
    required this.matchName,
    required this.matchPhoto,
    required this.matchUserId,
  });

  final String matchName;
  final String? matchPhoto;
  final String matchUserId;

  @override
  State<_MatchCelebrationDialog> createState() =>
      _MatchCelebrationDialogState();
}

class _MatchCelebrationDialogState extends State<_MatchCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated heart icon
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: const Icon(
                        Icons.favorite,
                        size: 64,
                        color: AppColors.error,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Title
                Text(
                  "It's a Match!",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Subtitle
                Text(
                  'You and ${widget.matchName} liked each other!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Profile photo with animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: widget.matchPhoto != null
                            ? NetworkImage(widget.matchPhoto!)
                            : null,
                        child: widget.matchPhoto == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Actions
                Column(
                  children: [
                    // Send message button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await ChatUtils.startConversationWith(
                            context,
                            widget.matchUserId,
                          );
                        },
                        icon: const Icon(Icons.chat_bubble),
                        label: const Text('Send Message'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Keep browsing button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(AppSpacing.md),
                        ),
                        child: const Text('Keep Browsing'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tab showing outgoing waves (waves sent to others)
class _OutgoingWavesTab extends StatelessWidget {
  const _OutgoingWavesTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WaveRequest>>(
      stream: WaveService.instance.watchOutgoingWaves(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator(message: 'Loading waves...');
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final waves = snapshot.data ?? [];

        if (waves.isEmpty) {
          return const EmptyState(
            icon: Icons.back_hand_outlined,
            title: 'No waves sent',
            message: 'Wave at someone from the home page to connect!',
          );
        }

        return ListView.builder(
          padding: AppSpacing.screenPadding,
          itemCount: waves.length,
          itemBuilder: (context, index) {
            final wave = waves[index];
            return _buildOutgoingWaveCard(context, wave);
          },
        );
      },
    );
  }

  Widget _buildOutgoingWaveCard(BuildContext context, WaveRequest wave) {
    final receiverName =
        wave.receiverProfile['displayName'] as String? ?? 'Someone';
    final receiverPhoto = wave.receiverProfile['photoUrl'] as String?;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundImage: receiverPhoto != null
                  ? NetworkImage(receiverPhoto)
                  : null,
              child: receiverPhoto == null
                  ? const Icon(Icons.person, size: 28)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You waved at $receiverName',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sent ${wave.timeAgo} • Waiting for response',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // Cancel button
            IconButton(
              onPressed: () async {
                // Show confirmation dialog
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cancel wave?'),
                    content: Text('Remove your wave to $receiverName?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Keep'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final success = await WaveService.instance.cancelWave(
                    wave.id,
                  );
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wave cancelled')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete_outline),
              color: AppColors.textSecondaryLight,
              tooltip: 'Cancel wave',
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab showing mutual matches (both users waved)
class _MutualMatchesTab extends StatelessWidget {
  const _MutualMatchesTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MutualMatch>>(
      stream: WaveService.instance.watchMutualMatches(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator(message: 'Loading matches...');
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final matches = snapshot.data ?? [];

        if (matches.isEmpty) {
          return const EmptyState(
            icon: Icons.favorite_outline,
            title: 'No matches yet',
            message:
                'When you both wave at each other, you\'ll match and can start chatting!',
          );
        }

        return ListView.builder(
          padding: AppSpacing.screenPadding,
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            return _buildMatchCard(context, match, userId);
          },
        );
      },
    );
  }

  Widget _buildMatchCard(
    BuildContext context,
    MutualMatch match,
    String currentUserId,
  ) {
    final otherProfile = match.getOtherUserProfile(currentUserId);
    final otherName = otherProfile['displayName'] as String? ?? 'Someone';
    final otherPhoto = otherProfile['photoUrl'] as String?;
    final otherUserId = match.getOtherUserId(currentUserId);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundImage: otherPhoto != null
                  ? NetworkImage(otherPhoto)
                  : null,
              child: otherPhoto == null
                  ? const Icon(Icons.person, size: 28)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Matched with $otherName',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You can now message each other',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // Chat button
            IconButton(
              onPressed: () async {
                await ChatUtils.startConversationWith(context, otherUserId);
              },
              icon: const Icon(Icons.chat_bubble),
              color: AppColors.primary,
              tooltip: 'Start chat',
            ),
          ],
        ),
      ),
    );
  }
}
