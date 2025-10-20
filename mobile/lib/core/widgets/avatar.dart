/// Avatar Widget
///
/// Reusable avatar component with network image caching and fallback.
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';

/// Circular avatar with cached network image and fallback
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.displayName,
    this.size = AppSpacing.avatarMd,
    this.showOnlineStatus = false,
    this.isOnline = false,
  });

  final String? imageUrl;
  final String? displayName;
  final double size;
  final bool showOnlineStatus;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Avatar circle
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppColors.borderLight
                  : AppColors.borderDark,
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildPlaceholder(),
                    errorWidget: (context, url, error) => _buildFallback(),
                  )
                : _buildFallback(),
          ),
        ),

        // Online status indicator
        if (showOnlineStatus)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.online : AppColors.offline,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceVariantLight,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildFallback() {
    final initial = displayName?.isNotEmpty == true
        ? displayName![0].toUpperCase()
        : '?';

    return Container(
      color: AppColors.primary,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Small avatar for list items
class SmallAvatar extends StatelessWidget {
  const SmallAvatar({
    super.key,
    this.imageUrl,
    this.displayName,
    this.showOnlineStatus = false,
    this.isOnline = false,
  });

  final String? imageUrl;
  final String? displayName;
  final bool showOnlineStatus;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return AppAvatar(
      imageUrl: imageUrl,
      displayName: displayName,
      size: AppSpacing.avatarSm,
      showOnlineStatus: showOnlineStatus,
      isOnline: isOnline,
    );
  }
}

/// Large avatar for profile pages
class LargeAvatar extends StatelessWidget {
  const LargeAvatar({super.key, this.imageUrl, this.displayName});

  final String? imageUrl;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    return AppAvatar(
      imageUrl: imageUrl,
      displayName: displayName,
      size: AppSpacing.avatarXl,
    );
  }
}
