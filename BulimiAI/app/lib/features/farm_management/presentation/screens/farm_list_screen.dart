import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/farm_record.dart';
import '../providers/farm_provider.dart';
import 'farm_detail_screen.dart';

final _currency = NumberFormat.currency(locale: 'en_UG', symbol: 'UGX ', decimalDigits: 0);

class FarmListScreen extends ConsumerWidget {
  const FarmListScreen({super.key});

  void _showAddFarmSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final sizeCtrl = TextEditingController();
    String crop = AppConstants.supportedCrops.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: AppConstants.spaceLg,
            right: AppConstants.spaceLg,
            top: AppConstants.spaceLg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppConstants.spaceLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add a farm', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppConstants.spaceMd),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Farm / plot name')),
              const SizedBox(height: AppConstants.spaceMd),
              DropdownButtonFormField<String>(
                initialValue: crop,
                items: AppConstants.supportedCrops
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => crop = v ?? crop),
                decoration: const InputDecoration(labelText: 'Crop'),
              ),
              const SizedBox(height: AppConstants.spaceMd),
              TextField(
                controller: sizeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Size (acres)'),
              ),
              const SizedBox(height: AppConstants.spaceLg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final size = double.tryParse(sizeCtrl.text) ?? 0;
                    if (nameCtrl.text.trim().isEmpty || size <= 0) return;
                    ref.read(farmManagementProvider.notifier).addFarm(
                          FarmRecord(
                            id: const Uuid().v4(),
                            name: nameCtrl.text.trim(),
                            cropName: crop,
                            sizeAcres: size,
                            plantingDate: DateTime.now(),
                          ),
                        );
                    Navigator.pop(context);
                  },
                  child: const Text('Save farm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farms = ref.watch(farmManagementProvider);
    final totalProfit = farms.fold<double>(0, (sum, f) => sum + f.profitUgx);

    return Scaffold(
      appBar: AppBar(title: const Text('Farm Management')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFarmSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: farms.isEmpty
          ? const Center(child: Text('No farms yet. Tap + to add your first plot.'))
          : ListView(
              padding: const EdgeInsets.all(AppConstants.spaceMd),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spaceMd),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total profit (all farms)', style: Theme.of(context).textTheme.bodyMedium),
                      Text(
                        _currency.format(totalProfit),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: totalProfit >= 0 ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spaceMd),
                ...farms.map((farm) => _FarmCard(farm: farm)),
              ],
            ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  final FarmRecord farm;
  const _FarmCard({required this.farm});

  @override
  Widget build(BuildContext context) {
    final profit = farm.profitUgx;
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spaceMd),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppConstants.spaceMd),
        title: Text(farm.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${farm.cropName} · ${farm.sizeAcres} acres'),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _currency.format(profit),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: profit >= 0 ? AppColors.success : AppColors.danger,
              ),
            ),
            const Text('profit', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FarmDetailScreen(farmId: farm.id)),
        ),
      ),
    );
  }
}
