/// Housing Provider
/// 
/// Riverpod providers for housing state management.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/housing.dart';
import '../repositories/housing_repository.dart';
import '../providers/farm_provider.dart';

/// Repository provider
final housingRepositoryProvider = Provider<HousingRepository>((ref) {
  return HousingRepository();
});

/// Provider for housings of current farm
final housingsProvider = FutureProvider<List<Housing>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  final repository = ref.watch(housingRepositoryProvider);
  return repository.getByFarm(farm.id);
});

/// Provider for housings grouped by block
final housingsGroupedProvider = FutureProvider<Map<String, List<Housing>>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return {};
  
  final repository = ref.watch(housingRepositoryProvider);
  return repository.getByFarmGroupedByBlock(farm.id);
});

/// Provider for available housings (for dropdown selection)
final availableHousingsProvider = FutureProvider<List<Housing>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  final repository = ref.watch(housingRepositoryProvider);
  return repository.getAvailable(farm.id);
});

/// Notifier for housing CRUD operations
class HousingNotifier extends StateNotifier<AsyncValue<List<Housing>>> {
  final HousingRepository _repository;
  final String? _farmId;

  HousingNotifier(this._repository, this._farmId) 
      : super(_farmId == null ? const AsyncValue.data([]) : const AsyncValue.loading()) {
    if (_farmId != null) loadHousings();
  }

  Future<void> loadHousings() async {
    if (_farmId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    try {
      final housings = await _repository.getByFarm(_farmId);
      state = AsyncValue.data(housings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Housing> create({
    required String code,
    String? name,
    String? block,
    int capacity = 1,
    HousingType type = HousingType.individual,
    String? notes,
  }) async {
    if (_farmId == null) throw Exception('No farm selected');
    
    final housing = await _repository.create(
      farmId: _farmId,
      code: code,
      name: name,
      block: block,
      capacity: capacity,
      type: type,
      notes: notes,
    );
    
    await loadHousings();
    return housing;
  }

  Future<void> update(Housing housing) async {
    await _repository.update(housing);
    await loadHousings();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await loadHousings();
  }
}

/// Provider for HousingNotifier
final housingNotifierProvider = StateNotifierProvider<HousingNotifier, AsyncValue<List<Housing>>>((ref) {
  final repository = ref.watch(housingRepositoryProvider);
  final farm = ref.watch(currentFarmProvider);
  return HousingNotifier(repository, farm?.id);
});
