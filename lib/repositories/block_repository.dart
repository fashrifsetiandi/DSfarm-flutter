/// Block Repository
/// 
/// Handles database operations for blocks.

library;

import '../core/services/supabase_service.dart';
import '../models/block.dart';

class BlockRepository {
  static const String _tableName = 'blocks';

  /// Get all blocks for a farm
  Future<List<Block>> getByFarm(String farmId) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('farm_id', farmId)
        .order('code');

    return (response as List)
        .map((json) => Block.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get block by ID
  Future<Block?> getById(String id) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Block.fromJson(response);
  }

  /// Create a new block
  Future<Block> create({
    required String farmId,
    required String code,
    String? name,
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

    return Block.fromJson(response);
  }

  /// Update a block
  Future<Block> update({
    required String id,
    String? code,
    String? name,
    String? description,
  }) async {
    final updates = <String, dynamic>{};
    if (code != null) updates['code'] = code.toUpperCase();
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;

    final response = await SupabaseService.client
        .from(_tableName)
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Block.fromJson(response);
  }

  /// Delete block
  Future<void> delete(String id) async {
    await SupabaseService.client
        .from(_tableName)
        .delete()
        .eq('id', id);
  }

  /// Get next position for a block
  Future<String> getNextPosition(String blockId, String blockCode) async {
    final response = await SupabaseService.client
        .from('housings')
        .select('position')
        .eq('block_id', blockId)
        .order('position');

    final positions = (response as List)
        .map((e) => e['position'] as String?)
        .where((p) => p != null)
        .toList();

    // Find max number
    int maxNum = 0;
    for (final pos in positions) {
      final match = RegExp(r'(\d+)$').firstMatch(pos!);
      if (match != null) {
        final num = int.tryParse(match.group(1)!) ?? 0;
        if (num > maxNum) maxNum = num;
      }
    }

    final nextNum = (maxNum + 1).toString().padLeft(2, '0');
    return '$blockCode-$nextNum';
  }
}
