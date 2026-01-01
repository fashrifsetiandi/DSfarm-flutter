/// Offspring Model (Anakan)
/// 
/// Represents offspring born from breeding records.
/// Tracks growth stages until sold, deceased, or promoted to livestock.

library;

class Offspring {
  final String id;
  final String farmId;
  final String? breedingRecordId;
  final String? housingId;
  final String code;
  final String? name;
  final Gender gender;
  final DateTime birthDate;
  final DateTime? weaningDate;
  final String? breedId;
  final String? breedName;
  final OffspringStatus status;
  final double? weight;
  final double? salePrice;
  final DateTime? saleDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Denormalized for display
  final String? damCode;      // Mother code
  final String? sireCode;     // Father code
  final String? housingCode;

  const Offspring({
    required this.id,
    required this.farmId,
    this.breedingRecordId,
    this.housingId,
    required this.code,
    this.name,
    required this.gender,
    required this.birthDate,
    this.weaningDate,
    this.breedId,
    this.breedName,
    this.status = OffspringStatus.infarm,
    this.weight,
    this.salePrice,
    this.saleDate,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.damCode,
    this.sireCode,
    this.housingCode,
  });

  /// Display name (use name if available, otherwise code)
  String get displayName => name ?? code;

  /// Age in days
  int get ageInDays => DateTime.now().difference(birthDate).inDays;

  /// Age formatted as string
  String get ageFormatted {
    final now = DateTime.now();
    final birth = birthDate;
    
    // Calculate years, months, days using calendar logic
    int years = now.year - birth.year;
    int months = now.month - birth.month;
    int days = now.day - birth.day;
    
    // Adjust for negative days
    if (days < 0) {
      months--;
      final prevMonth = DateTime(now.year, now.month, 0);
      days += prevMonth.day;
    }
    
    // Adjust for negative months
    if (months < 0) {
      years--;
      months += 12;
    }
    
    if (years > 0) {
      if (months > 0) {
        return '${years}th ${months}bln ${days}hr';
      }
      return '${years}th ${days}hr';
    }
    if (months > 0) {
      return '${months}bln ${days}hr';
    }
    return '${days} hari';
  }

  /// Gender icon
  String get genderIcon => gender == Gender.male ? '♂️' : '♀️';

  /// Check if weaned
  bool get isWeaned => weaningDate != null;

  /// Effective status - auto-calculates "siap jual" if 3+ months old
  /// This does not change the database value, just the displayed status
  OffspringStatus get effectiveStatus {
    // If already sold, deceased, or promoted - keep that status
    if (status == OffspringStatus.sold || 
        status == OffspringStatus.deceased ||
        status == OffspringStatus.promoted) {
      return status;
    }
    
    // If 3+ months old (90 days) and still infarm/weaned, show as ready to sell
    if (ageInDays >= 90 && 
        (status == OffspringStatus.infarm || 
         status == OffspringStatus.weaned)) {
      return OffspringStatus.readySell;
    }
    
    return status;
  }

  /// Create from JSON (Supabase response)
  factory Offspring.fromJson(Map<String, dynamic> json) {
    return Offspring(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      breedingRecordId: json['breeding_record_id'] as String?,
      housingId: json['housing_id'] as String?,
      code: json['code'] as String,
      name: json['name'] as String?,
      gender: Gender.fromString(json['gender'] as String? ?? 'female'),
      birthDate: DateTime.parse(json['birth_date'] as String),
      weaningDate: json['weaning_date'] != null 
          ? DateTime.parse(json['weaning_date'] as String) 
          : null,
      breedId: json['breed_id'] as String?,
      breedName: json['breeds']?['name'] as String?,
      status: OffspringStatus.fromString(json['status'] as String? ?? 'infarm'),
      weight: (json['weight'] as num?)?.toDouble(),
      salePrice: (json['sale_price'] as num?)?.toDouble(),
      saleDate: json['sale_date'] != null 
          ? DateTime.parse(json['sale_date'] as String) 
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      damCode: json['breeding_records']?['dam']?['code'] as String?,
      sireCode: json['breeding_records']?['sire']?['code'] as String?,
      housingCode: json['housings']?['code'] as String?,
    );
  }

  /// Convert to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'farm_id': farmId,
      'breeding_record_id': breedingRecordId,
      'housing_id': housingId,
      'code': code,
      'name': name,
      'gender': gender.value,
      'birth_date': birthDate.toIso8601String().split('T').first,
      'weaning_date': weaningDate?.toIso8601String().split('T').first,
      'breed_id': breedId,
      'status': status.value,
      'weight': weight,
      'sale_price': salePrice,
      'sale_date': saleDate?.toIso8601String().split('T').first,
      'notes': notes,
    };
  }

  /// Create copy with updated fields
  Offspring copyWith({
    String? id,
    String? farmId,
    String? breedingRecordId,
    String? housingId,
    String? code,
    String? name,
    Gender? gender,
    DateTime? birthDate,
    DateTime? weaningDate,
    String? breedId,
    String? breedName,
    OffspringStatus? status,
    double? weight,
    double? salePrice,
    DateTime? saleDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? damCode,
    String? sireCode,
    String? housingCode,
  }) {
    return Offspring(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      breedingRecordId: breedingRecordId ?? this.breedingRecordId,
      housingId: housingId ?? this.housingId,
      code: code ?? this.code,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      weaningDate: weaningDate ?? this.weaningDate,
      breedId: breedId ?? this.breedId,
      breedName: breedName ?? this.breedName,
      status: status ?? this.status,
      weight: weight ?? this.weight,
      salePrice: salePrice ?? this.salePrice,
      saleDate: saleDate ?? this.saleDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      damCode: damCode ?? this.damCode,
      sireCode: sireCode ?? this.sireCode,
      housingCode: housingCode ?? this.housingCode,
    );
  }

  @override
  String toString() => 'Offspring(id: $id, code: $code, age: $ageInDays days)';
}

/// Gender enum (reused from livestock)
enum Gender {
  male('male', 'Jantan', '♂️'),
  female('female', 'Betina', '♀️'),
  unknown('unknown', 'Belum Diketahui', '❓');

  final String value;
  final String displayName;
  final String icon;

  const Gender(this.value, this.displayName, this.icon);

  static Gender fromString(String value) {
    return Gender.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Gender.unknown,
    );
  }
}

/// Offspring status enum
enum OffspringStatus {
  infarm('infarm', 'Di Farm'),
  weaned('weaned', 'Lepas Sapih'),
  readySell('ready_sell', 'Siap Jual'),
  sold('sold', 'Terjual'),
  deceased('deceased', 'Mati'),
  promoted('promoted', 'Jadi Indukan');

  final String value;
  final String displayName;

  const OffspringStatus(this.value, this.displayName);

  static OffspringStatus fromString(String value) {
    return OffspringStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OffspringStatus.infarm,
    );
  }

  bool get isActive => 
      this != OffspringStatus.sold && 
      this != OffspringStatus.deceased && 
      this != OffspringStatus.promoted;
}
