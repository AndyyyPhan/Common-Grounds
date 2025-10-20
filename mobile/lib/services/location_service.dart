import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  LocationService._();
  static final instance = LocationService._();

  static const String _locationKey = 'last_known_location';
  static const String _locationEnabledKey = 'location_enabled';
  
  // Global matching - no campus restrictions
  // Users can match anywhere in the world
  
  StreamController<Position>? _locationController;
  StreamSubscription<Position>? _locationSubscription;
  Position? _lastKnownPosition;
  bool _isLocationEnabled = false;

  Stream<Position> get locationStream {
    _locationController ??= StreamController<Position>.broadcast();
    return _locationController!.stream;
  }

  Position? get lastKnownPosition => _lastKnownPosition;
  bool get isLocationEnabled => _isLocationEnabled;

  /// Initialize location service and request permissions
  Future<bool> initialize() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // Request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      // Request background location permission for Android
      if (await Permission.locationAlways.isDenied) {
        await Permission.locationAlways.request();
      }

      _isLocationEnabled = true;
      await _loadLastKnownLocation();
      return true;
    } catch (e) {
      print('Location service initialization error: $e');
      return false;
    }
  }

  /// Start location tracking
  Future<void> startLocationTracking() async {
    if (!_isLocationEnabled) return;

    try {
      _locationSubscription?.cancel();
      
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 10, // Update every 10 meters
      );

      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _lastKnownPosition = position;
          _locationController?.add(position);
          _saveLastKnownLocation(position);
        },
        onError: (error) {
          print('Location tracking error: $error');
        },
      );
    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    if (!_isLocationEnabled) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      _lastKnownPosition = position;
      _saveLastKnownLocation(position);
      return position;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Check if user location is valid (always true for global matching)
  bool isOnCampus(Position? position) {
    if (position == null) return false;
    
    print('User position: ${position.latitude}, ${position.longitude}');
    print('Global matching enabled - location valid anywhere');
    
    return true; // Allow matching anywhere in the world
  }

  /// Get coarse location (rounded to reduce precision)
  Map<String, double> getCoarseLocation(Position position) {
    // Round to ~100m precision
    const double precision = 0.001; // ~100m
    return {
      'lat': (position.latitude / precision).round() * precision,
      'lng': (position.longitude / precision).round() * precision,
    };
  }

  /// Calculate distance between two positions
  double calculateDistance(Position pos1, Position pos2) {
    return Geolocator.distanceBetween(
      pos1.latitude,
      pos1.longitude,
      pos2.latitude,
      pos2.longitude,
    );
  }

  /// Check if two users are within proximity (e.g., 50 meters)
  bool areWithinProximity(Position pos1, Position pos2, {double maxDistance = 50}) {
    return calculateDistance(pos1, pos2) <= maxDistance;
  }

  /// Save last known location to local storage
  Future<void> _saveLastKnownLocation(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_locationKey, '${position.latitude},${position.longitude}');
    } catch (e) {
      print('Error saving location: $e');
    }
  }

  /// Load last known location from local storage
  Future<void> _loadLastKnownLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationString = prefs.getString(_locationKey);
      if (locationString != null) {
        final parts = locationString.split(',');
        if (parts.length == 2) {
          _lastKnownPosition = Position(
            latitude: double.parse(parts[0]),
            longitude: double.parse(parts[1]),
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        }
      }
    } catch (e) {
      print('Error loading location: $e');
    }
  }

  /// Enable/disable location tracking
  Future<void> setLocationEnabled(bool enabled) async {
    _isLocationEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationEnabledKey, enabled);
    
    if (enabled) {
      await startLocationTracking();
    } else {
      await stopLocationTracking();
    }
  }

  /// Dispose resources
  void dispose() {
    _locationSubscription?.cancel();
    _locationController?.close();
  }
}
