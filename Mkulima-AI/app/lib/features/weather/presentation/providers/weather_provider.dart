import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/location_provider.dart';
import '../../../../core/network/api_client_provider.dart';
import '../../domain/entities/weather_entity.dart';

final weatherProvider = FutureProvider.autoDispose<WeatherSnapshot>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final location = await ref.watch(deviceLocationProvider.future);

  final villageName = location.isReal ? 'Your location' : 'Kiryandongo';

  try {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/api/v1/weather',
      queryParameters: {'lat': location.latitude, 'lon': location.longitude, 'village_name': villageName},
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
      subcounty: data['subcounty'] as String?,
      district: data['district'] as String?,
      currentTempC: (data['current_temp_c'] as num).toDouble(),
      humidityPercent: data['humidity_percent'] as int,
      windKph: (data['wind_kph'] as num).toDouble(),
      alertLevel: _parseAlertLevel(data['alert_level'] as String),
      aiRecommendation: data['ai_recommendation'] as String,
      forecast: forecastList,
    );
  } catch (e) {
    final now = DateTime.now();
    return WeatherSnapshot(
      village: '$villageName (offline)',
      currentTempC: 27,
      humidityPercent: 68,
      windKph: 12,
      alertLevel: WeatherAlertLevel.none,
      aiRecommendation: 'Could not reach the weather service. Showing a placeholder — connect to the '
          'internet for a real forecast.',
      forecast: List.generate(3, (i) {
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
