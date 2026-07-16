import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/storage/local_cache_service.dart';
import '../../domain/entities/farm_record.dart';

const _storageKey = 'farm_records';

final localCacheServiceProvider = Provider<LocalCacheService>((ref) => LocalCacheService());

/// Farm records store with real offline persistence.
///
/// On creation, loads any previously-saved records from disk (see
/// `LocalCacheService`) — falling back to two starter example farms only
/// if nothing has been saved yet (i.e. first-ever launch). Every mutation
/// (add/update/remove/expense/income) persists the full list back to disk
/// immediately, so farm data survives app restarts with no network
/// required — genuinely useful for farmers with unreliable connectivity.
class FarmManagementController extends StateNotifier<List<FarmRecord>> {
  final LocalCacheService _cache;

  FarmManagementController(this._cache) : super([]) {
    _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    final saved = await _cache.load(_storageKey);
    if (saved is List && saved.isNotEmpty) {
      state = saved.map((e) => FarmRecord.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      // First-ever launch: seed with example farms so the screen isn't empty.
      state = [
        FarmRecord(
          id: const Uuid().v4(),
          name: 'Home Garden Plot',
          cropName: 'Tomatoes',
          sizeAcres: 0.5,
          plantingDate: DateTime.now().subtract(const Duration(days: 40)),
          totalExpensesUgx: 180000,
          totalIncomeUgx: 260000,
        ),
        FarmRecord(
          id: const Uuid().v4(),
          name: 'Riverside Field',
          cropName: 'Maize',
          sizeAcres: 2.0,
          plantingDate: DateTime.now().subtract(const Duration(days: 70)),
          totalExpensesUgx: 420000,
          totalIncomeUgx: 300000,
        ),
      ];
      await _persist();
    }
  }

  Future<void> _persist() async {
    await _cache.save(_storageKey, state.map((f) => f.toJson()).toList());
  }

  Future<void> addFarm(FarmRecord farm) async {
    state = [...state, farm];
    await _persist();
  }

  Future<void> updateFarm(FarmRecord updated) async {
    state = [for (final f in state) if (f.id == updated.id) updated else f];
    await _persist();
  }

  Future<void> addExpense(String farmId, double amount) async {
    state = [
      for (final f in state)
        if (f.id == farmId) f.copyWith(totalExpensesUgx: f.totalExpensesUgx + amount) else f,
    ];
    await _persist();
  }

  Future<void> addIncome(String farmId, double amount) async {
    state = [
      for (final f in state)
        if (f.id == farmId) f.copyWith(totalIncomeUgx: f.totalIncomeUgx + amount) else f,
    ];
    await _persist();
  }

  Future<void> removeFarm(String farmId) async {
    state = state.where((f) => f.id != farmId).toList();
    await _persist();
  }
}

final farmManagementProvider =
    StateNotifierProvider<FarmManagementController, List<FarmRecord>>(
  (ref) => FarmManagementController(ref.watch(localCacheServiceProvider)),
);
