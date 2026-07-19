import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/location_provider.dart';
import '../../../../core/network/api_client_provider.dart';
import '../../domain/entities/market_price.dart';

/// Market-intelligence data source (Section 4 of the brief).
///
/// Calls the backend (`GET /api/v1/market/prices`), passing the farmer's
/// real device location (shared `deviceLocationProvider`) so the backend
/// can compute genuine distance-to-market and flag the nearest one.
/// IMPORTANT: the *prices* themselves remain simulated — see
/// `bulimi_ai_backend/app/routers/market.py` for why — but distance and
/// "nearest market" are real, computed from actual coordinates.
final marketPricesProvider = FutureProvider.autoDispose<List<MarketPrice>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final location = await ref.watch(deviceLocationProvider.future);

  try {
    final response = await apiClient.get<List<dynamic>>(
      '/api/v1/market/prices',
      queryParameters: {'lat': location.latitude, 'lon': location.longitude},
    );
    return response.data!.map((item) {
      final map = item as Map<String, dynamic>;
      return MarketPrice(
        cropName: map['crop_name'] as String,
        marketName: map['market_name'] as String,
        pricePerKgUgx: (map['price_per_kg_ugx'] as num).toDouble(),
        changePercent: (map['change_percent'] as num).toDouble(),
        trend7Day: List<double>.from((map['trend_7_day'] as List).map((v) => (v as num).toDouble())),
        distanceKm: (map['distance_km'] as num?)?.toDouble(),
        isNearest: map['is_nearest'] as bool? ?? false,
      );
    }).toList();
  } catch (e) {
    return const [
      MarketPrice(
        cropName: 'Beans',
        marketName: 'Local market (offline)',
        pricePerKgUgx: 3800,
        changePercent: 0,
        trend7Day: [3800, 3800, 3800, 3800, 3800, 3800, 3800],
      ),
    ];
  }
});
