import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/shared_widgets.dart';
import '../../domain/entities/market_price.dart';
import '../providers/market_provider.dart';

final _currency = NumberFormat.currency(locale: 'en_UG', symbol: 'UGX ', decimalDigits: 0);

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  String _selectedCrop = 'Beans';

  @override
  Widget build(BuildContext context) {
    final pricesAsync = ref.watch(marketPricesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Market Intelligence')),
      body: AsyncStateView<List<MarketPrice>>(
        value: pricesAsync,
        builder: (prices) {
          final crops = prices.map((p) => p.cropName).toSet().toList();
          final selectedPrices = prices.where((p) => p.cropName == _selectedCrop).toList()
            ..sort((a, b) => b.pricePerKgUgx.compareTo(a.pricePerKgUgx));
          final best = selectedPrices.isNotEmpty ? selectedPrices.first : null;
          final worst = selectedPrices.isNotEmpty ? selectedPrices.last : null;

          return ListView(
            padding: const EdgeInsets.all(AppConstants.spaceMd),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: crops.map((c) {
                  final selected = c == _selectedCrop;
                  return ChoiceChip(
                    label: Text(c),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedCrop = c),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppConstants.spaceMd),
              if (best != null && worst != null && best.marketName != worst.marketName)
                AppAlertBanner(
                  message:
                      '$_selectedCrop is selling higher in ${best.marketName} (${_currency.format(best.pricePerKgUgx)}) '
                      'than in ${worst.marketName} (${_currency.format(worst.pricePerKgUgx)}).',
                  color: AppColors.info,
                  icon: Icons.trending_up,
                ),
              const SizedBox(height: AppConstants.spaceMd),
              if (best != null)
                AppSectionCard(
                  title: '$_selectedCrop — 7-day trend (${best.marketName})',
                  icon: Icons.show_chart,
                  child: SizedBox(
                    height: 160,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (var i = 0; i < best.trend7Day.length; i++)
                                FlSpot(i.toDouble(), best.trend7Day[i]),
                            ],
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.primary.withValues(alpha: 0.12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppConstants.spaceMd),
              Text('Compare markets', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppConstants.spaceSm),
              ...selectedPrices.map((p) => _MarketPriceRow(price: p)),
            ],
          );
        },
      ),
    );
  }
}

class _MarketPriceRow extends StatelessWidget {
  final MarketPrice price;
  const _MarketPriceRow({required this.price});

  @override
  Widget build(BuildContext context) {
    final up = price.changePercent >= 0;
    return Card(
      child: ListTile(
        title: Text(price.marketName),
        subtitle: Text(_currency.format(price.pricePerKgUgx)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16, color: up ? AppColors.success : AppColors.danger),
            const SizedBox(width: 4),
            Text(
              '${price.changePercent.abs().toStringAsFixed(1)}%',
              style: TextStyle(color: up ? AppColors.success : AppColors.danger),
            ),
          ],
        ),
      ),
    );
  }
}
