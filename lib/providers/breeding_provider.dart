/// Breeding Record Provider
/// 
/// Riverpod providers for breeding record state management.
/// Includes auto-reminder creation and offspring generation.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/breeding_record.dart';
import '../models/offspring.dart';
import '../repositories/breeding_repository.dart';
import '../repositories/offspring_repository.dart';
import '../repositories/reminder_repository.dart';
import '../repositories/livestock_repository.dart';
import '../providers/farm_provider.dart';

/// Repository provider
final breedingRepositoryProvider = Provider<BreedingRecordRepository>((ref) {
  return BreedingRecordRepository();
});

/// Provider for all breeding records of current farm
final breedingRecordsProvider = FutureProvider<List<BreedingRecord>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  final repository = ref.watch(breedingRepositoryProvider);
  return repository.getByFarm(farm.id);
});

/// Provider for active breeding records (mated, pregnant)
final activeBreedingsProvider = FutureProvider<List<BreedingRecord>>((ref) async {
  final records = await ref.watch(breedingRecordsProvider.future);
  return records.where((r) => 
    r.status == BreedingStatus.mated || 
    r.status == BreedingStatus.palpated ||
    r.status == BreedingStatus.pregnant
  ).toList();
});

/// Provider for breeding records by dam
final breedingsByDamProvider = FutureProvider.family<List<BreedingRecord>, String>((ref, damId) async {
  final repository = ref.watch(breedingRepositoryProvider);
  return repository.getByDam(damId);
});

/// Notifier for breeding record CRUD operations
class BreedingNotifier extends StateNotifier<AsyncValue<List<BreedingRecord>>> {
  final BreedingRecordRepository _repository;
  final ReminderRepository _reminderRepo;
  final OffspringRepository _offspringRepo;
  final LivestockRepository _livestockRepo;
  final String? _farmId;

  BreedingNotifier(
    this._repository, 
    this._reminderRepo,
    this._offspringRepo,
    this._livestockRepo,
    this._farmId,
  ) : super(const AsyncValue.loading()) {
    if (_farmId != null) loadBreedings();
  }

  Future<void> loadBreedings() async {
    if (_farmId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    try {
      final breedings = await _repository.getByFarm(_farmId);
      state = AsyncValue.data(breedings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Create breeding with auto-reminders
  Future<BreedingRecord> create({
    required String damId,
    required DateTime matingDate,
    String? sireId,
    DateTime? expectedBirthDate,
    String? notes,
  }) async {
    if (_farmId == null) throw Exception('No farm selected');
    
    final breeding = await _repository.create(
      farmId: _farmId,
      damId: damId,
      matingDate: matingDate,
      sireId: sireId,
      expectedBirthDate: expectedBirthDate,
      notes: notes,
    );

    // Auto-create reminders
    try {
      await _reminderRepo.createBreedingReminders(
        farmId: _farmId,
        breedingRecordId: breeding.id,
        damName: breeding.damCode ?? 'Induk',
        matingDate: matingDate,
        expectedBirthDate: expectedBirthDate,
      );
    } catch (_) {
      // Ignore reminder errors
    }
    
    await loadBreedings();
    return breeding;
  }

  Future<void> updatePalpation({
    required String id,
    required DateTime palpationDate,
    required bool isPositive,
    DateTime? expectedBirthDate,
  }) async {
    await _repository.updatePalpation(
      id: id,
      palpationDate: palpationDate,
      isPositive: isPositive,
      expectedBirthDate: expectedBirthDate,
    );
    await loadBreedings();
  }

  /// Update birth and auto-create offspring
  Future<void> updateBirth({
    required String id,
    required DateTime actualBirthDate,
    required int birthCount,
    required int aliveCount,
    int? deadCount,
  }) async {
    // Get breeding record first
    final breeding = await _repository.getById(id);
    if (breeding == null || _farmId == null) return;

    // Update breeding record
    await _repository.updateBirth(
      id: id,
      actualBirthDate: actualBirthDate,
      birthCount: birthCount,
      aliveCount: aliveCount,
      deadCount: deadCount,
    );

    // Auto-create offspring for alive count
    if (aliveCount > 0) {
      try {
        // Get dam and sire info
        final dam = await _livestockRepo.getById(breeding.damId);
        final sire = breeding.sireId != null 
            ? await _livestockRepo.getById(breeding.sireId!)
            : null;
        
        final damBreedCode = dam?.breedName ?? 'UNK'; // Use breed name as fallback
        final sireSeq = sire?.sequenceNumber ?? '00';
        final damSeq = dam?.sequenceNumber ?? '00';
        final dateStr = _formatDateCode(actualBirthDate);

        // Create offspring records
        for (int i = 1; i <= aliveCount; i++) {
          final code = '$damBreedCode-J$sireSeq.B$damSeq-$dateStr-${i.toString().padLeft(2, '0')}';
          
          await _offspringRepo.create(
            farmId: _farmId,
            breedingRecordId: id,
            code: code,
            birthDate: actualBirthDate,
            status: OffspringStatus.infarm,
          );
        }

        // Create weaning reminder (birth + 35 days)
        await _reminderRepo.create(
          farmId: _farmId,
          type: ReminderType.weaning,
          title: 'Sapih anak ${breeding.damCode ?? "Induk"}',
          description: '$aliveCount ekor siap disapih',
          dueDate: actualBirthDate.add(const Duration(days: 35)),
          referenceId: id,
          referenceType: 'breeding_record',
        );
      } catch (_) {
        // Ignore offspring creation errors
      }
    }
    
    await loadBreedings();
  }

  String _formatDateCode(DateTime date) {
    final yy = (date.year % 100).toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yy$mm$dd';
  }

  Future<void> updateWeaning({
    required String id,
    required DateTime weaningDate,
    required int weanedCount,
  }) async {
    await _repository.updateWeaning(
      id: id,
      weaningDate: weaningDate,
      weanedCount: weanedCount,
    );
    await loadBreedings();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await loadBreedings();
  }
}

/// Provider for BreedingNotifier
final breedingNotifierProvider = StateNotifierProvider<BreedingNotifier, AsyncValue<List<BreedingRecord>>>((ref) {
  final repository = ref.watch(breedingRepositoryProvider);
  final reminderRepo = ReminderRepository();
  final offspringRepo = OffspringRepository();
  final livestockRepo = LivestockRepository();
  final farm = ref.watch(currentFarmProvider);
  return BreedingNotifier(repository, reminderRepo, offspringRepo, livestockRepo, farm?.id);
});
