import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/constants/proximity_constants.dart';
import 'package:mobile/models/user_profile.dart';
import 'package:mobile/services/profile_service.dart';

/// Search radius settings widget with Material Design 3 slider
/// Allows users to configure their proximity search radius
class SearchRadiusSettings extends StatefulWidget {
  final UserProfile profile;

  const SearchRadiusSettings({super.key, required this.profile});

  @override
  State<SearchRadiusSettings> createState() => _SearchRadiusSettingsState();
}

class _SearchRadiusSettingsState extends State<SearchRadiusSettings> {
  late double _currentRadius;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Use effective search radius (user preference or default)
    _currentRadius = widget.profile.effectiveSearchRadiusKm;
  }

  Future<void> _saveRadius(double newRadius) async {
    if (newRadius == widget.profile.searchRadiusKm) {
      // No change, skip save
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Create updated profile with new search radius
      final updatedProfile = UserProfile(
        uid: widget.profile.uid,
        displayName: widget.profile.displayName,
        photoUrl: widget.profile.photoUrl,
        bio: widget.profile.bio,
        classYear: widget.profile.classYear,
        major: widget.profile.major,
        interests: widget.profile.interests,
        createdAt: widget.profile.createdAt,
        updatedAt: DateTime.now(),
        location: widget.profile.location,
        searchRadiusKm: newRadius,
      );

      await ProfileService.instance.upsertProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Search radius updated to ${formatRadius(newRadius)}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating radius: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.radar, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Search Radius',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Find people within walking distance',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Current radius display
            Center(
              child: Column(
                children: [
                  Text(
                    formatRadius(_currentRadius),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getRadiusDescription(_currentRadius),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: colorScheme.primary,
                inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.3),
                thumbColor: colorScheme.primary,
                overlayColor: colorScheme.primary.withValues(alpha: 0.2),
                valueIndicatorColor: colorScheme.primary,
                valueIndicatorTextStyle: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Slider(
                value: _currentRadius,
                min: kMinSearchRadiusKm,
                max: kMaxSearchRadiusKm,
                divisions: 10, // 0.25 km increments
                label: formatRadius(_currentRadius),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        // Haptic feedback for better UX
                        HapticFeedback.selectionClick();
                        setState(() {
                          _currentRadius = value;
                        });
                      },
                onChangeEnd: (value) {
                  // Save when user releases slider
                  _saveRadius(value);
                },
              ),
            ),

            // Min/Max labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatRadius(kMinSearchRadiusKm),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  formatRadius(kMaxSearchRadiusKm),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            if (_isSaving) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  String _getRadiusDescription(double radiusKm) {
    if (radiusKm <= 0.7) {
      return 'Same building • 5 min walk';
    } else if (radiusKm <= 1.2) {
      return 'Nearby area • 10 min walk';
    } else if (radiusKm <= 2.0) {
      return 'Campus area • 20 min walk';
    } else {
      return 'Full campus • 30 min walk';
    }
  }
}
