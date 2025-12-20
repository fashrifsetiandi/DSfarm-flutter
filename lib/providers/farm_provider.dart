/// Farm Provider
/// 
/// Riverpod providers for farm state management.
/// Handles current farm context and farm list.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/farm.dart';
import '../repositories/farm_repository.dart';

/// Repository provider
final farmRepositoryProvider = Provider<FarmRepository>((ref) {
  return FarmRepository();
});

/// Provider untuk list semua farms user
final farmsProvider = FutureProvider<List<Farm>>((ref) async {
  final repository = ref.watch(farmRepositoryProvider);
  return repository.getAllFarms();
});

/// Provider untuk current active farm
/// User harus pilih farm sebelum bisa akses fitur lain
final currentFarmProvider = StateProvider<Farm?>((ref) => null);

/// Provider untuk farm by ID
final farmByIdProvider = FutureProvider.family<Farm?, String>((ref, id) async {
  final repository = ref.watch(farmRepositoryProvider);
  return repository.getFarmById(id);
});

/// Notifier untuk farm CRUD operations
class FarmNotifier extends StateNotifier<AsyncValue<List<Farm>>> {
  final FarmRepository _repository;
  final Ref _ref;

  FarmNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadFarms();
  }

  /// Load all farms
  Future<void> loadFarms() async {
    state = const AsyncValue.loading();
    try {
      final farms = await _repository.getAllFarms();
      state = AsyncValue.data(farms);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Create new farm
  Future<Farm> createFarm({
    required String name,
    required String animalType,
    String? location,
    String? description,
  }) async {
    final farm = await _repository.createFarm(
      name: name,
      animalType: animalType,
      location: location,
      description: description,
    );
    
    // Reload farms list
    await loadFarms();
    
    // Set as current farm if it's the first one
    if (state.valueOrNull?.length == 1) {
      _ref.read(currentFarmProvider.notifier).state = farm;
    }
    
    return farm;
  }

  /// Update farm
  Future<void> updateFarm(Farm farm) async {
    await _repository.updateFarm(farm);
    await loadFarms();
    
    // Update current farm if it was the one updated
    final currentFarm = _ref.read(currentFarmProvider);
    if (currentFarm?.id == farm.id) {
      _ref.read(currentFarmProvider.notifier).state = farm;
    }
  }

  /// Delete farm
  Future<void> deleteFarm(String id) async {
    await _repository.deleteFarm(id);
    await loadFarms();
    
    // Clear current farm if it was deleted
    final currentFarm = _ref.read(currentFarmProvider);
    if (currentFarm?.id == id) {
      _ref.read(currentFarmProvider.notifier).state = null;
    }
  }
}

/// Provider untuk FarmNotifier
final farmNotifierProvider = StateNotifierProvider<FarmNotifier, AsyncValue<List<Farm>>>((ref) {
  final repository = ref.watch(farmRepositoryProvider);
  return FarmNotifier(repository, ref);
});
