import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../config/routes/app_router.dart';
import '../../../../widgets/shared_widgets.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../weather/domain/entities/weather_entity.dart';
import '../../../weather/presentation/providers/weather_provider.dart';
import '../../../market/domain/entities/market_price.dart';
import '../../../market/presentation/providers/market_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';

final _currency = NumberFormat.currency(locale: 'en_UG', symbol: 'UGX ', decimalDigits: 0);

/// The farmer's main landing screen (Section 6 of the brief): today's
/// weather, AI recommendations, crop health shortcut, market snapshot,
/// and alerts — deliberately simple, card-based, and scannable for
/// farmers with limited digital experience.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);
    final pricesAsync = ref.watch(marketPricesProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user?.fullName ?? 'Farmer'} 👋'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () => context.push(AppRoutes.notifications),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weatherProvider);
          ref.invalidate(marketPricesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.spaceMd),
          children: [
            AsyncStateView<WeatherSnapshot>(
              value: weatherAsync,
              builder: (weather) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (weather.alertLevel != WeatherAlertLevel.none)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppConstants.spaceMd),
                      child: AppAlertBanner(
                        message: weather.aiRecommendation,
                        color: weather.alertLevel == WeatherAlertLevel.flood
                            ? AppColors.floodAlert
                            : AppColors.droughtAlert,
                        icon: weather.alertLevel == WeatherAlertLevel.flood
                            ? Icons.water_drop_outlined
                            : Icons.wb_sunny_outlined,
                      ),
                    ),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.weather),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppConstants.spaceLg),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.secondary, AppColors.secondaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(weather.village, style: const TextStyle(color: Colors.white70)),
                              Text(
                                '${weather.currentTempC.round()}°C',
                                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white70, size: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spaceLg),
            Text('Quick actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppConstants.spaceSm),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.camera_alt_outlined,
                    label: 'Check crop\nhealth',
                    color: AppColors.primary,
                    onTap: () => context.push(AppRoutes.diseaseDetection),
                  ),
                ),
                const SizedBox(width: AppConstants.spaceMd),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.mic_outlined,
                    label: 'Ask Mkulima\nAI',
                    color: AppColors.secondary,
                    onTap: () => context.go(AppRoutes.voiceAssistant),
                  ),
                ),
                const SizedBox(width: AppConstants.spaceMd),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.storefront_outlined,
                    label: 'Market\nprices',
                    color: AppColors.tertiary,
                    onTap: () => context.go(AppRoutes.market),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spaceLg),
            AppSectionCard(
              title: 'Market snapshot',
              icon: Icons.show_chart,
              trailing: TextButton(
                onPressed: () => context.go(AppRoutes.market),
                child: const Text('See all'),
              ),
              child: AsyncStateView<List<MarketPrice>>(
                value: pricesAsync,
                builder: (prices) {
                  final topThree = prices.take(3).toList();
                  return Column(
                    children: topThree
                        .map((p) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${p.cropName} · ${p.marketName}'),
                                  Text(_currency.format(p.pricePerKgUgx)),
                                ],
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: AppConstants.spaceLg),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceMd),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
