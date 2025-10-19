import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/privacy_settings.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'matching_service.dart';

class PrivacyService {
  PrivacyService._();
  static final instance = PrivacyService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final MatchingService _matchingService = MatchingService.instance;

  static const String _privacyCollection = 'privacy_settings';

  /// Get user's privacy settings
  Future<PrivacySettings?> getPrivacySettings(String userId) async {
    try {
      final doc = await _db.collection(_privacyCollection).doc(userId).get();
      if (!doc.exists) {
        // Create default privacy settings
        return await _createDefaultPrivacySettings(userId);
      }
      return PrivacySettings.fromMap(doc.data()!);
    } catch (e) {
      print('Error getting privacy settings: $e');
      return null;
    }
  }

  /// Stream user's privacy settings
  Stream<PrivacySettings?> watchPrivacySettings(String userId) {
    return _db.collection(_privacyCollection).doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return PrivacySettings.fromMap(snapshot.data()!);
    });
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings(PrivacySettings settings) async {
    try {
      final updatedSettings = settings.copyWith(updatedAt: DateTime.now());
      await _db.collection(_privacyCollection).doc(settings.userId).set(
        updatedSettings.toMap(),
        SetOptions(merge: true),
      );

      // Apply settings to services
      await _applyPrivacySettings(updatedSettings);
    } catch (e) {
      print('Error updating privacy settings: $e');
      rethrow;
    }
  }

  /// Create default privacy settings for new user
  Future<PrivacySettings> _createDefaultPrivacySettings(String userId) async {
    final now = DateTime.now();
    final defaultSettings = PrivacySettings(
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );

    await _db.collection(_privacyCollection).doc(userId).set(defaultSettings.toMap());
    return defaultSettings;
  }

  /// Apply privacy settings to all services
  Future<void> _applyPrivacySettings(PrivacySettings settings) async {
    try {
      // Apply location settings
      await _locationService.setLocationEnabled(settings.locationSharingEnabled);

      // Apply notification settings
      await _notificationService.setNotificationsEnabled(settings.notificationsEnabled);

      // Apply matching settings
      if (settings.allowMatching) {
        await _matchingService.startMatching(settings.userId);
      } else {
        await _matchingService.stopMatching(settings.userId);
      }
    } catch (e) {
      print('Error applying privacy settings: $e');
    }
  }

  /// Update specific privacy setting
  Future<void> updateLocationSharing(String userId, bool enabled) async {
    try {
      await _db.collection(_privacyCollection).doc(userId).update({
        'locationSharingEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _locationService.setLocationEnabled(enabled);
    } catch (e) {
      print('Error updating location sharing: $e');
    }
  }

  /// Update notification settings
  Future<void> updateNotifications(String userId, bool enabled) async {
    try {
      await _db.collection(_privacyCollection).doc(userId).update({
        'notificationsEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _notificationService.setNotificationsEnabled(enabled);
    } catch (e) {
      print('Error updating notifications: $e');
    }
  }

  /// Update profile visibility
  Future<void> updateProfileVisibility(String userId, bool visible) async {
    try {
      await _db.collection(_privacyCollection).doc(userId).update({
        'profileVisible': visible,
        'allowMatching': visible, // If profile is not visible, disable matching
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Apply matching settings
      if (visible) {
        await _matchingService.startMatching(userId);
      } else {
        await _matchingService.stopMatching(userId);
      }
    } catch (e) {
      print('Error updating profile visibility: $e');
    }
  }

  /// Update location precision
  Future<void> updateLocationPrecision(String userId, double precision) async {
    try {
      // Clamp precision between 0.0 and 1.0
      final clampedPrecision = precision.clamp(0.0, 1.0);

      await _db.collection(_privacyCollection).doc(userId).update({
        'locationPrecision': clampedPrecision,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating location precision: $e');
    }
  }

  /// Update daily match limit
  Future<void> updateDailyMatchLimit(String userId, int limit) async {
    try {
      // Clamp limit between 1 and 20
      final clampedLimit = limit.clamp(1, 20);

      await _db.collection(_privacyCollection).doc(userId).update({
        'maxDailyMatches': clampedLimit,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating daily match limit: $e');
    }
  }

  /// Update data sharing preferences
  Future<void> updateDataSharing(String userId, {
    bool? shareInterests,
    bool? shareClassYear,
    bool? shareMajor,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (shareInterests != null) updates['shareInterests'] = shareInterests;
      if (shareClassYear != null) updates['shareClassYear'] = shareClassYear;
      if (shareMajor != null) updates['shareMajor'] = shareMajor;

      await _db.collection(_privacyCollection).doc(userId).update(updates);
    } catch (e) {
      print('Error updating data sharing: $e');
    }
  }

  /// Delete all user data (GDPR compliance)
  Future<void> deleteAllUserData(String userId) async {
    try {
      // Delete privacy settings
      await _db.collection(_privacyCollection).doc(userId).delete();

      // Stop all services
      await _locationService.stopLocationTracking();
      await _matchingService.stopMatching(userId);

      // Note: Other data deletion (profile, messages, etc.) should be handled
      // by their respective services or a dedicated data deletion service
    } catch (e) {
      print('Error deleting user data: $e');
      rethrow;
    }
  }

  /// Check if user has given consent for data processing
  Future<bool> hasDataConsent(String userId) async {
    try {
      final settings = await getPrivacySettings(userId);
      return settings != null;
    } catch (e) {
      print('Error checking data consent: $e');
      return false;
    }
  }

  /// Get privacy summary for user
  Future<Map<String, dynamic>> getPrivacySummary(String userId) async {
    try {
      final settings = await getPrivacySettings(userId);
      if (settings == null) return {};

      return {
        'locationSharing': settings.locationSharingEnabled,
        'notifications': settings.notificationsEnabled,
        'profileVisible': settings.profileVisible,
        'allowMatching': settings.allowMatching,
        'locationPrecision': settings.locationPrecision,
        'maxDailyMatches': settings.maxDailyMatches,
        'shareInterests': settings.shareInterests,
        'shareClassYear': settings.shareClassYear,
        'shareMajor': settings.shareMajor,
        'lastUpdated': settings.updatedAt.toIso8601String(),
      };
    } catch (e) {
      print('Error getting privacy summary: $e');
      return {};
    }
  }
}
