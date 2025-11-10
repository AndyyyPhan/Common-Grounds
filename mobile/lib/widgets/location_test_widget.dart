import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

/// Debug widget for testing location functionality
/// Only shows in debug mode
class LocationTestWidget extends StatefulWidget {
  const LocationTestWidget({super.key});

  @override
  State<LocationTestWidget> createState() => _LocationTestWidgetState();
}

class _LocationTestWidgetState extends State<LocationTestWidget> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    final position = await LocationService.instance.getCurrentCoordinates();
    if (position != null) {
      setState(() {
        _currentPosition = position;
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
      });
    }
  }

  Future<void> _setCustomLocation() async {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid coordinates')),
      );
      return;
    }

    if (lat < -90 || lat > 90) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Latitude must be between -90 and 90')),
      );
      return;
    }

    if (lng < -180 || lng > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Longitude must be between -180 and 180')),
      );
      return;
    }

    await LocationService.instance.setCustomLocation(lat, lng);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Location set to: $lat, $lng')),
    );

    // Refresh current location display
    await _loadCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🔧 Location Testing (Debug Mode)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            
            // Current Location Display
            if (_currentPosition != null) ...[
              const Text('Current Location:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}'),
              Text('Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 16),
            ],

            // Custom Location Input
            const Text('Set Custom Location:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      hintText: '38.031994',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lngController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      hintText: '-78.510683',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _setCustomLocation,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Set Location'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadCurrentLocation,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Quick Location Buttons
            const Text('Quick Locations:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickLocationButton('Your Location', 38.03199384346889, -78.51068317176542),
                _buildQuickLocationButton('Google HQ', 37.4220936, -122.083922),
                _buildQuickLocationButton('Times Square', 40.7580, -73.9855),
                _buildQuickLocationButton('Golden Gate', 37.8199, -122.4783),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLocationButton(String label, double lat, double lng) {
    return ElevatedButton(
      onPressed: () async {
        _latController.text = lat.toString();
        _lngController.text = lng.toString();
        await _setCustomLocation();
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label),
    );
  }
}
