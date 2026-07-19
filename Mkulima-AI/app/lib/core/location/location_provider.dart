import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Simple lat/lon pair with a flag for whether it's the farmer's real
/// device location or a fallback reference point.
class DeviceLocation {
  final double latitude;
  final double longitude;
  final bool isReal;

  const DeviceLocation({required this.latitude, required this.longitude, required this.isReal});

  static const fallback = DeviceLocation(
    latitude: 1.6667, // Kiryandongo, Uganda
    longitude: 32.0,
    isReal: false,
  );
}

/// Shared device-location provider.
///
/// Requests location permission and reads GPS **once per app session**
/// (cached by Riverpod's default `Provider`/`FutureProvider` behavior),
/// so Weather, Market, and any future feature that needs the farmer's
/// location all share the same permission prompt and the same result,
/// instead of each asking independently. Falls back to a fixed reference
/// point (Kiryandongo, Uganda) if permission is denied or location is
/// otherwise unavailable (e.g. running in an emulator with no GPS).
final deviceLocationProvider = FutureProvider<DeviceLocation>((ref) async {
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return DeviceLocation.fallback;
    }

    final position = await Geolocator.getCurrentPosition();
    return DeviceLocation(latitude: position.latitude, longitude: position.longitude, isReal: true);
  } catch (_) {
    return DeviceLocation.fallback;
  }
});
