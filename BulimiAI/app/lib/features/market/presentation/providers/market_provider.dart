import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../domain/entities/market_price.dart';

/// Market-intelligence data source (Section 4 of the brief).
///
/// Calls the Mkulima AI backend (bulimi_ai_backend/) (`GET /api/v1/market/prices`). IMPORTANT:
/// as documented in `bulimi_ai_backend/app/routers/market.py`, this data is
/// currently simulated server-side — there is no free, reliable live public
/// API for Ugandan crop market prices. Routing through the backend now
/// (rather than generating mock data on-device) means swapping in a real
/// data source later only requires changing the backend, not the app.
final marketPricesProvider = FutureProvider.autoDispose<List<MarketPrice>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);

  try {
    final response = await apiClient.get<List<dynamic>>('/api/v1/market/prices');
    return response.data!.map((item) {
      final map = item as Map<String, dynamic>;
      return MarketPrice(
        cropName: map['crop_name'] as String,
        marketName: map['market_name'] as String,
        pricePerKgUgx: (map['price_per_kg_ugx'] as num).toDouble(),
        changePercent: (map['change_percent'] as num).toDouble(),
        trend7Day: List<double>.from((map['trend_7_day'] as List).map((v) => (v as num).toDouble())),
      );
    }).toList();
  } catch (e) {
    // Backend unreachable — minimal local fallback so the screen isn't empty.
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
