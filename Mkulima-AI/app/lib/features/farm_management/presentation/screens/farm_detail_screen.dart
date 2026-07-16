import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/shared_widgets.dart';
import '../providers/farm_provider.dart';

final _currency = NumberFormat.currency(locale: 'en_UG', symbol: 'UGX ', decimalDigits: 0);
final _dateFormat = DateFormat('d MMM yyyy');

class FarmDetailScreen extends ConsumerWidget {
  final String farmId;
  const FarmDetailScreen({super.key, required this.farmId});

  void _showAmountDialog(BuildContext context, WidgetRef ref, {required bool isExpense}) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isExpense ? 'Add expense' : 'Add income'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (UGX)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(ctrl.text) ?? 0;
              if (amount <= 0) return;
              final notifier = ref.read(farmManagementProvider.notifier);
              isExpense ? notifier.addExpense(farmId, amount) : notifier.addIncome(farmId, amount);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farms = ref.watch(farmManagementProvider);
    final farm = farms.firstWhere((f) => f.id == farmId, orElse: () => farms.first);
    final profit = farm.profitUgx;

    return Scaffold(
      appBar: AppBar(title: Text(farm.name)),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spaceMd),
        children: [
          AppSectionCard(
            title: 'Farm details',
            icon: Icons.grass_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Crop', value: farm.cropName),
                _DetailRow(label: 'Size', value: '${farm.sizeAcres} acres'),
                _DetailRow(label: 'Planted on', value: _dateFormat.format(farm.plantingDate)),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceMd),
          AppSectionCard(
            title: 'Profit summary',
            icon: Icons.bar_chart_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Income', value: _currency.format(farm.totalIncomeUgx), valueColor: AppColors.success),
                _DetailRow(label: 'Expenses', value: _currency.format(farm.totalExpensesUgx), valueColor: AppColors.danger),
                const Divider(),
                _DetailRow(
                  label: 'Net profit',
                  value: _currency.format(profit),
                  valueColor: profit >= 0 ? AppColors.success : AppColors.danger,
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceMd),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAmountDialog(context, ref, isExpense: true),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Add expense'),
                ),
              ),
              const SizedBox(width: AppConstants.spaceMd),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAmountDialog(context, ref, isExpense: false),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add income'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spaceMd),
          AppSectionCard(
            title: 'Recommendation',
            icon: Icons.lightbulb_outline,
            child: Text(
              profit >= 0
                  ? 'This farm is profitable so far. Consider reinvesting part of the profit into quality '
                      'inputs for the next season.'
                  : 'Expenses currently exceed income on this farm. Review input costs and check the Market '
                      'Intelligence tab for better-selling markets nearby.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _DetailRow({required this.label, required this.value, this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
