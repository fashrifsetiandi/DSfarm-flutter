/// Block Provider
/// 
/// Riverpod providers for block state management.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/block.dart';
import '../repositories/block_repository.dart';
import '../providers/farm_provider.dart';

/// Repository provider
final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  return BlockRepository();
});

/// Provider for all blocks of current farm
final blocksProvider = FutureProvider<List<Block>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  final repository = ref.watch(blockRepositoryProvider);
  return repository.getByFarm(farm.id);
});

/// Notifier for block CRUD
class BlockNotifier extends StateNotifier<AsyncValue<List<Block>>> {
  final BlockRepository _repository;
  final String? _farmId;

  BlockNotifier(this._repository, this._farmId) : super(const AsyncValue.loading()) {
    if (_farmId != null) loadBlocks();
  }

  Future<void> loadBlocks() async {
    if (_farmId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    try {
      final blocks = await _repository.getByFarm(_farmId);
      state = AsyncValue.data(blocks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Block> create({
    required String code,
    String? name,
    String? description,
  }) async {
    if (_farmId == null) throw Exception('No farm selected');
    
    final block = await _repository.create(
      farmId: _farmId,
      code: code,
      name: name,
      description: description,
    );
    
    await loadBlocks();
    return block;
  }

  Future<Block> update({
    required String id,
    String? code,
    String? name,
    String? description,
  }) async {
    final block = await _repository.update(
      id: id,
      code: code,
      name: name,
      description: description,
    );
    
    await loadBlocks();
    return block;
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await loadBlocks();
  }
}

/// Provider for BlockNotifier
final blockNotifierProvider = StateNotifierProvider<BlockNotifier, AsyncValue<List<Block>>>((ref) {
  final repository = ref.watch(blockRepositoryProvider);
  final farm = ref.watch(currentFarmProvider);
  return BlockNotifier(repository, farm?.id);
});

/// Provider for next position in a block
final nextPositionProvider = FutureProvider.family<String, ({String blockId, String blockCode})>((ref, params) async {
  final repository = ref.watch(blockRepositoryProvider);
  return repository.getNextPosition(params.blockId, params.blockCode);
});
