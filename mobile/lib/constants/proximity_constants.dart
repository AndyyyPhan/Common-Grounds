/// Proximity search configuration constants
/// Following industry best practices for location-based social apps
library;

/// Minimum search radius in kilometers
/// Covers immediate area (same building/block)
const double kMinSearchRadiusKm = 0.5;

/// Default search radius in kilometers
/// Comfortable 15-20 minute walk, covers most campus areas
const double kDefaultSearchRadiusKm = 1.5;

/// Maximum search radius in kilometers
/// Covers entire campus, ~30 minute walk maximum
const double kMaxSearchRadiusKm = 3.0;

/// Minimum number of common interests required for a match
const int kMinCommonInterests = 1;

/// Default result limit for proximity searches
const int kDefaultResultLimit = 10;

/// Cache expiry duration for proximity matches
const Duration kMatchCacheExpiry = Duration(minutes: 5);

/// Helper to clamp radius within valid bounds
double clampSearchRadius(double radius) {
  return radius.clamp(kMinSearchRadiusKm, kMaxSearchRadiusKm);
}

/// Format radius for display (shows meters if < 1km)
String formatRadius(double radiusKm) {
  if (radiusKm < 1.0) {
    return '${(radiusKm * 1000).round()}m';
  }
  return '${radiusKm.toStringAsFixed(1)}km';
}
