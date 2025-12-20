/// Breed Repository
/// 
/// Handles database operations for breeds.

library;

import '../core/services/supabase_service.dart';
import '../models/breed.dart';

class BreedRepository {
  static const String _tableName = 'breeds';

  /// Get all breeds for a farm
  Future<List<Breed>> getByFarm(String farmId) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('farm_id', farmId)
        .order('code');

    return (response as List)
        .map((json) => Breed.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get breed by ID
  Future<Breed?> getById(String id) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Breed.fromJson(response);
  }

  /// Create a new breed
  Future<Breed> create({
    required String farmId,
    required String code,
    required String name,
    String? description,
  }) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .insert({
          'farm_id': farmId,
          'code': code.toUpperCase(),
          'name': name,
          'description': description,
        })
        .select()
        .single();

    return Breed.fromJson(response);
  }

  /// Delete breed
  Future<void> delete(String id) async {
    await SupabaseService.client
        .from(_tableName)
        .delete()
        .eq('id', id);
  }
}
