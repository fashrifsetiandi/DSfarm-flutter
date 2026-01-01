
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/livestock_status_model.dart';

class StatusRepository {
  final SupabaseClient _supabase;

  StatusRepository(this._supabase);

  Future<List<LivestockStatusModel>> getStatuses(String farmId) async {
    try {
      final response = await _supabase
          .from('livestock_status')
          .select()
          .eq('farm_id', farmId)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => LivestockStatusModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load statuses: $e');
    }
  }

  Future<LivestockStatusModel> createStatus(String farmId, LivestockStatusModel status) async {
    final response = await _supabase
        .from('livestock_status')
        .insert({
          'farm_id': farmId,
          'code': status.code,
          'name': status.name,
          'color': status.colorHex,
          'type': status.type,
          'valid_for_gender': status.validForGender,
          'sort_order': status.sortOrder,
        })
        .select()
        .single();
    return LivestockStatusModel.fromJson(response);
  }

  Future<LivestockStatusModel> updateStatus(LivestockStatusModel status) async {
    final response = await _supabase
        .from('livestock_status')
        .update({
          'code': status.code,
          'name': status.name,
          'color': status.colorHex,
          'type': status.type,
          'valid_for_gender': status.validForGender,
          'sort_order': status.sortOrder,
        })
        .eq('id', status.id)
        .select()
        .single();
    return LivestockStatusModel.fromJson(response);
  }

  Future<void> deleteStatus(String id) async {
    await _supabase.from('livestock_status').delete().eq('id', id);
  }

  // Fallback for initial load if DB is empty or during migration
  List<LivestockStatusModel> getDefaults() {
    return [
      const LivestockStatusModel(id: '1', code: 'betina_muda', name: 'Betina Muda', colorHex: '#4CAF50', type: 'active', validForGender: 'female'),
      const LivestockStatusModel(id: '2', code: 'siap_kawin', name: 'Siap Kawin', colorHex: '#9C27B0', type: 'active', validForGender: 'female'),
      const LivestockStatusModel(id: '3', code: 'bunting', name: 'Bunting', colorHex: '#E91E63', type: 'active', validForGender: 'female'),
      const LivestockStatusModel(id: '4', code: 'menyusui', name: 'Menyusui', colorHex: '#E91E63', type: 'active', validForGender: 'female'),
      const LivestockStatusModel(id: '5', code: 'pejantan_muda', name: 'Pejantan Muda', colorHex: '#4CAF50', type: 'active', validForGender: 'male'),
      const LivestockStatusModel(id: '6', code: 'pejantan_aktif', name: 'Pejantan Aktif', colorHex: '#2196F3', type: 'active', validForGender: 'male'),
      const LivestockStatusModel(id: '7', code: 'istirahat', name: 'Istirahat', colorHex: '#9E9E9E', type: 'active', validForGender: 'both'),
      const LivestockStatusModel(id: '9', code: 'deceased', name: 'Mati', colorHex: '#F44336', type: 'deceased', validForGender: 'both'),
    ];
  }
}
