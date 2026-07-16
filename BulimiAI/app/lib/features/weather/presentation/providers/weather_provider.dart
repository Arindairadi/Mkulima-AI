import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../domain/entities/weather_entity.dart';

/// Live weather data source.
///
/// Calls the Mkulima AI backend (bulimi_ai_backend/) (`GET /api/v1/weather`), which fetches real
/// forecast data from Open-Meteo and an AI-generated recommendation from
/// Gemini. Tries to use the device's real GPS location via `geolocator`;
/// if location permission is denied or unavailable, falls back to a fixed
/// reference point (Kiryandongo, Uganda) so the feature still works.
/// If the backend itself is unreachable, falls back further to a fully
/// local mock forecast so the screen never shows a dead end.
final weatherProvider = FutureProvider.autoDispose<WeatherSnapshot>((ref) async {
  final apiClient = ref.watch(apiClientProvider);

  double lat = 1.6667; // Kiryandongo, Uganda — fallback reference point
  double lon = 32.0;
  String villageName = 'Kiryandongo';

  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested != LocationPermission.denied && requested != LocationPermission.deniedForever) {
        final position = await Geolocator.getCurrentPosition();
        lat = position.latitude;
        lon = position.longitude;
        villageName = 'Your location';
      }
    } else if (permission != LocationPermission.deniedForever) {
      final position = await Geolocator.getCurrentPosition();
      lat = position.latitude;
      lon = position.longitude;
      villageName = 'Your location';
    }
  } catch (_) {
    // Location unavailable (emulator, permission denied, etc.) — proceed
    // with the fallback reference point set above.
  }

  try {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/api/v1/weather',
      queryParameters: {'lat': lat, 'lon': lon, 'village_name': villageName},
    );
    final data = response.data!;
    final forecastList = (data['forecast'] as List).map((f) {
      return DailyForecast(
        date: DateTime.parse(f['date'] as String),
        tempHighC: (f['temp_high_c'] as num).toDouble(),
        tempLowC: (f['temp_low_c'] as num).toDouble(),
        rainChancePercent: f['rain_chance_percent'] as int,
        condition: f['condition'] as String,
      );
    }).toList();

    return WeatherSnapshot(
      village: data['village'] as String,
      currentTempC: (data['current_temp_c'] as num).toDouble(),
      humidityPercent: data['humidity_percent'] as int,
      windKph: (data['wind_kph'] as num).toDouble(),
      alertLevel: _parseAlertLevel(data['alert_level'] as String),
      aiRecommendation: data['ai_recommendation'] as String,
      forecast: forecastList,
    );
  } catch (e) {
    // Backend unreachable — fall back to a local mock forecast rather than
    // showing an error screen. Clearly a fallback, not a real forecast.
    final now = DateTime.now();
    return WeatherSnapshot(
      village: '$villageName (offline)',
      currentTempC: 27,
      humidityPercent: 68,
      windKph: 12,
      alertLevel: WeatherAlertLevel.none,
      aiRecommendation: 'Could not reach the weather service. Showing a placeholder — connect to the '
          'internet for a real forecast.',
      forecast: List.generate(5, (i) {
        return DailyForecast(
          date: now.add(Duration(days: i)),
          tempHighC: 26,
          tempLowC: 18,
          rainChancePercent: 30,
          condition: 'Unknown (offline)',
        );
      }),
    );
  }
});

WeatherAlertLevel _parseAlertLevel(String value) {
  switch (value) {
    case 'flood':
      return WeatherAlertLevel.flood;
    case 'drought':
      return WeatherAlertLevel.drought;
    default:
      return WeatherAlertLevel.none;
  }
}
