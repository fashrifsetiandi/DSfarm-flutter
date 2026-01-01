
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/livestock_status_model.dart';
import '../repositories/status_repository.dart';

// Repository Provider
final statusRepositoryProvider = Provider<StatusRepository>((ref) {
  return StatusRepository(Supabase.instance.client);
});

// State Notifier
final statusNotifierProvider = StateNotifierProvider.family<StatusNotifier, AsyncValue<List<LivestockStatusModel>>, String>((ref, farmId) {
  return StatusNotifier(ref.watch(statusRepositoryProvider), farmId);
});

class StatusNotifier extends StateNotifier<AsyncValue<List<LivestockStatusModel>>> {
  final StatusRepository _repository;
  final String _farmId;

  StatusNotifier(this._repository, this._farmId) : super(const AsyncValue.loading()) {
    loadStatuses();
  }

  Future<void> loadStatuses() async {
    try {
      state = const AsyncValue.loading();
      final statuses = await _repository.getStatuses(_farmId);
      
      if (statuses.isEmpty) {
        // Fallback or seed logic could go here
        // For now, return defaults locally to ensure UI works even if DB is empty
        state = AsyncValue.data(_repository.getDefaults());
      } else {
        state = AsyncValue.data(statuses);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  List<LivestockStatusModel> getByGender(String gender) { // 'male', 'female'
    return state.value?.where((s) => s.validForGender == 'both' || s.validForGender == gender).toList() ?? [];
  }

  Future<void> create(LivestockStatusModel status) async {
    try {
      await _repository.createStatus(_farmId, status);
      await loadStatuses();
    } catch (e) {
      // Revert or show error
      rethrow;
    }
  }

  Future<void> update(LivestockStatusModel status) async {
    try {
      await _repository.updateStatus(status);
      await loadStatuses();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repository.deleteStatus(id);
      await loadStatuses();
    } catch (e) {
      rethrow;
    }
  }
}
