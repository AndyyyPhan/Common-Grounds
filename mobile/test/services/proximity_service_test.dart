import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/user_profile.dart';
import 'package:mobile/services/proximity_service.dart';
import 'package:mobile/constants/interest_categories.dart';

void main() {
  group('ProximityMatch', () {
    test('formattedDistance should return meters for distances < 1km', () {
      final match = ProximityMatch(
        userProfile: _createMockProfile(),
        distanceKm: 0.5,
        commonInterests: ['Coding', 'Gaming'],
        matchScore: 0.8,
      );

      expect(match.formattedDistance, '500m');
    });

    test('formattedDistance should return kilometers for distances >= 1km', () {
      final match = ProximityMatch(
        userProfile: _createMockProfile(),
        distanceKm: 2.3,
        commonInterests: ['Coding', 'Gaming'],
        matchScore: 0.8,
      );

      expect(match.formattedDistance, '2.3km');
    });

    test('matchPercentage should convert score to percentage', () {
      final match = ProximityMatch(
        userProfile: _createMockProfile(),
        distanceKm: 1.0,
        commonInterests: ['Coding', 'Gaming'],
        matchScore: 0.75,
      );

      expect(match.matchPercentage, 75);
    });

    test('matchPercentage should round correctly', () {
      final match = ProximityMatch(
        userProfile: _createMockProfile(),
        distanceKm: 1.0,
        commonInterests: ['Coding'],
        matchScore: 0.847,
      );

      expect(match.matchPercentage, 85);
    });
  });

  group('UserProfile - Categorized Interests', () {
    test('getInterestsByCategory should group interests correctly', () {
      final profile = _createProfileWithCategories();
      final grouped = profile.getInterestsByCategory();

      expect(grouped[InterestCategory.academic], contains('Coding'));
      expect(grouped[InterestCategory.academic], contains('Study Buddy'));
      expect(grouped[InterestCategory.sports], contains('Basketball'));
      expect(grouped[InterestCategory.social], contains('Coffee'));
    });

    test('countInterestsInCategory should count correctly', () {
      final profile = _createProfileWithCategories();

      expect(profile.countInterestsInCategory(InterestCategory.academic), 2);
      expect(profile.countInterestsInCategory(InterestCategory.sports), 1);
      expect(profile.countInterestsInCategory(InterestCategory.social), 1);
      expect(profile.countInterestsInCategory(InterestCategory.entertainment), 1);
    });

    test('profileCompleteness should calculate correctly for complete profile',
        () {
      final profile = _createCompleteProfile();
      final completeness = profile.profileCompleteness;

      // Complete profile should have high completeness score
      expect(completeness, greaterThan(0.8));
      expect(completeness, lessThanOrEqualTo(1.0));
    });

    test('profileCompleteness should be lower for incomplete profile', () {
      final profile = _createIncompleteProfile();
      final completeness = profile.profileCompleteness;

      // Incomplete profile should have lower completeness score
      expect(completeness, lessThan(0.6));
      expect(completeness, greaterThanOrEqualTo(0.0));
    });

    test('profileCompleteness should reward diverse interests', () {
      final diverseProfile = _createProfileWithDiverseInterests();
      final narrowProfile = _createProfileWithNarrowInterests();

      expect(diverseProfile.profileCompleteness,
          greaterThan(narrowProfile.profileCompleteness));
    });
  });

  group('Category-Weighted Matching Algorithm', () {
    test('should detect interest overlap across categories', () {
      final user1 = _createProfileWithInterests(
        ['Coding', 'Hackathons', 'Study Buddy'], // Academic
      );
      final user2Academic = _createProfileWithInterests(
        ['Coding', 'Research', 'Engineering'], // Academic overlap
      );
      final user2Entertainment = _createProfileWithInterests(
        ['Gaming', 'Movies', 'Anime'], // No academic overlap
      );

      // User2Academic should have match due to shared academic interests
      // User2Entertainment should have no match due to no overlap
      expect(user1.interests.toSet().intersection(user2Academic.interests.toSet()).isNotEmpty,
          isTrue);
      expect(
          user1.interests.toSet().intersection(user2Entertainment.interests.toSet()).isEmpty,
          isTrue);
    });

    test('should consider category distribution in matching', () {
      final user = _createProfileWithDiverseInterests();
      final categories = user.getInterestsByCategory();

      // Should have interests in multiple categories
      expect(categories.keys.length, greaterThanOrEqualTo(3));
    });
  });

  group('Interest Category Weights', () {
    test('category weights should sum to 1.0', () {
      final totalWeight = kCategoryWeights.values.reduce((a, b) => a + b);
      expect(totalWeight, closeTo(1.0, 0.01));
    });

    test('all category weights should be approximately equal', () {
      final weights = kCategoryWeights.values.toList();
      final avgWeight = 1.0 / kCategoryWeights.length;

      for (final weight in weights) {
        // Each weight should be close to ~16.7% (1/6)
        expect(weight, closeTo(avgWeight, 0.01));
      }
    });

    test('all weights should be positive', () {
      for (final weight in kCategoryWeights.values) {
        expect(weight, greaterThan(0));
      }
    });
  });
}

// Helper functions to create mock user profiles

UserProfile _createMockProfile() {
  final now = DateTime(2025, 1, 1);
  return UserProfile(
    uid: 'user123',
    displayName: 'Test User',
    photoUrl: null,
    interests: const ['Coding', 'Gaming'],
    major: 'Computer Science',
    classYear: '2025',
    createdAt: now,
    updatedAt: now,
  );
}

UserProfile _createProfileWithCategories() {
  final now = DateTime(2025, 1, 1);
  return UserProfile(
    uid: 'user_categories',
    displayName: 'Category Test User',
    photoUrl: 'https://example.com/photo.jpg',
    bio: 'Test bio',
    interests: const ['Coding', 'Study Buddy', 'Basketball', 'Coffee', 'Gaming'],
    major: 'Computer Science',
    classYear: '2025',
    createdAt: now,
    updatedAt: now,
  );
}

UserProfile _createCompleteProfile() {
  final now = DateTime(2025, 1, 1);
  return UserProfile(
    uid: 'complete_user',
    displayName: 'Complete User',
    photoUrl: 'https://example.com/photo.jpg',
    bio: 'A comprehensive bio about me',
    interests: const [
      'Coding',
      'Study Buddy',
      'Basketball',
      'Coffee',
      'Music',
      'Travel',
      'Gaming',
      'Photography',
    ],
    major: 'Computer Science',
    classYear: '2025',
    createdAt: now,
    updatedAt: now,
  );
}

UserProfile _createIncompleteProfile() {
  final now = DateTime(2025, 1, 1);
  return UserProfile(
    uid: 'incomplete_user',
    displayName: null,
    photoUrl: null,
    bio: null,
    interests: const ['Coding', 'Gaming'],
    major: null,
    classYear: null,
    createdAt: now,
    updatedAt: now,
  );
}

UserProfile _createProfileWithDiverseInterests() {
  final now = DateTime(2025, 1, 1);
  return UserProfile(
    uid: 'diverse_user',
    displayName: 'Diverse User',
    photoUrl: 'https://example.com/photo.jpg',
    interests: const [
      'Coding', // Academic
      'Basketball', // Sports
      'Coffee', // Social
      'Music', // Creative
      'Gaming', // Entertainment
      'Travel', // Lifestyle
    ],
    major: 'Computer Science',
    classYear: '2025',
    createdAt: now,
    updatedAt: now,
  );
}

UserProfile _createProfileWithNarrowInterests() {
  final now = DateTime(2025, 1, 1);
  return UserProfile(
    uid: 'narrow_user',
    displayName: 'Narrow User',
    photoUrl: 'https://example.com/photo.jpg',
    interests: const [
      'Basketball',
      'Volleyball',
      'Gym',
      'Running',
      'Pickleball',
    ], // All sports
    major: 'Kinesiology',
    classYear: '2025',
    createdAt: now,
    updatedAt: now,
  );
}

UserProfile _createProfileWithInterests(List<String> interests) {
  final now = DateTime(2025, 1, 1);
  return UserProfile(
    uid: 'test_user_${interests.hashCode}',
    displayName: 'Test User',
    photoUrl: null,
    interests: interests,
    major: 'Test Major',
    classYear: '2025',
    createdAt: now,
    updatedAt: now,
  );
}
