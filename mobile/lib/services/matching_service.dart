import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_profile.dart';
import '../models/match.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'profile_service.dart';

class MatchingService {
  MatchingService._();
  static final instance = MatchingService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService.instance;
  final NotificationService _notificationService = NotificationService.instance;

  static const String _matchesCollection = 'matches';
  static const String _userLocationsCollection = 'user_locations';
  static const String _activeUsersCollection = 'active_users';
  
  // Matching parameters
  static const double _proximityThreshold = 50.0; // 50 meters
  static const int _maxMatchesPerHour = 3;
  static const Duration _matchCooldown = Duration(hours: 1);
  
  StreamController<Match>? _matchController;
  Timer? _matchingTimer;
  bool _isMatchingActive = false;

  Stream<Match> get matchStream {
    _matchController ??= StreamController<Match>.broadcast();
    return _matchController!.stream;
  }

  bool get isMatchingActive => _isMatchingActive;

  /// Initialize matching service
  Future<void> initialize() async {
    // Start periodic matching check
    _startMatchingTimer();
  }

  /// Start matching timer
  void _startMatchingTimer() {
    _matchingTimer?.cancel();
    _matchingTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_isMatchingActive) {
        _performMatching();
      }
    });
  }

  /// Start matching for current user
  Future<void> startMatching(String userId) async {
    _isMatchingActive = true;
    
    // Update user's active status
    await _updateUserActiveStatus(userId, true);
    
    // Start location tracking if not already started
    if (!_locationService.isLocationEnabled) {
      await _locationService.initialize();
      await _locationService.startLocationTracking();
    }
    
    // Perform initial matching
    await _performMatching();
  }

  /// Stop matching for current user
  Future<void> stopMatching(String userId) async {
    _isMatchingActive = false;
    await _updateUserActiveStatus(userId, false);
  }

  /// Update user's active status
  Future<void> _updateUserActiveStatus(String userId, bool isActive) async {
    try {
      await _db.collection(_activeUsersCollection).doc(userId).set({
        'isActive': isActive,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user active status: $e');
    }
  }

  /// Update user's location
  Future<void> updateUserLocation(String userId, Position position) async {
    try {
      final coarseLocation = _locationService.getCoarseLocation(position);
      
      await _db.collection(_userLocationsCollection).doc(userId).set({
        'userId': userId,
        'latitude': coarseLocation['lat'],
        'longitude': coarseLocation['lng'],
        'timestamp': FieldValue.serverTimestamp(),
        'isOnCampus': _locationService.isOnCampus(position),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user location: $e');
    }
  }

  /// Perform matching algorithm
  Future<void> _performMatching() async {
    try {
      final currentUser = await _getCurrentUser();
      if (currentUser == null) return;

      final currentPosition = _locationService.lastKnownPosition;
      if (currentPosition == null) return;

      // Update current user's location
      await updateUserLocation(currentUser.uid, currentPosition);

      // Get nearby active users
      final nearbyUsers = await _getNearbyActiveUsers(currentPosition);
      
      // Find matches
      for (final nearbyUser in nearbyUsers) {
        if (await _shouldCreateMatch(currentUser, nearbyUser)) {
          await _createMatch(currentUser, nearbyUser);
        }
      }
    } catch (e) {
      print('Error in matching process: $e');
    }
  }

  /// Get current user from auth
  Future<UserProfile?> _getCurrentUser() async {
    // This would typically get the current user from your auth service
    // For now, we'll return null and handle this in the calling code
    return null;
  }

  /// Get nearby active users
  Future<List<UserProfile>> _getNearbyActiveUsers(Position position) async {
    try {
      // Get all active users
      final activeUsersSnapshot = await _db
          .collection(_activeUsersCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final nearbyUsers = <UserProfile>[];

      for (final doc in activeUsersSnapshot.docs) {
        final userId = doc.id;
        
        // Get user location
        final locationDoc = await _db
            .collection(_userLocationsCollection)
            .doc(userId)
            .get();

        if (locationDoc.exists) {
          final locationData = locationDoc.data()!;
          final userLat = locationData['latitude'] as double;
          final userLng = locationData['longitude'] as double;
          
          // Calculate distance
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            userLat,
            userLng,
          );

          if (distance <= _proximityThreshold) {
            // Get user profile
            final profile = await ProfileService.instance.getProfile(userId);
            if (profile != null) {
              nearbyUsers.add(profile);
            }
          }
        }
      }

      return nearbyUsers;
    } catch (e) {
      print('Error getting nearby users: $e');
      return [];
    }
  }

  /// Check if two users should be matched
  Future<bool> _shouldCreateMatch(UserProfile user1, UserProfile user2) async {
    // Don't match with self
    if (user1.uid == user2.uid) return false;

    // Check for shared interests
    final sharedInterests = _findSharedInterests(user1.interests, user2.interests);
    if (sharedInterests.isEmpty) return false;

    // Check if match already exists
    final existingMatch = await _getExistingMatch(user1.uid, user2.uid);
    if (existingMatch != null) return false;

    // Check cooldown period
    if (await _isInCooldown(user1.uid, user2.uid)) return false;

    // Check daily match limit
    if (await _hasReachedMatchLimit(user1.uid)) return false;

    return true;
  }

  /// Find shared interests between two users
  List<String> _findSharedInterests(List<String> interests1, List<String> interests2) {
    return interests1.where((interest) => interests2.contains(interest)).toList();
  }

  /// Get existing match between two users
  Future<Match?> _getExistingMatch(String userId1, String userId2) async {
    try {
      final query = await _db
          .collection(_matchesCollection)
          .where('participants', arrayContains: userId1)
          .get();

      for (final doc in query.docs) {
        final match = Match.fromMap(doc.data());
        if (match.participants.contains(userId2)) {
          return match;
        }
      }
      return null;
    } catch (e) {
      print('Error getting existing match: $e');
      return null;
    }
  }

  /// Check if users are in cooldown period
  Future<bool> _isInCooldown(String userId1, String userId2) async {
    try {
      final now = DateTime.now();
      final cooldownStart = now.subtract(_matchCooldown);

      final query = await _db
          .collection(_matchesCollection)
          .where('participants', arrayContains: userId1)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(cooldownStart))
          .get();

      for (final doc in query.docs) {
        final match = Match.fromMap(doc.data());
        if (match.participants.contains(userId2)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking cooldown: $e');
      return false;
    }
  }

  /// Check if user has reached daily match limit
  Future<bool> _hasReachedMatchLimit(String userId) async {
    try {
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);

      final query = await _db
          .collection(_matchesCollection)
          .where('participants', arrayContains: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(dayStart))
          .get();

      return query.docs.length >= _maxMatchesPerHour;
    } catch (e) {
      print('Error checking match limit: $e');
      return false;
    }
  }

  /// Create a new match
  Future<void> _createMatch(UserProfile user1, UserProfile user2) async {
    try {
      final sharedInterests = _findSharedInterests(user1.interests, user2.interests);
      final match = Match(
        id: _generateMatchId(),
        participants: [user1.uid, user2.uid],
        sharedInterests: sharedInterests,
        status: MatchStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _db.collection(_matchesCollection).doc(match.id).set(match.toMap());

      // Send notifications to both users
      await _sendMatchNotifications(match, user1, user2);

      // Emit match event
      _matchController?.add(match);
    } catch (e) {
      print('Error creating match: $e');
    }
  }

  /// Send match notifications
  Future<void> _sendMatchNotifications(Match match, UserProfile user1, UserProfile user2) async {
    try {
      final sharedInterest = match.sharedInterests.isNotEmpty 
          ? match.sharedInterests.first 
          : 'common interests';

      // Send notification to user1
      await _notificationService.sendProximityNotification(
        targetUserId: user1.uid,
        sharedInterest: sharedInterest,
        approximateLocation: 'nearby',
      );

      // Send notification to user2
      await _notificationService.sendProximityNotification(
        targetUserId: user2.uid,
        sharedInterest: sharedInterest,
        approximateLocation: 'nearby',
      );
    } catch (e) {
      print('Error sending match notifications: $e');
    }
  }

  /// Generate unique match ID
  String _generateMatchId() {
    return 'match_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  /// Get user's matches
  Future<List<Match>> getUserMatches(String userId) async {
    try {
      final query = await _db
          .collection(_matchesCollection)
          .where('participants', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => Match.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error getting user matches: $e');
      return [];
    }
  }

  /// Update match status
  Future<void> updateMatchStatus(String matchId, MatchStatus status) async {
    try {
      await _db.collection(_matchesCollection).doc(matchId).update({
        'status': status.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating match status: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _matchingTimer?.cancel();
    _matchController?.close();
  }
}
