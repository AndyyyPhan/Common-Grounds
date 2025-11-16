import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/constants/vibe_tags.dart';
import 'package:mobile/models/user_profile.dart';

/// Widget for selecting vibe tags with category organization
/// Allows users to select 3-5 personality tags for better matching
class VibeTagSelector extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback? onChanged;

  const VibeTagSelector({super.key, required this.profile, this.onChanged});

  @override
  State<VibeTagSelector> createState() => _VibeTagSelectorState();
}

class _VibeTagSelectorState extends State<VibeTagSelector> {
  late Set<String> _selectedTags;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedTags = widget.profile.vibeTags.toSet();
  }

  Future<void> _saveSelection() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.profile.uid)
          .update({
            'vibeTags': _selectedTags.toList(),
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          });

      widget.onChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save vibe tags: $e'),
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

  void _toggleTag(String tagId) {
    HapticFeedback.selectionClick();

    setState(() {
      if (_selectedTags.contains(tagId)) {
        _selectedTags.remove(tagId);
      } else {
        _selectedTags.add(tagId);
      }
    });

    _saveSelection();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selectedCount = _selectedTags.length;
    final isOptimal =
        selectedCount >= VibeTags.minRecommendedTags &&
        selectedCount <= VibeTags.maxRecommendedTags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Select Your Vibe',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isOptimal
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOptimal ? Icons.check_circle : Icons.adjust,
                      size: 16,
                      color: isOptimal
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$selectedCount/${VibeTags.maxRecommendedTags}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isOptimal
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Recommendation text
        if (!isOptimal)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Pick ${VibeTags.minRecommendedTags}-${VibeTags.maxRecommendedTags} tags for better matches! +30% profile boost',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Tags by category
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: VibeCategory.values.length,
            itemBuilder: (context, index) {
              final category = VibeCategory.values[index];
              final tags = VibeTags.tagsByCategory[category] ?? [];

              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category header
                    Row(
                      children: [
                        Text(
                          category.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tag chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((tag) {
                        final isSelected = _selectedTags.contains(tag.id);

                        return FilterChip(
                          label: Text(tag.displayText),
                          selected: isSelected,
                          onSelected: (_) => _toggleTag(tag.id),
                          showCheckmark: true,
                          backgroundColor: colorScheme.surface,
                          selectedColor: colorScheme.primaryContainer,
                          checkmarkColor: colorScheme.onPrimaryContainer,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outline,
                          ),
                          elevation: isSelected ? 2 : 0,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Saving indicator
        if (_isSaving) const LinearProgressIndicator(minHeight: 2),
      ],
    );
  }
}
