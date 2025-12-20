/// Reminder Provider
/// 
/// Riverpod providers for reminder state management.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reminder.dart';
import '../repositories/reminder_repository.dart';
import '../providers/farm_provider.dart';

/// Repository provider
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository();
});

/// Provider for all reminders of current farm
final remindersProvider = FutureProvider<List<Reminder>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  final repository = ref.watch(reminderRepositoryProvider);
  return repository.getByFarm(farm.id);
});

/// Provider for pending reminders
final pendingRemindersProvider = FutureProvider<List<Reminder>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  final repository = ref.watch(reminderRepositoryProvider);
  return repository.getPending(farm.id);
});

/// Provider for overdue reminders
final overdueRemindersProvider = FutureProvider<List<Reminder>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  final repository = ref.watch(reminderRepositoryProvider);
  return repository.getOverdue(farm.id);
});

/// Notifier for reminder CRUD
class ReminderNotifier extends StateNotifier<AsyncValue<List<Reminder>>> {
  final ReminderRepository _repository;
  final String? _farmId;

  ReminderNotifier(this._repository, this._farmId) : super(const AsyncValue.loading()) {
    if (_farmId != null) loadReminders();
  }

  Future<void> loadReminders() async {
    if (_farmId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    try {
      final reminders = await _repository.getPending(_farmId);
      state = AsyncValue.data(reminders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Reminder> create({
    required ReminderType type,
    required String title,
    String? description,
    required DateTime dueDate,
    String? referenceId,
    String? referenceType,
  }) async {
    if (_farmId == null) throw Exception('No farm selected');
    
    final reminder = await _repository.create(
      farmId: _farmId,
      type: type,
      title: title,
      description: description,
      dueDate: dueDate,
      referenceId: referenceId,
      referenceType: referenceType,
    );
    
    await loadReminders();
    return reminder;
  }

  Future<void> markCompleted(String id) async {
    await _repository.markCompleted(id);
    await loadReminders();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await loadReminders();
  }

  /// Create breeding reminders (palpation, expected birth)
  Future<void> createBreedingReminders({
    required String breedingRecordId,
    required String damName,
    required DateTime matingDate,
    DateTime? expectedBirthDate,
  }) async {
    if (_farmId == null) throw Exception('No farm selected');
    
    await _repository.createBreedingReminders(
      farmId: _farmId,
      breedingRecordId: breedingRecordId,
      damName: damName,
      matingDate: matingDate,
      expectedBirthDate: expectedBirthDate,
    );
    
    await loadReminders();
  }
}

/// Provider for ReminderNotifier
final reminderNotifierProvider = StateNotifierProvider<ReminderNotifier, AsyncValue<List<Reminder>>>((ref) {
  final repository = ref.watch(reminderRepositoryProvider);
  final farm = ref.watch(currentFarmProvider);
  return ReminderNotifier(repository, farm?.id);
});
