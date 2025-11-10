import 'dart:math';
import 'package:mobile/constants/interest_categories.dart';

/// Utilities for normalizing and categorizing user interests
/// Uses Levenshtein distance for fuzzy matching and synonym mapping

/// Normalizes a custom interest to match existing predefined interests
/// Returns the canonical interest name if a match is found, or a cleaned
/// version of the custom interest if no match exists
String normalizeInterest(String custom) {
  final trimmed = custom.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  String normalized = trimmed.toLowerCase();

  // Step 1: Check exact synonym match (fast path)
  if (kInterestSynonyms.containsKey(normalized)) {
    return kInterestSynonyms[normalized]!;
  }

  // Step 2: Check fuzzy match against all predefined interests
  // Use Levenshtein distance <= 2 for similar interests
  String? fuzzyMatch = _findFuzzyMatch(normalized, kAllInterests);
  if (fuzzyMatch != null) {
    return fuzzyMatch;
  }

  // Step 3: Check fuzzy match against synonym keys
  // This catches misspellings of common variations
  for (final synonym in kInterestSynonyms.keys) {
    if (_levenshteinDistance(normalized, synonym) <= 2) {
      return kInterestSynonyms[synonym]!;
    }
  }

  // Step 4: No match found - return cleaned custom interest
  // Capitalize each word for consistency
  return _capitalizeWords(custom.trim());
}

/// Attempts to categorize a custom interest into one of the predefined categories
/// Returns null if the interest doesn't clearly fit any category
InterestCategory? categorizeCustomInterest(String interest) {
  final normalized = interest.toLowerCase();

  // Check if it's already a predefined interest
  final category = getCategoryForInterest(interest);
  if (category != null) {
    return category;
  }

  // Keyword-based categorization for custom interests
  // Academic keywords
  if (_containsAny(normalized, [
    'study',
    'research',
    'class',
    'course',
    'learn',
    'academic',
    'science',
    'engineering',
    'math',
    'code',
    'program',
    'tech',
  ])) {
    return InterestCategory.academic;
  }

  // Sports keywords
  if (_containsAny(normalized, [
    'sport',
    'exercise',
    'fitness',
    'gym',
    'workout',
    'run',
    'swim',
    'play',
    'team',
    'practice',
    'training',
  ])) {
    return InterestCategory.sports;
  }

  // Entertainment keywords
  if (_containsAny(normalized, [
    'game',
    'play',
    'watch',
    'movie',
    'show',
    'series',
    'stream',
    'entertainment',
  ])) {
    return InterestCategory.entertainment;
  }

  // Creative keywords
  if (_containsAny(normalized, [
    'art',
    'music',
    'create',
    'creative',
    'design',
    'photo',
    'paint',
    'draw',
    'write',
    'perform',
  ])) {
    return InterestCategory.creative;
  }

  // Social keywords
  if (_containsAny(normalized, [
    'food',
    'eat',
    'drink',
    'coffee',
    'restaurant',
    'social',
    'party',
    'hang',
    'chill',
  ])) {
    return InterestCategory.social;
  }

  // Lifestyle keywords
  if (_containsAny(normalized, [
    'travel',
    'nature',
    'outdoor',
    'environment',
    'lifestyle',
    'wellness',
    'volunteer',
    'community',
  ])) {
    return InterestCategory.lifestyle;
  }

  // No clear category match
  return null;
}

/// Groups a list of interests by category
/// Useful for displaying interests in the UI
Map<InterestCategory, List<String>> groupInterestsByCategory(
  List<String> interests,
) {
  final Map<InterestCategory, List<String>> grouped = {};

  for (final interest in interests) {
    final category =
        getCategoryForInterest(interest) ?? categorizeCustomInterest(interest);

    if (category != null) {
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(interest);
    }
  }

  return grouped;
}

/// Validates if a list of interests meets minimum requirements
/// Returns error message if invalid, null if valid
String? validateInterestSelection(List<String> interests) {
  if (interests.isEmpty) {
    return 'Please select at least 5 interests';
  }

  if (interests.length < 5) {
    return 'Please select at least ${5 - interests.length} more interests';
  }

  // Check for reasonable category distribution
  // At least 2 different categories recommended
  final categories = interests
      .map((i) => getCategoryForInterest(i) ?? categorizeCustomInterest(i))
      .where((c) => c != null)
      .toSet();

  if (categories.length < 2) {
    return 'Please select interests from at least 2 different categories';
  }

  return null; // Valid
}

// ============================================================================
// Private Helper Functions
// ============================================================================

/// Finds a fuzzy match for a string against a list of candidates
/// Returns the candidate if Levenshtein distance <= 2, null otherwise
String? _findFuzzyMatch(String query, List<String> candidates) {
  for (final candidate in candidates) {
    if (_levenshteinDistance(query, candidate.toLowerCase()) <= 2) {
      return candidate;
    }
  }
  return null;
}

/// Calculates the Levenshtein distance between two strings
/// Used for fuzzy matching to catch typos and variations
int _levenshteinDistance(String s1, String s2) {
  if (s1 == s2) return 0;
  if (s1.isEmpty) return s2.length;
  if (s2.isEmpty) return s1.length;

  final len1 = s1.length;
  final len2 = s2.length;

  // Create distance matrix
  List<List<int>> matrix = List.generate(
    len1 + 1,
    (i) => List.generate(len2 + 1, (j) => 0),
  );

  // Initialize first row and column
  for (int i = 0; i <= len1; i++) {
    matrix[i][0] = i;
  }
  for (int j = 0; j <= len2; j++) {
    matrix[0][j] = j;
  }

  // Calculate distances
  for (int i = 1; i <= len1; i++) {
    for (int j = 1; j <= len2; j++) {
      final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
      matrix[i][j] = min(
        min(
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
        ),
        matrix[i - 1][j - 1] + cost, // substitution
      );
    }
  }

  return matrix[len1][len2];
}

/// Checks if a string contains any of the given keywords as whole words
/// Uses word boundaries to avoid false matches (e.g., "coffee shops" shouldn't match "photo")
bool _containsAny(String text, List<String> keywords) {
  // Split text into words and check for keyword matches
  final words = text.toLowerCase().split(RegExp(r'\s+'));
  return keywords.any((keyword) {
    final keywordLower = keyword.toLowerCase();
    // Check if any word starts with the keyword or keyword appears as a word
    return words.any(
      (word) => word == keywordLower || word.startsWith(keywordLower),
    );
  });
}

/// Capitalizes the first letter of each word in a string
String _capitalizeWords(String text) {
  if (text.isEmpty) return text;

  return text
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      })
      .join(' ');
}
