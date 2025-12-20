/// Reminder Repository
/// 
/// Handles database operations for reminders.

library;

import '../core/services/supabase_service.dart';
import '../models/reminder.dart';

class ReminderRepository {
  static const String _tableName = 'reminders';

  /// Get all reminders for a farm
  Future<List<Reminder>> getByFarm(String farmId) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('farm_id', farmId)
        .order('due_date');

    return (response as List)
        .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get pending reminders (not completed)
  Future<List<Reminder>> getPending(String farmId) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('farm_id', farmId)
        .eq('is_completed', false)
        .order('due_date');

    return (response as List)
        .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get overdue reminders
  Future<List<Reminder>> getOverdue(String farmId) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('farm_id', farmId)
        .eq('is_completed', false)
        .lt('due_date', today)
        .order('due_date');

    return (response as List)
        .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new reminder
  Future<Reminder> create({
    required String farmId,
    required ReminderType type,
    required String title,
    String? description,
    required DateTime dueDate,
    String? referenceId,
    String? referenceType,
  }) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .insert({
          'farm_id': farmId,
          'type': type.value,
          'title': title,
          'description': description,
          'due_date': dueDate.toIso8601String().split('T').first,
          'reference_id': referenceId,
          'reference_type': referenceType,
          'is_completed': false,
        })
        .select()
        .single();

    return Reminder.fromJson(response);
  }

  /// Mark reminder as completed
  Future<void> markCompleted(String id) async {
    await SupabaseService.client
        .from(_tableName)
        .update({
          'is_completed': true,
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Delete reminder
  Future<void> delete(String id) async {
    await SupabaseService.client
        .from(_tableName)
        .delete()
        .eq('id', id);
  }

  /// Create breeding-related reminders automatically
  Future<void> createBreedingReminders({
    required String farmId,
    required String breedingRecordId,
    required String damName,
    required DateTime matingDate,
    required DateTime? expectedBirthDate,
    int palpationDays = 12,
    int weaningDays = 35,
  }) async {
    // Palpation reminder (12 days after mating for rabbits)
    await create(
      farmId: farmId,
      type: ReminderType.palpation,
      title: 'Palpasi $damName',
      description: 'Cek kebuntingan $damName',
      dueDate: matingDate.add(Duration(days: palpationDays)),
      referenceId: breedingRecordId,
      referenceType: 'breeding_record',
    );

    // Expected birth reminder
    if (expectedBirthDate != null) {
      await create(
        farmId: farmId,
        type: ReminderType.expectedBirth,
        title: 'Perkiraan lahir $damName',
        description: 'Siapkan kandang kelahiran',
        dueDate: expectedBirthDate.subtract(const Duration(days: 2)),
        referenceId: breedingRecordId,
        referenceType: 'breeding_record',
      );
    }
  }
}
