import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacySettings {
  final String userId;
  final bool locationSharingEnabled;
  final bool notificationsEnabled;
  final bool profileVisible;
  final bool allowMatching;
  final double locationPrecision; // 0.0 = very precise, 1.0 = very coarse
  final int maxDailyMatches;
  final bool shareInterests;
  final bool shareClassYear;
  final bool shareMajor;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PrivacySettings({
    required this.userId,
    this.locationSharingEnabled = true,
    this.notificationsEnabled = true,
    this.profileVisible = true,
    this.allowMatching = true,
    this.locationPrecision = 0.5, // Default to medium precision
    this.maxDailyMatches = 5,
    this.shareInterests = true,
    this.shareClassYear = true,
    this.shareMajor = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if user can be matched with others
  bool get canBeMatched => allowMatching && profileVisible;

  /// Check if location sharing is enabled with sufficient precision
  bool get canShareLocation => locationSharingEnabled && locationPrecision < 1.0;

  /// Get effective location precision (higher = more privacy)
  double get effectiveLocationPrecision {
    if (!locationSharingEnabled) return 1.0;
    return locationPrecision;
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'locationSharingEnabled': locationSharingEnabled,
    'notificationsEnabled': notificationsEnabled,
    'profileVisible': profileVisible,
    'allowMatching': allowMatching,
    'locationPrecision': locationPrecision,
    'maxDailyMatches': maxDailyMatches,
    'shareInterests': shareInterests,
    'shareClassYear': shareClassYear,
    'shareMajor': shareMajor,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory PrivacySettings.fromMap(Map<String, dynamic> map) => PrivacySettings(
    userId: map['userId'] as String,
    locationSharingEnabled: map['locationSharingEnabled'] as bool? ?? true,
    notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
    profileVisible: map['profileVisible'] as bool? ?? true,
    allowMatching: map['allowMatching'] as bool? ?? true,
    locationPrecision: (map['locationPrecision'] as num?)?.toDouble() ?? 0.5,
    maxDailyMatches: map['maxDailyMatches'] as int? ?? 5,
    shareInterests: map['shareInterests'] as bool? ?? true,
    shareClassYear: map['shareClassYear'] as bool? ?? true,
    shareMajor: map['shareMajor'] as bool? ?? true,
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
  );

  PrivacySettings copyWith({
    String? userId,
    bool? locationSharingEnabled,
    bool? notificationsEnabled,
    bool? profileVisible,
    bool? allowMatching,
    double? locationPrecision,
    int? maxDailyMatches,
    bool? shareInterests,
    bool? shareClassYear,
    bool? shareMajor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PrivacySettings(
    userId: userId ?? this.userId,
    locationSharingEnabled: locationSharingEnabled ?? this.locationSharingEnabled,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    profileVisible: profileVisible ?? this.profileVisible,
    allowMatching: allowMatching ?? this.allowMatching,
    locationPrecision: locationPrecision ?? this.locationPrecision,
    maxDailyMatches: maxDailyMatches ?? this.maxDailyMatches,
    shareInterests: shareInterests ?? this.shareInterests,
    shareClassYear: shareClassYear ?? this.shareClassYear,
    shareMajor: shareMajor ?? this.shareMajor,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
