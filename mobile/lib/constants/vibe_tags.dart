/// Vibe Tags for personality-based matching
/// Inspired by Bumble's badge system - quick, visual, fun
library;

/// Categories of vibe tags
enum VibeCategory {
  socialEnergy('Social Energy', '🎭'),
  studyStyle('Study Style', '📚'),
  schedule('Schedule', '⏰'),
  energy('Energy', '⚡'),
  ambience('Ambience', '🎵');

  const VibeCategory(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// Individual vibe tag
class VibeTag {
  final String id;
  final String label;
  final String emoji;
  final VibeCategory category;
  final String? description;

  const VibeTag({
    required this.id,
    required this.label,
    required this.emoji,
    required this.category,
    this.description,
  });

  /// Display text with emoji
  String get displayText => '$emoji $label';

  /// Check if this tag is compatible with another tag
  bool isCompatibleWith(VibeTag other) {
    // Same tag = perfect match
    if (id == other.id) return true;

    // Conflicting pairs (different category, opposite vibes)
    const conflicts = {
      'morning_person': ['night_owl'],
      'night_owl': ['morning_person'],
      'extrovert': ['introvert'],
      'introvert': ['extrovert'],
      'high_energy': ['chill'],
      'chill': ['high_energy'],
      'music_on': ['silence'],
      'silence': ['music_on'],
    };

    if (conflicts[id]?.contains(other.id) ?? false) {
      return false;
    }

    // Everything else is compatible or complementary
    return true;
  }

  /// Calculate compatibility score with another tag
  /// 1.0 = perfect match, 0.5 = compatible/complementary, 0.0 = conflicting
  double compatibilityScore(VibeTag other) {
    if (id == other.id) return 1.0;
    if (!isCompatibleWith(other)) return 0.0;
    return 0.5; // Compatible but not identical
  }
}

/// All available vibe tags
class VibeTags {
  // Social Energy
  static const extrovert = VibeTag(
    id: 'extrovert',
    label: 'Extrovert',
    emoji: '🎉',
    category: VibeCategory.socialEnergy,
    description: 'I recharge around people',
  );

  static const introvert = VibeTag(
    id: 'introvert',
    label: 'Introvert',
    emoji: '📚',
    category: VibeCategory.socialEnergy,
    description: 'I recharge alone',
  );

  static const ambivert = VibeTag(
    id: 'ambivert',
    label: 'Ambivert',
    emoji: '🤝',
    category: VibeCategory.socialEnergy,
    description: 'Depends on my mood',
  );

  // Study Style
  static const groupStudy = VibeTag(
    id: 'group_study',
    label: 'Group study',
    emoji: '👥',
    category: VibeCategory.studyStyle,
    description: 'Love studying with others',
  );

  static const soloFocus = VibeTag(
    id: 'solo_focus',
    label: 'Solo focus',
    emoji: '🧘',
    category: VibeCategory.studyStyle,
    description: 'I study best alone',
  );

  static const coffeeShop = VibeTag(
    id: 'coffee_shop',
    label: 'Coffee shop regular',
    emoji: '☕',
    category: VibeCategory.studyStyle,
    description: 'Love public study spots',
  );

  // Schedule
  static const morningPerson = VibeTag(
    id: 'morning_person',
    label: 'Morning person',
    emoji: '🌅',
    category: VibeCategory.schedule,
    description: 'Early bird gets the worm',
  );

  static const nightOwl = VibeTag(
    id: 'night_owl',
    label: 'Night owl',
    emoji: '🌙',
    category: VibeCategory.schedule,
    description: 'Best work happens at night',
  );

  static const flexible = VibeTag(
    id: 'flexible',
    label: 'Flexible',
    emoji: '⏰',
    category: VibeCategory.schedule,
    description: 'I adapt to any schedule',
  );

  // Energy
  static const highEnergy = VibeTag(
    id: 'high_energy',
    label: 'High energy',
    emoji: '⚡',
    category: VibeCategory.energy,
    description: 'Always on the go',
  );

  static const chill = VibeTag(
    id: 'chill',
    label: 'Chill',
    emoji: '😌',
    category: VibeCategory.energy,
    description: 'Relaxed and easygoing',
  );

  static const focused = VibeTag(
    id: 'focused',
    label: 'Focused',
    emoji: '🎯',
    category: VibeCategory.energy,
    description: 'Laser-focused when working',
  );

  // Ambience
  static const musicOn = VibeTag(
    id: 'music_on',
    label: 'Music on',
    emoji: '🎵',
    category: VibeCategory.ambience,
    description: 'Lo-fi beats to study to',
  );

  static const silence = VibeTag(
    id: 'silence',
    label: 'Silence',
    emoji: '🤫',
    category: VibeCategory.ambience,
    description: 'Complete quiet please',
  );

  static const studyBreaks = VibeTag(
    id: 'study_breaks',
    label: 'Study breaks',
    emoji: '🎮',
    category: VibeCategory.ambience,
    description: 'Regular breaks keep me fresh',
  );

  /// All tags organized by category
  static const Map<VibeCategory, List<VibeTag>> tagsByCategory = {
    VibeCategory.socialEnergy: [extrovert, introvert, ambivert],
    VibeCategory.studyStyle: [groupStudy, soloFocus, coffeeShop],
    VibeCategory.schedule: [morningPerson, nightOwl, flexible],
    VibeCategory.energy: [highEnergy, chill, focused],
    VibeCategory.ambience: [musicOn, silence, studyBreaks],
  };

  /// All tags as flat list
  static const List<VibeTag> all = [
    // Social Energy
    extrovert,
    introvert,
    ambivert,
    // Study Style
    groupStudy,
    soloFocus,
    coffeeShop,
    // Schedule
    morningPerson,
    nightOwl,
    flexible,
    // Energy
    highEnergy,
    chill,
    focused,
    // Ambience
    musicOn,
    silence,
    studyBreaks,
  ];

  /// Get tag by ID
  static VibeTag? getById(String id) {
    try {
      return all.firstWhere((tag) => tag.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get tags by IDs
  static List<VibeTag> getByIds(List<String> ids) {
    return ids.map((id) => getById(id)).whereType<VibeTag>().toList();
  }

  /// Calculate overall compatibility between two sets of vibe tags
  /// Returns score from 0.0 (incompatible) to 1.0 (perfect match)
  static double calculateCompatibility(List<String> tags1, List<String> tags2) {
    if (tags1.isEmpty || tags2.isEmpty) return 0.5; // Neutral

    final vibeTags1 = getByIds(tags1);
    final vibeTags2 = getByIds(tags2);

    if (vibeTags1.isEmpty || vibeTags2.isEmpty) return 0.5;

    double totalScore = 0.0;
    int comparisons = 0;

    // Compare each tag from user1 with each tag from user2
    for (final tag1 in vibeTags1) {
      for (final tag2 in vibeTags2) {
        totalScore += tag1.compatibilityScore(tag2);
        comparisons++;
      }
    }

    return comparisons > 0 ? totalScore / comparisons : 0.5;
  }

  /// Get common vibe tags between two users
  static List<VibeTag> getCommonTags(List<String> tags1, List<String> tags2) {
    final set1 = tags1.toSet();
    final set2 = tags2.toSet();
    final commonIds = set1.intersection(set2);
    return getByIds(commonIds.toList());
  }

  /// Recommended minimum and maximum tags to select
  static const int minRecommendedTags = 3;
  static const int maxRecommendedTags = 5;

  /// Profile completion boost for adding vibe tags
  static const double profileCompletionBoost = 0.30; // 30% boost
}
