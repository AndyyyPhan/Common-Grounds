import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/location_service.dart';

class LocationPickerPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const LocationPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set initial location if provided, otherwise use default
    _selectedLocation = widget.initialLatitude != null && widget.initialLongitude != null
        ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
        : null;
    _selectedAddress = widget.initialAddress;

    // If no initial coordinates were provided, load from user's saved profile
    if (_selectedLocation == null) {
      _loadSavedProfileLocation();
    }
    // As an absolute fallback, use a neutral default only if nothing loads
    _selectedLocation ??= const LatLng(38.03199384346889, -78.51068317176542);
  }

  Future<void> _loadSavedProfileLocation() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      final data = snap.data();
      final location = (data?['location'] as Map<String, dynamic>?) ?? {};
      final lat = location['latitude'] as num?;
      final lng = location['longitude'] as num?;
      if (lat != null && lng != null) {
        final latLng = LatLng(lat.toDouble(), lng.toDouble());
        if (mounted) {
          setState(() {
            _selectedLocation = latLng;
          });
          // Recenter map if already created
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: latLng, zoom: 15.0),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🗺️ Error loading saved profile location: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Location'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveLocation,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading 
                    ? Theme.of(context).disabledColor
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation!,
              zoom: 15.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            onTap: _onMapTapped,
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected_location'),
                      position: _selectedLocation!,
                      infoWindow: InfoWindow(
                        title: 'Your Location',
                        snippet: _selectedAddress ?? 'Tap to select location',
                      ),
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            zoomControlsEnabled: true,
            mapToolbarEnabled: true,
          ),

          // Location Info Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Selected Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_selectedAddress != null) ...[
                      Text(
                        _selectedAddress!,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      'Lat: ${_selectedLocation?.latitude.toStringAsFixed(6) ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Lng: ${_selectedLocation?.longitude.toStringAsFixed(6) ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Instructions Card
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'How to Use',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Tap anywhere on the map to set your location\n'
                      '• Use the location button to center on your current position\n'
                      '• Pinch to zoom in/out for precise selection\n'
                      '• Tap "Save" when you\'re happy with your location',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Saving your location...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onMapTapped(LatLng location) {
    if (kDebugMode) {
      debugPrint('🗺️ Map tapped at: ${location.latitude}, ${location.longitude}');
    }
    
    setState(() {
      _selectedLocation = location;
      _selectedAddress = null; // Clear address, will be fetched if needed
    });

    if (kDebugMode) {
      debugPrint('🗺️ Pin placed at: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}');
    }

    // Optional: Fetch address for the selected location
    _fetchAddressForLocation(location);
  }

  Future<void> _fetchAddressForLocation(LatLng location) async {
    // For now, we'll just show coordinates
    // In a real app, you might want to use Google Geocoding API
    setState(() {
      _selectedAddress = 'Location: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
    });
  }

  Future<void> _saveLocation() async {
    if (kDebugMode) {
      debugPrint('🗺️ ===== SAVE LOCATION STARTED =====');
    }
    
    if (_selectedLocation == null) {
      if (kDebugMode) {
        debugPrint('🗺️ ❌ No location selected - showing error');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first')),
      );
      return;
    }

    if (kDebugMode) {
      debugPrint('🗺️ ✅ Save button pressed with location: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}');
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update location using LocationService
      if (kDebugMode) {
        debugPrint('🗺️ 📞 Calling LocationService.setCustomLocation...');
      }
      
      await LocationService.instance.setCustomLocation(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );

      if (kDebugMode) {
        debugPrint('🗺️ ✅ LocationService.setCustomLocation completed successfully');
      }

      if (mounted) {
        if (kDebugMode) {
          debugPrint('🗺️ 📱 Showing success message and navigating back');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location updated to ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Return the new coordinates to trigger refresh
        Navigator.of(context).pop({
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🗺️ ❌ Error in _saveLocation: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (kDebugMode) {
        debugPrint('🗺️ ===== SAVE LOCATION COMPLETED =====');
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
