import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/constants/interest_categories.dart';
import 'package:mobile/utils/interest_utils.dart';

class UserProfile {
  final String uid;
  final String? displayName;
  final String? photoUrl;
  final String? bio;
  final String? classYear; // e.g., "2026"
  final String? major; // e.g., "CS"
  final List<String> interests;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserLocation? location;

  const UserProfile({
    required this.uid,
    this.displayName,
    this.photoUrl,
    this.bio,
    this.classYear,
    this.major,
    this.interests = const [],
    required this.createdAt,
    required this.updatedAt,
    this.location,
  });

  bool get isComplete =>
      interests.isNotEmpty; // tweak your own "completion" rule

  /// Returns a profile completeness score (0.0 to 1.0)
  /// Used as a multiplier in the matching algorithm
  double get profileCompleteness {
    double score = 0.0;

    // Basic info (40%)
    if (displayName != null && displayName!.isNotEmpty) score += 0.15;
    if (photoUrl != null && photoUrl!.isNotEmpty) score += 0.15;
    if (bio != null && bio!.isNotEmpty) score += 0.10;

    // Academic info (20%)
    if (major != null && major!.isNotEmpty) score += 0.10;
    if (classYear != null && classYear!.isNotEmpty) score += 0.10;

    // Interests (40% - most important for matching)
    if (interests.length >= 5) {
      score += 0.20;
    } else if (interests.isNotEmpty) {
      score += 0.20 * (interests.length / 5);
    }
    // Bonus for diverse interests across categories
    final categories = getInterestsByCategory().keys.length;
    if (categories >= 3) {
      score += 0.20;
    } else if (categories > 0) {
      score += 0.20 * (categories / 3);
    }

    return score.clamp(0.0, 1.0);
  }

  /// Groups interests by category for display and matching
  /// Returns a map of category to list of interests
  Map<InterestCategory, List<String>> getInterestsByCategory() {
    return groupInterestsByCategory(interests);
  }

  /// Gets interests for a specific category
  List<String> getInterestsForCategory(InterestCategory category) {
    return getInterestsByCategory()[category] ?? [];
  }

  /// Counts how many interests are in a specific category
  int countInterestsInCategory(InterestCategory category) {
    return getInterestsForCategory(category).length;
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'bio': bio,
    'classYear': classYear,
    'major': major,
    'interests': interests,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    if (location != null) 'location': location!.toMap(),
  };

  factory UserProfile.fromMap(Map<String, dynamic> m) {
    final uid = m['uid'];
    if (uid == null || uid is! String) {
      throw ArgumentError(
        'UserProfile.fromMap: uid field is required and must be a String, got: $uid',
      );
    }

    return UserProfile(
      uid: uid,
      displayName: m['displayName'] as String?,
      photoUrl: m['photoUrl'] as String?,
      bio: m['bio'] as String?,
      classYear: m['classYear'] as String?,
      major: m['major'] as String?,
      interests: (m['interests'] as List?)?.cast<String>() ?? const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        m['createdAt'] as int? ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        m['updatedAt'] as int? ?? 0,
      ),
      location: m['location'] != null
          ? UserLocation.fromMap(m['location'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Represents a user's location with privacy-preserving geohash
class UserLocation {
  final String geohash;
  final double? latitude;
  final double? longitude;
  final DateTime? lastUpdated;
  final bool isVisible;

  const UserLocation({
    required this.geohash,
    this.latitude,
    this.longitude,
    this.lastUpdated,
    this.isVisible = true,
  });

  Map<String, dynamic> toMap() => {
    'geohash': geohash,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (lastUpdated != null) 'lastUpdated': lastUpdated!.millisecondsSinceEpoch,
    'isVisible': isVisible,
  };

  factory UserLocation.fromMap(Map<String, dynamic> m) {
    final geohash = m['geohash'];
    if (geohash == null || geohash is! String) {
      throw ArgumentError(
        'UserLocation.fromMap: geohash field is required and must be a String, got: $geohash',
      );
    }

    DateTime? lastUpdated;
    if (m['lastUpdated'] != null) {
      final lastUpdatedValue = m['lastUpdated'];
      if (lastUpdatedValue is Timestamp) {
        lastUpdated = lastUpdatedValue.toDate();
      } else if (lastUpdatedValue is int) {
        lastUpdated = DateTime.fromMillisecondsSinceEpoch(lastUpdatedValue);
      }
    }

    return UserLocation(
      geohash: geohash,
      latitude: m['latitude'] as double?,
      longitude: m['longitude'] as double?,
      lastUpdated: lastUpdated,
      isVisible: m['isVisible'] as bool? ?? true,
    );
  }
}
