/// Livestock Model (Indukan/Pejantan)
/// 
/// Represents breeding livestock in the farm.
/// Can be male (pejantan) or female (induk).

library;

class Livestock {
  final String id;
  final String farmId;
  final String? housingId;
  final String code;       // e.g., "I-001", "P-001"
  final String? name;
  final Gender gender;
  final String? breedId;
  final String? breedName; // Denormalized for display
  final DateTime? birthDate;
  final DateTime? acquisitionDate;
  final AcquisitionType acquisitionType;
  final double? purchasePrice;
  final LivestockStatus status;
  final int generation;
  final double? weight;     // Current weight in kg
  final String? notes;
  final Map<String, dynamic>? metadata; // Flexible per-animal fields
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Computed properties
  final String? housingCode; // Denormalized for display

  const Livestock({
    required this.id,
    required this.farmId,
    this.housingId,
    required this.code,
    this.name,
    required this.gender,
    this.breedId,
    this.breedName,
    this.birthDate,
    this.acquisitionDate,
    this.acquisitionType = AcquisitionType.purchased,
    this.purchasePrice,
    this.status = LivestockStatus.active,
    this.generation = 1,
    this.weight,
    this.notes,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
    this.housingCode,
  });

  /// Display name is just the code
  String get displayName => code;

  /// Age in days (null if birth date unknown)
  int? get ageInDays {
    if (birthDate == null) return null;
    return DateTime.now().difference(birthDate!).inDays;
  }

  /// Age formatted as string
  String get ageFormatted {
    final days = ageInDays;
    if (days == null) return '-';
    
    if (days < 30) return '$days hari';
    if (days < 365) return '${(days / 30).floor()} bulan';
    
    final years = (days / 365).floor();
    final months = ((days % 365) / 30).floor();
    if (months == 0) return '$years tahun';
    return '$years tahun $months bulan';
  }

  /// Gender icon
  String get genderIcon => gender == Gender.male ? '♂️' : '♀️';

  /// Check if female (for breeding purposes)
  bool get isFemale => gender == Gender.female;

  /// Check if male (for breeding purposes)
  bool get isMale => gender == Gender.male;

  /// Get gender prefix for code (J = Jantan, B = Betina)
  String get genderPrefix => gender == Gender.male ? 'J' : 'B';

  /// Get sequence number from code (e.g., "REX-J01" -> "01")
  String get sequenceNumber {
    final parts = code.split('-');
    if (parts.length < 2) return '01';
    // Extract digits from "J01" or "B123"
    return parts.last.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Create from JSON (Supabase response)
  factory Livestock.fromJson(Map<String, dynamic> json) {
    return Livestock(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      housingId: json['housing_id'] as String?,
      code: json['code'] as String,
      name: json['name'] as String?,
      gender: Gender.fromString(json['gender'] as String),
      breedId: json['breed_id'] as String?,
      breedName: json['breeds']?['name'] as String?,
      birthDate: json['birth_date'] != null 
          ? DateTime.parse(json['birth_date'] as String) 
          : null,
      acquisitionDate: json['acquisition_date'] != null 
          ? DateTime.parse(json['acquisition_date'] as String) 
          : null,
      acquisitionType: AcquisitionType.fromString(
        json['acquisition_type'] as String? ?? 'purchased',
      ),
      purchasePrice: (json['purchase_price'] as num?)?.toDouble(),
      status: LivestockStatus.fromString(json['status'] as String? ?? 'active'),
      generation: json['generation'] as int? ?? 1,
      weight: (json['weight'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      housingCode: json['housings']?['code'] as String?,
    );
  }

  /// Convert to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
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
      'status': status.value,
      'generation': generation,
      'weight': weight,
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// Create copy with updated fields
  Livestock copyWith({
    String? id,
    String? farmId,
    String? housingId,
    String? code,
    String? name,
    Gender? gender,
    String? breedId,
    String? breedName,
    DateTime? birthDate,
    DateTime? acquisitionDate,
    AcquisitionType? acquisitionType,
    double? purchasePrice,
    LivestockStatus? status,
    int? generation,
    double? weight,
    String? notes,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? housingCode,
  }) {
    return Livestock(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      housingId: housingId ?? this.housingId,
      code: code ?? this.code,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      breedId: breedId ?? this.breedId,
      breedName: breedName ?? this.breedName,
      birthDate: birthDate ?? this.birthDate,
      acquisitionDate: acquisitionDate ?? this.acquisitionDate,
      acquisitionType: acquisitionType ?? this.acquisitionType,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      status: status ?? this.status,
      generation: generation ?? this.generation,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      housingCode: housingCode ?? this.housingCode,
    );
  }

  @override
  String toString() => 'Livestock(id: $id, code: $code, gender: $gender)';
}

/// Gender enum
enum Gender {
  male('male', 'Jantan', '♂️'),
  female('female', 'Betina', '♀️');

  final String value;
  final String displayName;
  final String icon;

  const Gender(this.value, this.displayName, this.icon);

  static Gender fromString(String value) {
    return Gender.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Gender.female,
    );
  }
}

/// Acquisition type enum
enum AcquisitionType {
  born('born', 'Lahir di Farm'),
  purchased('purchased', 'Pembelian'),
  gifted('gifted', 'Hibah');

  final String value;
  final String displayName;

  const AcquisitionType(this.value, this.displayName);

  static AcquisitionType fromString(String value) {
    return AcquisitionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AcquisitionType.purchased,
    );
  }
}

/// Livestock status enum
enum LivestockStatus {
  active('active', 'Aktif'),
  sold('sold', 'Terjual'),
  deceased('deceased', 'Mati'),
  culled('culled', 'Afkir');

  final String value;
  final String displayName;

  const LivestockStatus(this.value, this.displayName);

  static LivestockStatus fromString(String value) {
    return LivestockStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LivestockStatus.active,
    );
  }
}
