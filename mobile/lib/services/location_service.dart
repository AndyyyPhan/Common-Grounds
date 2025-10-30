import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:mobile/services/proximity_service.dart';

class LocationService {
  LocationService._();
  static final instance = LocationService._();

  final _db = FirebaseFirestore.instance;
  Timer? _locationTimer;
  String? _currentUserId;
  
  // When true, do not auto-update location from GPS/debug.
  // This is set when the user manually selects a location on the map.
  bool _manualOverrideActive = false;

  // Update interval in minutes (coarse tracking for privacy)
  static const _updateIntervalMinutes = 5;

  // Geohash precision (lower = coarser area, better privacy)
  // Precision 6 = ~1.2km x 0.6km area
  static const _geohashPrecision = 6;

  // Debug location override (disabled by default). Enable only if explicitly set.
  static bool _useDebugOverride = false;
  static const double _debugLatitude = 38.03199384346889;
  static const double _debugLongitude = -78.51068317176542;

  /// Enable or disable using the hardcoded debug coordinates.
  /// This remains OFF by default to prevent unexpected overwrites.
  void setUseDebugLocationOverride(bool enabled) {
    _useDebugOverride = enabled;
  }

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

    // Load existing profile location. If present, treat it as authoritative and
    // skip auto-updates (manual override). If absent, fall back to device.
    try {
      final snap = await _db.collection('users').doc(uid).get();
      final data = snap.data();
      final location = (data?['location'] as Map<String, dynamic>?) ?? {};
      final hasSavedLat = location['latitude'] != null;
      final hasSavedLng = location['longitude'] != null;

      if (hasSavedLat && hasSavedLng) {
        // Respect the saved profile location as source of truth
        _manualOverrideActive = true;
        stopTracking();
        if (kDebugMode) {
          debugPrint('🔒 Found saved profile location — using manual override');
        }
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error reading saved location: $e');
      }
    }

    // If no saved coordinates, ensure location services are enabled and start
    // auto updates from device (coarse accuracy)
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (kDebugMode) {
        debugPrint('Location services are disabled');
      }
      return false;
    }

    await _updateUserLocation();
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

    // Respect manual override: do not overwrite user-selected location
    if (_manualOverrideActive) {
      if (kDebugMode) {
        debugPrint('🔒 Manual override active — skipping auto location update');
      }
      return;
    }

    try {
      Position position;
      
      if (_useDebugOverride) {
        // Use debug coordinates for testing
        position = Position(
          latitude: _debugLatitude,
          longitude: _debugLongitude,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
        
        if (kDebugMode) {
          debugPrint('🔧 Using debug location: ${position.latitude}, ${position.longitude}');
        }
      } else {
        // Get current position with low accuracy for privacy
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low, // ~1-5km accuracy for privacy
            distanceFilter: 100, // Only update if moved 100m
          ),
        );
      }

      // Convert to GeoFirePoint
      final geoPoint = GeoFirePoint(
        GeoPoint(position.latitude, position.longitude),
      );

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
        debugPrint(
          '📍 Location updated: ${position.latitude}, ${position.longitude}',
        );
        debugPrint('📍 Geohash: $geohash');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating location: $e');
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
      debugPrint(
        'Location tracking started (updates every $_updateIntervalMinutes minutes)',
      );
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

  /// Set custom location (works in both debug and production)
  Future<void> setCustomLocation(double latitude, double longitude) async {
    if (kDebugMode) {
      debugPrint('🔧 ===== SET CUSTOM LOCATION STARTED =====');
      debugPrint('🔧 📍 Input coordinates: $latitude, $longitude');
      debugPrint('🔧 👤 Current user ID: $_currentUserId');
    }

    if (_currentUserId == null) {
      if (kDebugMode) {
        debugPrint('🔧 ❌ No current user ID - cannot set location');
        debugPrint('🔧 ===== SET CUSTOM LOCATION FAILED =====');
      }
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint('🔧 🔨 Creating Position object...');
      }
      // Create a custom position
      final position = Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      if (kDebugMode) {
        debugPrint('🔧 ✅ Position created: ${position.latitude}, ${position.longitude}');
        debugPrint('🔧 🌍 Converting to GeoFirePoint...');
      }

      // Convert to GeoFirePoint
      final geoPoint = GeoFirePoint(
        GeoPoint(position.latitude, position.longitude),
      );

      // Get geohash with specified precision
      final geohash = geoPoint.geohash.substring(0, _geohashPrecision);

      if (kDebugMode) {
        debugPrint('🔧 ✅ GeoFirePoint created');
        debugPrint('🔧 🗺️ Geohash: $geohash');
        debugPrint('🔧 💾 Writing to Firestore...');
      }

      // Update user's location in Firestore
      await _db.collection('users').doc(_currentUserId).set({
        'location': {
          'geohash': geohash,
          'geopoint': geoPoint.geopoint,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'lastUpdated': FieldValue.serverTimestamp(),
          'isVisible': true,
        },
      }, SetOptions(merge: true));

      // Activate manual override to prevent auto-updates from overwriting
      _manualOverrideActive = true;
      // Stop periodic GPS/debug updates while manual override is active
      stopTracking();

      // Invalidate proximity cache so Home reflects the new location immediately
      try {
        ProximityService.instance.clearCache();
      } catch (_) {
        // Safe to ignore cache clear failures
      }

      if (kDebugMode) {
        debugPrint('🔧 ✅ Firestore write completed successfully');
        debugPrint('🔧 📍 Final coordinates saved: $latitude, $longitude');
        debugPrint('🔧 🗺️ Final geohash: $geohash');
        debugPrint('🔧 👤 User document updated: $_currentUserId');
        debugPrint('🔧 ===== SET CUSTOM LOCATION COMPLETED =====');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔧 ❌ Error setting custom location: $e');
        debugPrint('🔧 ❌ Error type: ${e.runtimeType}');
        debugPrint('🔧 ===== SET CUSTOM LOCATION FAILED =====');
      }
      rethrow; // Re-throw so the calling code can handle the error
    }
  }

  /// Get current coordinates
  Future<Position?> getCurrentCoordinates() async {
    try {
      if (_useDebugOverride) {
        // Return debug coordinates for testing
        return Position(
          latitude: _debugLatitude,
          longitude: _debugLongitude,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      } else {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            distanceFilter: 100,
          ),
        );
        return position;
      }
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
