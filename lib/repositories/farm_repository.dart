/// Farm Repository
/// 
/// Handles all database operations for Farm entity.
/// Uses Supabase as the backend.

library;

import '../core/services/supabase_service.dart';
import '../models/farm.dart';

class FarmRepository {
  static const String _tableName = 'farms';

  /// Get all farms for current user
  Future<List<Farm>> getAllFarms() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Farm.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a single farm by ID
  Future<Farm?> getFarmById(String id) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Farm.fromJson(response);
  }

  /// Create a new farm
  Future<Farm> createFarm({
    required String name,
    required String animalType,
    String? location,
    String? description,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await SupabaseService.client
        .from(_tableName)
        .insert({
          'user_id': userId,
          'name': name,
          'animal_type': animalType,
          'location': location,
          'description': description,
          'is_active': true,
        })
        .select()
        .single();

    return Farm.fromJson(response);
  }

  /// Update an existing farm
  Future<Farm> updateFarm(Farm farm) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .update({
          'name': farm.name,
          'animal_type': farm.animalType,
          'location': farm.location,
          'description': farm.description,
          'is_active': farm.isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', farm.id)
        .select()
        .single();

    return Farm.fromJson(response);
  }

  /// Soft delete a farm (set is_active to false)
  Future<void> deleteFarm(String id) async {
    await SupabaseService.client
        .from(_tableName)
        .update({'is_active': false})
        .eq('id', id);
  }

  /// Get farm count for current user
  Future<int> getFarmCount() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return 0;

    final response = await SupabaseService.client
        .from(_tableName)
        .select('id')
        .eq('user_id', userId)
        .eq('is_active', true);

    return (response as List).length;
  }
}
