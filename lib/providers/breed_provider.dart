/// Breed Provider
/// 
/// Riverpod providers for breed state management.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/breed.dart';
import '../repositories/breed_repository.dart';
import '../providers/farm_provider.dart';

/// Repository provider
final breedRepositoryProvider = Provider<BreedRepository>((ref) {
  return BreedRepository();
});

/// Provider for all breeds of current farm
final breedsProvider = FutureProvider<List<Breed>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  final repository = ref.watch(breedRepositoryProvider);
  return repository.getByFarm(farm.id);
});

/// Notifier for breed CRUD
class BreedNotifier extends StateNotifier<AsyncValue<List<Breed>>> {
  final BreedRepository _repository;
  final String? _farmId;

  BreedNotifier(this._repository, this._farmId) 
      : super(_farmId == null ? const AsyncValue.data([]) : const AsyncValue.loading()) {
    if (_farmId != null) loadBreeds();
  }

  Future<void> loadBreeds() async {
    print('BreedNotifier.loadBreeds called, farmId: $_farmId');
    if (_farmId == null) {
      print('BreedNotifier: farmId is null, returning empty list');
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    try {
      final breeds = await _repository.getByFarm(_farmId);
      print('BreedNotifier: loaded ${breeds.length} breeds');
      state = AsyncValue.data(breeds);
    } catch (e, st) {
      print('BreedNotifier ERROR: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<Breed> create({
    required String code,
    required String name,
    String? description,
  }) async {
    if (_farmId == null) throw Exception('No farm selected');
    
    final breed = await _repository.create(
      farmId: _farmId,
      code: code,
      name: name,
      description: description,
    );
    
    await loadBreeds();
    return breed;
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await loadBreeds();
  }
}

/// Provider for BreedNotifier
final breedNotifierProvider = StateNotifierProvider<BreedNotifier, AsyncValue<List<Breed>>>((ref) {
  final repository = ref.watch(breedRepositoryProvider);
  final farm = ref.watch(currentFarmProvider);
  return BreedNotifier(repository, farm?.id);
});
