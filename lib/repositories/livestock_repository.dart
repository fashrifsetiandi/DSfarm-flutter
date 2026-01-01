/// Livestock Repository
/// 
/// Handles all database operations for Livestock entity.

library;

import '../core/services/supabase_service.dart';
import '../models/livestock.dart';

class LivestockRepository {
  static const String _tableName = 'livestocks';

  /// Get all livestock for a farm (excluding sold/deceased/culled)
  Future<List<Livestock>> getByFarm(String farmId) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select('''
          *,
          housings:housing_id(code),
          breeds:breed_id(name),
          mother:mother_id(code),
          father:father_id(code)
        ''')
        .eq('farm_id', farmId)
        .order('code');

    return (response as List)
        .map((json) => Livestock.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get livestock by gender (excluding sold/deceased/culled)
  Future<List<Livestock>> getByGender(String farmId, Gender gender) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select('''
          *,
          housings:housing_id(code),
          breeds:breed_id(name),
          mother:mother_id(code),
          father:father_id(code)
        ''')
        .eq('farm_id', farmId)
        .eq('gender', gender.value)
        .not('status', 'in', '(sold,deceased,culled)')
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
          breeds:breed_id(name),
          mother:mother_id(code),
          father:father_id(code)
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
    String? status,
    int generation = 1,
    double? weight,
    String? notes,
    String? motherId,
    String? fatherId,
  }) async {
    // Default statuses based on legacy enum logic
    final defaultStatus = gender == Gender.female ? 'betina_muda' : 'pejantan_muda';
    final effectiveStatus = status ?? defaultStatus;
    
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
          'status': effectiveStatus,
          'generation': generation,
          'weight': weight,
          'notes': notes,
          'mother_id': motherId,
          'father_id': fatherId,
        })
        .select('''
          *,
          housings:housing_id(code),
          breeds:breed_id(name),
          mother:mother_id(code),
          father:father_id(code)
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
          'status': livestock.status,
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
  Future<void> updateStatus(String id, String status) async {
    await SupabaseService.client
        .from(_tableName)
        .update({
          'status': status,
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

  /// Get livestock count for a farm (excluding sold/deceased/culled)
  Future<int> getCount(String farmId) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select('id')
        .eq('farm_id', farmId)
        .not('status', 'in', '(sold,deceased,culled)');

    return (response as List).length;
  }

  /// Get livestock count by gender (excluding sold/deceased/culled)
  Future<Map<Gender, int>> getCountByGender(String farmId) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select('gender')
        .eq('farm_id', farmId)
        .not('status', 'in', '(sold,deceased,culled)');

    final list = response as List;
    return {
      Gender.male: list.where((e) => e['gender'] == 'male').length,
      Gender.female: list.where((e) => e['gender'] == 'female').length,
    };
  }

  /// Get full statistics for livestock
  /// Returns: total (ever owned), infarm (active), keluar (exited)
  Future<LivestockStats> getFullStats(String farmId) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select('status, gender')
        .eq('farm_id', farmId);

    final list = response as List;
    final exitedStatuses = ['sold', 'deceased', 'culled'];
    
    final infarm = list.where((e) => !exitedStatuses.contains(e['status'])).length;
    final keluar = list.where((e) => exitedStatuses.contains(e['status'])).length;
    
    // Gender breakdown for infarm only
    final infarmList = list.where((e) => !exitedStatuses.contains(e['status']));
    final maleInfarm = infarmList.where((e) => e['gender'] == 'male').length;
    final femaleInfarm = infarmList.where((e) => e['gender'] == 'female').length;
    
    return LivestockStats(
      total: list.length,
      infarm: infarm,
      keluar: keluar,
      maleInfarm: maleInfarm,
      femaleInfarm: femaleInfarm,
    );
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

