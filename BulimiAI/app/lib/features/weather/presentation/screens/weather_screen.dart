import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../widgets/shared_widgets.dart';
import '../../domain/entities/weather_entity.dart';
import '../providers/weather_provider.dart';

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Weather Advisor')),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(weatherProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.spaceMd),
          children: [
            AsyncStateView<WeatherSnapshot>(
              value: weatherAsync,
              builder: (weather) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CurrentConditions(weather: weather),
                  const SizedBox(height: AppConstants.spaceMd),
                  if (weather.alertLevel != WeatherAlertLevel.none) ...[
                    AppAlertBanner(
                      message: weather.aiRecommendation,
                      color: weather.alertLevel == WeatherAlertLevel.flood
                          ? AppColors.floodAlert
                          : AppColors.droughtAlert,
                      icon: weather.alertLevel == WeatherAlertLevel.flood
                          ? Icons.water_drop_outlined
                          : Icons.wb_sunny_outlined,
                    ),
                    const SizedBox(height: AppConstants.spaceMd),
                  ],
                  AppSectionCard(
                    title: '5-day forecast',
                    icon: Icons.calendar_month_outlined,
                    child: Column(
                      children: weather.forecast
                          .map((f) => _ForecastRow(forecast: f))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spaceMd),
                  AppSectionCard(
                    title: 'Irrigation advice',
                    icon: Icons.water_outlined,
                    child: Text(
                      weather.forecast.first.rainChancePercent > 60
                          ? 'Your farm does not need irrigation today — rainfall is likely.'
                          : 'Low rain chance today. Consider irrigating if soil is dry.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentConditions extends StatelessWidget {
  final WeatherSnapshot weather;
  const _CurrentConditions({required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spaceLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.secondaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(weather.village, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            '${weather.currentTempC.round()}°C',
            style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.spaceSm),
          Row(
            children: [
              _MiniStat(icon: Icons.water_drop, label: '${weather.humidityPercent}%'),
              const SizedBox(width: AppConstants.spaceLg),
              _MiniStat(icon: Icons.air, label: '${weather.windKph.round()} kph'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _ForecastRow extends StatelessWidget {
  final DailyForecast forecast;
  const _ForecastRow({required this.forecast});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 48, child: Text(DateFormat('E').format(forecast.date))),
          Expanded(child: Text(forecast.condition, style: Theme.of(context).textTheme.bodyMedium)),
          Text('${forecast.rainChancePercent}%', style: const TextStyle(color: AppColors.secondary)),
          const SizedBox(width: AppConstants.spaceMd),
          Text('${forecast.tempHighC.round()}° / ${forecast.tempLowC.round()}°'),
        ],
      ),
    );
  }
}
