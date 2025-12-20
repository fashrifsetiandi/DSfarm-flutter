/// Health Record Provider
/// 
/// Riverpod providers for health record state management.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_record.dart';
import '../repositories/health_repository.dart';
import '../providers/farm_provider.dart';

/// Repository provider
final healthRepositoryProvider = Provider<HealthRecordRepository>((ref) {
  return HealthRecordRepository();
});

/// Provider for all health records of current farm
final healthRecordsProvider = FutureProvider<List<HealthRecord>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  final repository = ref.watch(healthRepositoryProvider);
  return repository.getByFarm(farm.id);
});

/// Provider for health records by livestock
final healthByLivestockProvider = FutureProvider.family<List<HealthRecord>, String>((ref, livestockId) async {
  final repository = ref.watch(healthRepositoryProvider);
  return repository.getByLivestock(livestockId);
});

/// Notifier for health record CRUD
class HealthNotifier extends StateNotifier<AsyncValue<List<HealthRecord>>> {
  final HealthRecordRepository _repository;
  final String? _farmId;

  HealthNotifier(this._repository, this._farmId) : super(const AsyncValue.loading()) {
    if (_farmId != null) loadRecords();
  }

  Future<void> loadRecords() async {
    if (_farmId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    try {
      final records = await _repository.getByFarm(_farmId);
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<HealthRecord> create({
    String? livestockId,
    String? offspringId,
    required HealthRecordType type,
    required String title,
    required DateTime recordDate,
    String? medicine,
    String? dosage,
    double? cost,
    String? notes,
    DateTime? nextDueDate,
  }) async {
    if (_farmId == null) throw Exception('No farm selected');
    
    final record = await _repository.create(
      farmId: _farmId,
      livestockId: livestockId,
      offspringId: offspringId,
      type: type,
      title: title,
      recordDate: recordDate,
      medicine: medicine,
      dosage: dosage,
      cost: cost,
      notes: notes,
      nextDueDate: nextDueDate,
    );
    
    await loadRecords();
    return record;
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await loadRecords();
  }
}

/// Provider for HealthNotifier
final healthNotifierProvider = StateNotifierProvider<HealthNotifier, AsyncValue<List<HealthRecord>>>((ref) {
  final repository = ref.watch(healthRepositoryProvider);
  final farm = ref.watch(currentFarmProvider);
  return HealthNotifier(repository, farm?.id);
});
