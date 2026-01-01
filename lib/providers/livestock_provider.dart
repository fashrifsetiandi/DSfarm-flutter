/// Livestock Provider
/// 
/// Riverpod providers for livestock state management.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/livestock.dart';
import '../repositories/livestock_repository.dart';
import '../providers/farm_provider.dart';

/// Repository provider
final livestockRepositoryProvider = Provider<LivestockRepository>((ref) {
  return LivestockRepository();
});

/// Provider for all livestock of current farm
final livestocksProvider = FutureProvider<List<Livestock>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  final repository = ref.watch(livestockRepositoryProvider);
  return repository.getByFarm(farm.id);
});

/// Provider for female livestock
final femaleLivestocksProvider = FutureProvider<List<Livestock>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  final repository = ref.watch(livestockRepositoryProvider);
  return repository.getFemales(farm.id);
});

/// Provider for male livestock
final maleLivestocksProvider = FutureProvider<List<Livestock>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  final repository = ref.watch(livestockRepositoryProvider);
  return repository.getMales(farm.id);
});

/// Provider for livestock count by gender
final livestockCountProvider = FutureProvider<Map<Gender, int>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return {Gender.male: 0, Gender.female: 0};
  
  final repository = ref.watch(livestockRepositoryProvider);
  return repository.getCountByGender(farm.id);
});

/// Provider for full livestock statistics (total, infarm, keluar)
final livestockStatsProvider = FutureProvider<LivestockStats>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return LivestockStats.empty;
  
  final repository = ref.watch(livestockRepositoryProvider);
  return repository.getFullStats(farm.id);
});

/// Notifier for livestock CRUD operations
class LivestockNotifier extends StateNotifier<AsyncValue<List<Livestock>>> {
  final LivestockRepository _repository;
  final String? _farmId;

  LivestockNotifier(this._repository, this._farmId) 
      : super(_farmId == null ? const AsyncValue.data([]) : const AsyncValue.loading()) {
    if (_farmId != null) loadLivestocks();
  }

  Future<void> loadLivestocks() async {
    if (_farmId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    try {
      final livestocks = await _repository.getByFarm(_farmId);
      state = AsyncValue.data(livestocks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Livestock> create({
    required String code,
    required Gender gender,
    String? housingId,
    String? name,
    String? breedId,
    DateTime? birthDate,
    DateTime? acquisitionDate,
    AcquisitionType acquisitionType = AcquisitionType.purchased,
    double? purchasePrice,
    String? status,
    int generation = 1,
    double? weight,
    String? notes,
    String? motherId,
    String? fatherId,
  }) async {
    if (_farmId == null) throw Exception('No farm selected');
    
    final livestock = await _repository.create(
      farmId: _farmId,
      code: code,
      gender: gender,
      housingId: housingId,
      name: name,
      breedId: breedId,
      birthDate: birthDate,
      acquisitionDate: acquisitionDate,
      acquisitionType: acquisitionType,
      purchasePrice: purchasePrice,
      status: status ?? (gender == Gender.female ? 'betina_muda' : 'pejantan_muda'),
      generation: generation,
      weight: weight,
      notes: notes,
      motherId: motherId,
      fatherId: fatherId,
    );
    
    await loadLivestocks();
    return livestock;
  }

  Future<void> update(Livestock livestock) async {
    await _repository.update(livestock);
    await loadLivestocks();
  }

  Future<void> updateStatus(String id, String status) async {
    await _repository.updateStatus(id, status);
    await loadLivestocks();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await loadLivestocks();
  }
}

/// Provider for LivestockNotifier
final livestockNotifierProvider = StateNotifierProvider<LivestockNotifier, AsyncValue<List<Livestock>>>((ref) {
  final repository = ref.watch(livestockRepositoryProvider);
  final farm = ref.watch(currentFarmProvider);
  return LivestockNotifier(repository, farm?.id);
});

/// Provider for generating next livestock code
final nextLivestockCodeProvider = FutureProvider.family<String, ({String breedCode, Gender gender})>((ref, params) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return '${params.breedCode}-${params.gender == Gender.male ? 'J' : 'B'}01';
  
  final repository = ref.watch(livestockRepositoryProvider);
  return repository.getNextCode(
    farmId: farm.id,
    breedCode: params.breedCode,
    gender: params.gender,
  );
});

