/// Health Record Repository
/// 
/// Handles database operations for health records.

library;

import '../core/services/supabase_service.dart';
import '../models/health_record.dart';

class HealthRecordRepository {
  static const String _tableName = 'health_records';

  /// Get all health records for a farm
  Future<List<HealthRecord>> getByFarm(String farmId) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select('''
          *,
          livestocks:livestock_id(code, name),
          offsprings:offspring_id(code, name)
        ''')
        .eq('farm_id', farmId)
        .order('record_date', ascending: false);

    return (response as List)
        .map((json) => HealthRecord.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get health records for a specific livestock
  Future<List<HealthRecord>> getByLivestock(String livestockId) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('livestock_id', livestockId)
        .order('record_date', ascending: false);

    return (response as List)
        .map((json) => HealthRecord.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get health records for a specific offspring
  Future<List<HealthRecord>> getByOffspring(String offspringId) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('offspring_id', offspringId)
        .order('record_date', ascending: false);

    return (response as List)
        .map((json) => HealthRecord.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new health record
  Future<HealthRecord> create({
    required String farmId,
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
    final response = await SupabaseService.client
        .from(_tableName)
        .insert({
          'farm_id': farmId,
          'livestock_id': livestockId,
          'offspring_id': offspringId,
          'type': type.value,
          'title': title,
          'record_date': recordDate.toIso8601String().split('T').first,
          'medicine': medicine,
          'dosage': dosage,
          'cost': cost,
          'notes': notes,
          'next_due_date': nextDueDate?.toIso8601String().split('T').first,
        })
        .select()
        .single();

    return HealthRecord.fromJson(response);
  }

  /// Delete health record
  Future<void> delete(String id) async {
    await SupabaseService.client
        .from(_tableName)
        .delete()
        .eq('id', id);
  }
}
