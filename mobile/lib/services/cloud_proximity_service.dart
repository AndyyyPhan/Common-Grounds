import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

/// Service for calling Cloud Functions for similarity calculations
class CloudProximityService {
  CloudProximityService._();
  static final instance = CloudProximityService._();

  final _functions = FirebaseFunctions.instance;

  /// Find nearby users with similar interests using Cloud Function
  Future<List<ProximityMatch>> findNearbyMatches(
    UserProfile currentUserProfile, {
    double maxDistanceKm = 0.1,
    int minCommonInterests = 1,
    int limit = 10,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('☁️ ===== CLOUD PROXIMITY SEARCH STARTED =====');
        debugPrint('☁️ 📍 Current user: ${currentUserProfile.displayName}');
        debugPrint('☁️ 📍 Max distance: ${maxDistanceKm}km');
        debugPrint('☁️ 📍 Min common interests: $minCommonInterests');
        debugPrint('☁️ 📍 Limit: $limit');
      }

      // Call the Cloud Function
      final callable = _functions.httpsCallable('findNearbyMatches');
      final result = await callable.call({
        'currentUserUid': currentUserProfile.uid,
        'maxDistanceKm': maxDistanceKm,
        'minCommonInterests': minCommonInterests,
        'limit': limit,
      });

      final data = result.data as Map<String, dynamic>;
      final matchesData = data['matches'] as List<dynamic>;
      final totalProcessed = data['totalProcessed'] as int;
      final executionTimeMs = data['executionTimeMs'] as int;

      if (kDebugMode) {
        debugPrint('☁️ ✅ Cloud Function completed successfully');
        debugPrint('☁️ 📊 Found ${matchesData.length} matches');
        debugPrint('☁️ 📊 Total processed: $totalProcessed users');
        debugPrint('☁️ ⏱️ Execution time: ${executionTimeMs}ms');
      }

      // Convert the response to ProximityMatch objects
      final matches = matchesData.map((matchData) {
        final userProfileData = matchData['userProfile'] as Map<String, dynamic>;
        final userProfile = UserProfile.fromMap(userProfileData);
        
        return ProximityMatch(
          userProfile: userProfile,
          distanceKm: (matchData['distanceKm'] as num).toDouble(),
          commonInterests: List<String>.from(matchData['commonInterests']),
          matchScore: (matchData['matchScore'] as num).toDouble(),
        );
      }).toList();

      if (kDebugMode) {
        debugPrint('☁️ ===== CLOUD PROXIMITY SEARCH COMPLETED =====');
      }

      return matches;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('☁️ ❌ Error in Cloud Proximity Service: $e');
        debugPrint('☁️ ❌ Error type: ${e.runtimeType}');
      }
      
      // Re-throw with more context
      throw Exception('Failed to find nearby matches: $e');
    }
  }

  /// Get user profile by UID using Cloud Function
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      if (kDebugMode) {
        debugPrint('☁️ 📋 Getting user profile for UID: $uid');
      }

      final callable = _functions.httpsCallable('getUserProfile');
      final result = await callable.call({'uid': uid});

      final data = result.data as Map<String, dynamic>;
      final userProfile = UserProfile.fromMap(data);

      if (kDebugMode) {
        debugPrint('☁️ ✅ User profile retrieved successfully');
      }

      return userProfile;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('☁️ ❌ Error getting user profile: $e');
      }
      return null;
    }
  }

  /// Stream of nearby matches using Cloud Function (with periodic updates)
  Stream<List<ProximityMatch>> watchNearbyMatches(
    UserProfile currentUserProfile, {
    double maxDistanceKm = 0.1,
    int minCommonInterests = 1,
    int limit = 10,
  }) {
    // Create a controller for immediate start
    final controller = StreamController<List<ProximityMatch>>();

    // Start with immediate search
    findNearbyMatches(
          currentUserProfile,
          maxDistanceKm: maxDistanceKm,
          minCommonInterests: minCommonInterests,
          limit: limit,
        )
        .then((matches) {
          controller.add(matches);
        })
        .catchError((error) {
          controller.addError(error);
        });

    // Then update every 2 minutes
    Timer.periodic(const Duration(minutes: 2), (timer) {
      findNearbyMatches(
            currentUserProfile,
            maxDistanceKm: maxDistanceKm,
            minCommonInterests: minCommonInterests,
            limit: limit,
          )
          .then((matches) {
            controller.add(matches);
          })
          .catchError((error) {
            controller.addError(error);
          });
    });

    return controller.stream;
  }
}

/// ProximityMatch model for Cloud Function results
class ProximityMatch {
  final UserProfile userProfile;
  final double distanceKm;
  final List<String> commonInterests;
  final double matchScore;

  ProximityMatch({
    required this.userProfile,
    required this.distanceKm,
    required this.commonInterests,
    required this.matchScore,
  });

  @override
  String toString() {
    return 'ProximityMatch(user: ${userProfile.displayName}, distance: ${distanceKm.toStringAsFixed(2)}km, common: ${commonInterests.length}, score: ${matchScore.toStringAsFixed(3)})';
  }
}
