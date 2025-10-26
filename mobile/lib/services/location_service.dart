import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

class LocationService {
  LocationService._();
  static final instance = LocationService._();

  final _db = FirebaseFirestore.instance;
  Timer? _locationTimer;
  String? _currentUserId;

  // Update interval in minutes (coarse tracking for privacy)
  static const _updateIntervalMinutes = 5;

  // Geohash precision (lower = coarser area, better privacy)
  // Precision 6 = ~1.2km x 0.6km area
  static const _geohashPrecision = 6;

  /// Initialize location tracking for a user
  Future<bool> initForUser(String uid) async {
    _currentUserId = uid;

    // Check and request permissions
    final hasPermission = await _requestLocationPermission();
    if (!hasPermission) {
      if (kDebugMode) {
        debugPrint('Location permission denied');
      }
      return false;
    }

    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (kDebugMode) {
        debugPrint('Location services are disabled');
      }
      return false;
    }

    // Update location immediately
    await _updateUserLocation();

    // Start periodic updates
    startTracking();

    return true;
  }

  /// Request location permission from user
  Future<bool> _requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;

    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }

    if (status.isPermanentlyDenied) {
      if (kDebugMode) {
        debugPrint('Location permission permanently denied. Opening settings.');
      }
      await openAppSettings();
      return false;
    }

    return status.isGranted || status.isLimited;
  }

  /// Get current location and update Firestore
  Future<void> _updateUserLocation() async {
    if (_currentUserId == null) return;

    try {
      // Get current position with low accuracy for privacy
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // ~1-5km accuracy for privacy
          distanceFilter: 100, // Only update if moved 100m
        ),
      );

      // Convert to GeoFirePoint
      final geoPoint = GeoFirePoint(GeoPoint(
        position.latitude,
        position.longitude,
      ));

      // Get geohash with specified precision (coarse for privacy)
      final geohash = geoPoint.geohash.substring(0, _geohashPrecision);

      // Update user's location in Firestore
      await _db.collection('users').doc(_currentUserId).set({
        'location': {
          'geohash': geohash,
          'geopoint': geoPoint.geopoint,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'lastUpdated': FieldValue.serverTimestamp(),
          'isVisible': true, // User can toggle this in settings
        },
      }, SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint('Location updated: ${position.latitude}, ${position.longitude}');
        debugPrint('Geohash: $geohash');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating location: $e');
      }
    }
  }

  /// Start periodic location tracking
  void startTracking() {
    // Cancel existing timer if any
    _locationTimer?.cancel();

    // Set up periodic updates
    _locationTimer = Timer.periodic(
      const Duration(minutes: _updateIntervalMinutes),
      (_) => _updateUserLocation(),
    );

    if (kDebugMode) {
      debugPrint('Location tracking started (updates every $_updateIntervalMinutes minutes)');
    }
  }

  /// Stop location tracking
  void stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    if (kDebugMode) {
      debugPrint('Location tracking stopped');
    }
  }

  /// Set user location visibility (opt-in/opt-out)
  Future<void> setLocationVisibility(String uid, bool isVisible) async {
    await _db.collection('users').doc(uid).set({
      'location': {
        'isVisible': isVisible,
        'lastUpdated': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));

    if (!isVisible) {
      stopTracking();
    } else if (_currentUserId == uid) {
      await _updateUserLocation();
      startTracking();
    }
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted || status.isLimited;
  }

  /// Manually refresh location now
  Future<void> refreshLocation() async {
    await _updateUserLocation();
  }

  /// Get current coordinates
  Future<Position?> getCurrentCoordinates() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 100,
        ),
      );
      return position;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting current coordinates: $e');
      }
      return null;
    }
  }

  /// Clean up resources
  void dispose() {
    stopTracking();
    _currentUserId = null;
  }
}
