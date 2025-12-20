/// Livestock Repository
/// 
/// Handles all database operations for Livestock entity.

library;

import '../core/services/supabase_service.dart';
import '../models/livestock.dart';

class LivestockRepository {
  static const String _tableName = 'livestocks';

  /// Get all livestock for a farm
  Future<List<Livestock>> getByFarm(String farmId) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select('''
          *,
          housings:housing_id(code),
          breeds:breed_id(name)
        ''')
        .eq('farm_id', farmId)
        .eq('status', 'active')
        .order('code');

    return (response as List)
        .map((json) => Livestock.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get livestock by gender
  Future<List<Livestock>> getByGender(String farmId, Gender gender) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select('''
          *,
          housings:housing_id(code),
          breeds:breed_id(name)
        ''')
        .eq('farm_id', farmId)
        .eq('gender', gender.value)
        .eq('status', 'active')
        .order('code');

    return (response as List)
        .map((json) => Livestock.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get female livestock (for breeding)
  Future<List<Livestock>> getFemales(String farmId) async {
    return getByGender(farmId, Gender.female);
  }

  /// Get male livestock (for breeding)
  Future<List<Livestock>> getMales(String farmId) async {
    return getByGender(farmId, Gender.male);
  }

  /// Get a single livestock by ID
  Future<Livestock?> getById(String id) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select('''
          *,
          housings:housing_id(code),
          breeds:breed_id(name)
        ''')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Livestock.fromJson(response);
  }

  /// Create a new livestock
  Future<Livestock> create({
    required String farmId,
    required String code,
    required Gender gender,
    String? housingId,
    String? name,
    String? breedId,
    DateTime? birthDate,
    DateTime? acquisitionDate,
    AcquisitionType acquisitionType = AcquisitionType.purchased,
    double? purchasePrice,
    int generation = 1,
    double? weight,
    String? notes,
  }) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .insert({
          'farm_id': farmId,
          'housing_id': housingId,
          'code': code,
          'name': name,
          'gender': gender.value,
          'breed_id': breedId,
          'birth_date': birthDate?.toIso8601String().split('T').first,
          'acquisition_date': acquisitionDate?.toIso8601String().split('T').first,
          'acquisition_type': acquisitionType.value,
          'purchase_price': purchasePrice,
          'status': 'active',
          'generation': generation,
          'weight': weight,
          'notes': notes,
        })
        .select('''
          *,
          housings:housing_id(code),
          breeds:breed_id(name)
        ''')
        .single();

    return Livestock.fromJson(response);
  }

  /// Update an existing livestock
  Future<Livestock> update(Livestock livestock) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .update({
          'housing_id': livestock.housingId,
          'code': livestock.code,
          'name': livestock.name,
          'gender': livestock.gender.value,
          'breed_id': livestock.breedId,
          'birth_date': livestock.birthDate?.toIso8601String().split('T').first,
          'acquisition_date': livestock.acquisitionDate?.toIso8601String().split('T').first,
          'acquisition_type': livestock.acquisitionType.value,
          'purchase_price': livestock.purchasePrice,
          'status': livestock.status.value,
          'generation': livestock.generation,
          'weight': livestock.weight,
          'notes': livestock.notes,
          'metadata': livestock.metadata,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', livestock.id)
        .select('''
          *,
          housings:housing_id(code),
          breeds:breed_id(name)
        ''')
        .single();

    return Livestock.fromJson(response);
  }

  /// Update livestock status
  Future<void> updateStatus(String id, LivestockStatus status) async {
    await SupabaseService.client
        .from(_tableName)
        .update({
          'status': status.value,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Delete a livestock
  Future<void> delete(String id) async {
    await SupabaseService.client
        .from(_tableName)
        .delete()
        .eq('id', id);
  }

  /// Get livestock count for a farm
  Future<int> getCount(String farmId) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select('id')
        .eq('farm_id', farmId)
        .eq('status', 'active');

    return (response as List).length;
  }

  /// Get livestock count by gender
  Future<Map<Gender, int>> getCountByGender(String farmId) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select('gender')
        .eq('farm_id', farmId)
        .eq('status', 'active');

    final list = response as List;
    return {
      Gender.male: list.where((e) => e['gender'] == 'male').length,
      Gender.female: list.where((e) => e['gender'] == 'female').length,
    };
  }

  /// Generate next code for livestock
  /// Format: [BREED_CODE]-[J/B][SEQUENCE]
  /// Example: REX-J01, NZW-B04
  Future<String> getNextCode({
    required String farmId,
    required String breedCode,
    required Gender gender,
  }) async {
    final genderPrefix = gender == Gender.male ? 'J' : 'B';
    final pattern = '$breedCode-$genderPrefix%';

    // Get existing codes with this pattern
    final response = await SupabaseService.client
        .from(_tableName)
        .select('code')
        .eq('farm_id', farmId)
        .ilike('code', pattern);

    final codes = (response as List).map((e) => e['code'] as String).toList();

    // Find max sequence number
    int maxSeq = 0;
    for (final code in codes) {
      final parts = code.split('-');
      if (parts.length >= 2) {
        final seqStr = parts.last.replaceAll(RegExp(r'[^0-9]'), '');
        final seq = int.tryParse(seqStr) ?? 0;
        if (seq > maxSeq) maxSeq = seq;
      }
    }

    // Generate next code with 2+ digits
    final nextSeq = maxSeq + 1;
    final seqStr = nextSeq.toString().padLeft(2, '0');
    return '$breedCode-$genderPrefix$seqStr';
  }
}

