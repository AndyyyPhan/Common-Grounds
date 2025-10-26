import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/user_profile.dart';

/// Service for finding nearby users with similar interests
class ProximityService {
  ProximityService._();
  static final instance = ProximityService._();

  final _db = FirebaseFirestore.instance;

  /// Find nearby users with similar interests
  /// 
  /// Parameters:
  /// - currentUserProfile: The current user's profile
  /// - maxDistanceKm: Maximum distance in kilometers (default: 5km)
  /// - minCommonInterests: Minimum number of common interests required (default: 1)
  /// - limit: Maximum number of results to return (default: 10)
  Future<List<ProximityMatch>> findNearbyMatches(
    UserProfile currentUserProfile, {
    double maxDistanceKm = 5.0,
    int minCommonInterests = 1,
    int limit = 10,
  }) async {
    try {
      // Check if user has location and interests
      if (currentUserProfile.location?.isVisible != true) {
        debugPrint('User location not visible');
        return [];
      }

      if (currentUserProfile.interests.isEmpty) {
        debugPrint('User has no interests');
        return [];
      }

      final currentGeohash = currentUserProfile.location!.geohash;
      final currentLat = currentUserProfile.location!.latitude;
      final currentLng = currentUserProfile.location!.longitude;

      if (currentLat == null || currentLng == null) {
        debugPrint('User location coordinates not available');
        return [];
      }

      // Get nearby geohashes (expanded search area)
      final nearbyGeohashes = _getNearbyGeohashes(currentGeohash, maxDistanceKm);

      debugPrint('🔍 PROXIMITY SEARCH STARTED');
      debugPrint('📍 Current user: ${currentUserProfile.displayName}');
      debugPrint('📍 Current location: $currentLat, $currentLng');
      debugPrint('📍 Current geohash: $currentGeohash');
      debugPrint('📍 User interests: ${currentUserProfile.interests}');
      debugPrint('🔍 Searching in ${nearbyGeohashes.length} geohash areas');
      debugPrint('🔍 Nearby geohashes: $nearbyGeohashes');

      // Query users in nearby geohashes
      final List<ProximityMatch> matches = [];
      
      // First try geohash-based search
      for (final geohash in nearbyGeohashes.take(5)) { // Limit to first 5 for performance
        final query = await _db
            .collection('users')
            .where('location.geohash', isEqualTo: geohash)
            .where('location.isVisible', isEqualTo: true)
            .limit(limit * 2) // Get more to filter by interests
            .get();

        debugPrint('🔍 Querying geohash $geohash: found ${query.docs.length} users');

        for (final doc in query.docs) {
          // Skip current user
          if (doc.id == currentUserProfile.uid) continue;

          try {
            final userProfile = UserProfile.fromMap(doc.data());
            
            // Check if user has location coordinates
            if (userProfile.location?.latitude == null || 
                userProfile.location?.longitude == null) {
              continue;
            }

            // Calculate distance
            final distance = _calculateDistance(
              currentLat,
              currentLng,
              userProfile.location!.latitude!,
              userProfile.location!.longitude!,
            );

            // Filter by distance
            if (distance > maxDistanceKm) continue;

            // Calculate common interests
            final commonInterests = _getCommonInterests(
              currentUserProfile.interests,
              userProfile.interests,
            );

            // Filter by minimum common interests
            if (commonInterests.length < minCommonInterests) continue;

            // Calculate match score (higher is better)
            final matchScore = _calculateMatchScore(
              commonInterests.length,
              currentUserProfile.interests.length,
              userProfile.interests.length,
              distance,
            );

            matches.add(ProximityMatch(
              userProfile: userProfile,
              distanceKm: distance,
              commonInterests: commonInterests,
              matchScore: matchScore,
            ));
          } catch (e) {
            debugPrint('Error parsing user profile ${doc.id}: $e');
            continue;
          }
        }
      }

      // If no matches found with geohash, try a broader search
      if (matches.isEmpty) {
        debugPrint('🔍 No matches found with geohash search, trying broader search...');
        final query = await _db
            .collection('users')
            .where('location.isVisible', isEqualTo: true)
            .limit(50) // Get more users for broader search
            .get();

        debugPrint('🔍 Broad search found ${query.docs.length} users');

        for (final doc in query.docs) {
          // Skip current user
          if (doc.id == currentUserProfile.uid) continue;

          try {
            final userProfile = UserProfile.fromMap(doc.data());
            
            // Check if user has location coordinates
            if (userProfile.location?.latitude == null || 
                userProfile.location?.longitude == null) {
              continue;
            }

            // Calculate distance
            final distance = _calculateDistance(
              currentLat,
              currentLng,
              userProfile.location!.latitude!,
              userProfile.location!.longitude!,
            );

            // Filter by distance (more lenient for broad search)
            if (distance > maxDistanceKm * 2) continue;

            // Calculate common interests
            final commonInterests = _getCommonInterests(
              currentUserProfile.interests,
              userProfile.interests,
            );

            // Filter by minimum common interests
            if (commonInterests.length < minCommonInterests) continue;

            // Calculate match score (higher is better)
            final matchScore = _calculateMatchScore(
              commonInterests.length,
              currentUserProfile.interests.length,
              userProfile.interests.length,
              distance,
            );

            matches.add(ProximityMatch(
              userProfile: userProfile,
              distanceKm: distance,
              commonInterests: commonInterests,
              matchScore: matchScore,
            ));
          } catch (e) {
            debugPrint('Error parsing user profile ${doc.id}: $e');
            continue;
          }
        }
      }

      // Sort by match score (highest first) and limit results
      matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      
      final limitedMatches = matches.take(limit).toList();
      
      debugPrint('✅ Found ${limitedMatches.length} matches');
      for (final match in limitedMatches) {
        debugPrint('🎯 Match: ${match.userProfile.displayName} - '
            '${match.distanceKm.toStringAsFixed(1)}km - '
            '${match.commonInterests.length} common interests - '
            'Score: ${match.matchScore.toStringAsFixed(2)}');
        debugPrint('   Common interests: ${match.commonInterests}');
      }

      return limitedMatches;
    } catch (e) {
      debugPrint('Error finding nearby matches: $e');
      return [];
    }
  }

  /// Get nearby geohashes for proximity search
  List<String> _getNearbyGeohashes(String centerGeohash, double maxDistanceKm) {
    // Simplified approach for testing - search broader area
    final geohashes = <String>{centerGeohash};
    
    // For testing, let's search a broader area by using shorter geohash
    final baseGeohash = centerGeohash.substring(0, 3); // Use first 3 chars for very broad search
    
    // Add variations to expand search area significantly
    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 10; j++) {
        geohashes.add('${baseGeohash}${i.toString()}${j.toString()}');
      }
    }
    
    debugPrint('🔍 Generated ${geohashes.length} geohashes for search');
    return geohashes.toList();
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * 
        sin(dLng / 2) * sin(dLng / 2);
    
    final double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  /// Get common interests between two users
  List<String> _getCommonInterests(List<String> interests1, List<String> interests2) {
    return interests1.where((interest) => interests2.contains(interest)).toList();
  }

  /// Calculate match score based on interests and distance
  double _calculateMatchScore(
    int commonInterestsCount,
    int currentUserInterestsCount,
    int otherUserInterestsCount,
    double distanceKm,
  ) {
    // Interest similarity score (0-1)
    final interestSimilarity = commonInterestsCount / 
        (currentUserInterestsCount + otherUserInterestsCount - commonInterestsCount);
    
    // Distance score (closer is better, 0-1)
    final distanceScore = (10 - distanceKm.clamp(0, 10)) / 10;
    
    // Weighted combination: 70% interests, 30% distance
    return (interestSimilarity * 0.7) + (distanceScore * 0.3);
  }

  /// Stream of nearby matches (real-time updates)
  Stream<List<ProximityMatch>> watchNearbyMatches(
    UserProfile currentUserProfile, {
    double maxDistanceKm = 5.0,
    int minCommonInterests = 1,
    int limit = 10,
  }) {
    return Stream.periodic(const Duration(minutes: 2), (_) {
      return findNearbyMatches(
        currentUserProfile,
        maxDistanceKm: maxDistanceKm,
        minCommonInterests: minCommonInterests,
        limit: limit,
      );
    }).asyncMap((future) => future);
  }
}

/// Represents a proximity match with another user
class ProximityMatch {
  final UserProfile userProfile;
  final double distanceKm;
  final List<String> commonInterests;
  final double matchScore;

  const ProximityMatch({
    required this.userProfile,
    required this.distanceKm,
    required this.commonInterests,
    required this.matchScore,
  });

  /// Get formatted distance string
  String get formattedDistance {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    } else {
      return '${distanceKm.toStringAsFixed(1)}km';
    }
  }

  /// Get match percentage
  int get matchPercentage {
    return (matchScore * 100).round();
  }
}
