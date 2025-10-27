import 'package:cloud_firestore/cloud_firestore.dart';

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
      interests.isNotEmpty; // tweak your own “completion” rule

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
      throw ArgumentError('UserProfile.fromMap: uid field is required and must be a String, got: $uid');
    }
    
    return UserProfile(
      uid: uid,
      displayName: m['displayName'] as String?,
      photoUrl: m['photoUrl'] as String?,
      bio: m['bio'] as String?,
      classYear: m['classYear'] as String?,
      major: m['major'] as String?,
      interests: (m['interests'] as List?)?.cast<String>() ?? const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int? ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updatedAt'] as int? ?? 0),
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
    if (lastUpdated != null)
      'lastUpdated': lastUpdated!.millisecondsSinceEpoch,
    'isVisible': isVisible,
  };

  factory UserLocation.fromMap(Map<String, dynamic> m) {
    final geohash = m['geohash'];
    if (geohash == null || geohash is! String) {
      throw ArgumentError('UserLocation.fromMap: geohash field is required and must be a String, got: $geohash');
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
