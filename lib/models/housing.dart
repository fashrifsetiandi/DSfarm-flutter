/// Housing Model (Kandang)
/// 
/// Represents a housing unit for livestock.
/// Can be individual cage or colony depending on animal type.

library;

class Housing {
  final String id;
  final String farmId;
  final String? blockId;   // Reference to block
  final String? blockCode; // From joined query
  final String? position;  // Position within block (e.g., "A-01")
  final String code;       // e.g., "K-001", "A-01"
  final String? name;
  final int capacity;
  final HousingType type;
  final HousingStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Computed properties (not stored in DB)
  final int? currentOccupancy;

  const Housing({
    required this.id,
    required this.farmId,
    this.blockId,
    this.blockCode,
    this.position,
    required this.code,
    this.name,
    this.capacity = 1,
    this.type = HousingType.individual,
    this.status = HousingStatus.active,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.currentOccupancy,
  });

  /// Display name (use position if has block, otherwise code)
  String get displayName => position ?? name ?? code;

  /// Check if housing has available space
  bool get hasSpace => (currentOccupancy ?? 0) < capacity;

  /// Available space count
  int get availableSpace => capacity - (currentOccupancy ?? 0);

  /// Occupancy percentage
  double get occupancyPercentage {
    if (capacity == 0) return 0;
    return ((currentOccupancy ?? 0) / capacity) * 100;
  }

  /// Create from JSON (Supabase response)
  factory Housing.fromJson(Map<String, dynamic> json) {
    return Housing(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      blockId: json['block_id'] as String?,
      blockCode: json['blocks']?['code'] as String?,
      position: json['position'] as String?,
      code: json['code'] as String,
      name: json['name'] as String?,
      capacity: json['capacity'] as int? ?? 1,
      type: HousingType.fromString(json['housing_type'] as String? ?? 'individual'),
      status: HousingStatus.fromString(json['status'] as String? ?? 'active'),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      currentOccupancy: json['current_occupancy'] as int?,
    );
  }

  /// Convert to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'farm_id': farmId,
      'block_id': blockId,
      'position': position,
      'code': code,
      'name': name,
      'capacity': capacity,
      'housing_type': type.value,
      'status': status.value,
      'notes': notes,
    };
  }

  /// Create copy with updated fields
  Housing copyWith({
    String? id,
    String? farmId,
    String? blockId,
    String? blockCode,
    String? position,
    String? code,
    String? name,
    int? capacity,
    HousingType? type,
    HousingStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? currentOccupancy,
  }) {
    return Housing(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      blockId: blockId ?? this.blockId,
      blockCode: blockCode ?? this.blockCode,
      position: position ?? this.position,
      code: code ?? this.code,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      type: type ?? this.type,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentOccupancy: currentOccupancy ?? this.currentOccupancy,
    );
  }

  @override
  String toString() => 'Housing(id: $id, code: $code, capacity: $capacity)';
}

/// Housing type enum
enum HousingType {
  individual('individual', 'Individual'),
  colony('colony', 'Koloni'),
  pond('pond', 'Kolam');

  final String value;
  final String displayName;

  const HousingType(this.value, this.displayName);

  static HousingType fromString(String value) {
    return HousingType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => HousingType.individual,
    );
  }
}

/// Housing status enum
enum HousingStatus {
  active('active', 'Aktif'),
  maintenance('maintenance', 'Perawatan'),
  inactive('inactive', 'Tidak Aktif');

  final String value;
  final String displayName;

  const HousingStatus(this.value, this.displayName);

  static HousingStatus fromString(String value) {
    return HousingStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => HousingStatus.active,
    );
  }
}
