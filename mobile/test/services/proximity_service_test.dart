import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/user_profile.dart';
import 'package:mobile/services/proximity_service.dart';

void main() {
  group('ProximityMatch', () {
    test('formattedDistance should return meters for distances < 1km', () {
      final match = ProximityMatch(
        userProfile: _createMockProfile(),
        distanceKm: 0.5,
        commonInterests: ['coding', 'gaming'],
        matchScore: 0.8,
      );

      expect(match.formattedDistance, '500m');
    });

    test('formattedDistance should return kilometers for distances >= 1km', () {
      final match = ProximityMatch(
        userProfile: _createMockProfile(),
        distanceKm: 2.3,
        commonInterests: ['coding', 'gaming'],
        matchScore: 0.8,
      );

      expect(match.formattedDistance, '2.3km');
    });

    test('matchPercentage should convert score to percentage', () {
      final match = ProximityMatch(
        userProfile: _createMockProfile(),
        distanceKm: 1.0,
        commonInterests: ['coding', 'gaming'],
        matchScore: 0.75,
      );

      expect(match.matchPercentage, 75);
    });

    test('matchPercentage should round correctly', () {
      final match = ProximityMatch(
        userProfile: _createMockProfile(),
        distanceKm: 1.0,
        commonInterests: ['coding'],
        matchScore: 0.847,
      );

      expect(match.matchPercentage, 85);
    });
  });
}

// Helper function to create mock user profile
UserProfile _createMockProfile() {
  final now = DateTime(2025, 1, 1);
  return UserProfile(
    uid: 'user123',
    displayName: 'Test User',
    photoUrl: null,
    interests: const ['coding', 'gaming'],
    major: 'Computer Science',
    classYear: '2025',
    createdAt: now,
    updatedAt: now,
  );
}
