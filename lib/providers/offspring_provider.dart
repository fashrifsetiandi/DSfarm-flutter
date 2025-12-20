/// Offspring Provider
/// 
/// Riverpod providers for offspring state management.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/offspring.dart';
import '../repositories/offspring_repository.dart';
import '../providers/farm_provider.dart';

/// Repository provider
final offspringRepositoryProvider = Provider<OffspringRepository>((ref) {
  return OffspringRepository();
});

/// Provider for all offspring of current farm
final offspringsProvider = FutureProvider<List<Offspring>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  final repository = ref.watch(offspringRepositoryProvider);
  return repository.getByFarm(farm.id);
});

/// Provider for offspring by status
final offspringsByStatusProvider = FutureProvider.family<List<Offspring>, OffspringStatus>((ref, status) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  final repository = ref.watch(offspringRepositoryProvider);
  return repository.getByStatus(farm.id, status);
});

/// Provider for offspring count by status
final offspringCountProvider = FutureProvider<Map<OffspringStatus, int>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return {};
  
  final repository = ref.watch(offspringRepositoryProvider);
  return repository.getCountByStatus(farm.id);
});

/// Notifier for offspring CRUD operations
class OffspringNotifier extends StateNotifier<AsyncValue<List<Offspring>>> {
  final OffspringRepository _repository;
  final String? _farmId;

  OffspringNotifier(this._repository, this._farmId) 
      : super(_farmId == null ? const AsyncValue.data([]) : const AsyncValue.loading()) {
    if (_farmId != null) loadOffsprings();
  }

  Future<void> loadOffsprings() async {
    if (_farmId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    try {
      final offsprings = await _repository.getByFarm(_farmId);
      state = AsyncValue.data(offsprings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Offspring> create({
    required String code,
    required Gender gender,
    required DateTime birthDate,
    String? breedingRecordId,
    String? housingId,
    String? name,
    String? breedId,
    double? weight,
    String? notes,
  }) async {
    if (_farmId == null) throw Exception('No farm selected');
    
    final offspring = await _repository.create(
      farmId: _farmId,
      code: code,
      gender: gender,
      birthDate: birthDate,
      breedingRecordId: breedingRecordId,
      housingId: housingId,
      name: name,
      breedId: breedId,
      weight: weight,
      notes: notes,
    );
    
    await loadOffsprings();
    return offspring;
  }

  Future<void> update(Offspring offspring) async {
    await _repository.update(offspring);
    await loadOffsprings();
  }

  Future<void> updateStatus(String id, OffspringStatus status, {
    double? salePrice,
    DateTime? saleDate,
  }) async {
    await _repository.updateStatus(id, status, salePrice: salePrice, saleDate: saleDate);
    await loadOffsprings();
  }

  Future<void> markAsWeaned(String id) async {
    await _repository.markAsWeaned(id, DateTime.now());
    await loadOffsprings();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await loadOffsprings();
  }
}

/// Provider for OffspringNotifier
final offspringNotifierProvider = StateNotifierProvider<OffspringNotifier, AsyncValue<List<Offspring>>>((ref) {
  final repository = ref.watch(offspringRepositoryProvider);
  final farm = ref.watch(currentFarmProvider);
  return OffspringNotifier(repository, farm?.id);
});
