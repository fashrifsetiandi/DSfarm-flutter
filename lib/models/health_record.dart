/// Health Record Model
/// 
/// Tracks health events like vaccinations, illnesses, treatments.

library;

class HealthRecord {
  final String id;
  final String farmId;
  final String? livestockId;
  final String? offspringId;
  final HealthRecordType type;
  final String title;
  final DateTime recordDate;
  final String? medicine;
  final String? dosage;
  final double? cost;
  final String? notes;
  final DateTime? nextDueDate;
  final DateTime createdAt;

  // Denormalized for display
  final String? animalCode;
  final String? animalName;

  const HealthRecord({
    required this.id,
    required this.farmId,
    this.livestockId,
    this.offspringId,
    required this.type,
    required this.title,
    required this.recordDate,
    this.medicine,
    this.dosage,
    this.cost,
    this.notes,
    this.nextDueDate,
    required this.createdAt,
    this.animalCode,
    this.animalName,
  });

  /// Check if this is for a livestock
  bool get isForLivestock => livestockId != null;

  /// Check if this is for an offspring
  bool get isForOffspring => offspringId != null;

  /// Display name of animal
  String get animalDisplayName => animalName ?? animalCode ?? 'Unknown';

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      livestockId: json['livestock_id'] as String?,
      offspringId: json['offspring_id'] as String?,
      type: HealthRecordType.fromString(json['type'] as String),
      title: json['title'] as String,
      recordDate: DateTime.parse(json['record_date'] as String),
      medicine: json['medicine'] as String?,
      dosage: json['dosage'] as String?,
      cost: (json['cost'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      nextDueDate: json['next_due_date'] != null 
          ? DateTime.parse(json['next_due_date'] as String) 
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      animalCode: json['livestocks']?['code'] as String? 
          ?? json['offsprings']?['code'] as String?,
      animalName: json['livestocks']?['name'] as String? 
          ?? json['offsprings']?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farm_id': farmId,
      'livestock_id': livestockId,
      'offspring_id': offspringId,
      'type': type.value,
      'title': title,
      'record_date': recordDate.toIso8601String().split('T').first,
      'medicine': medicine,
      'dosage': dosage,
      'cost': cost,
      'notes': notes,
      'next_due_date': nextDueDate?.toIso8601String().split('T').first,
    };
  }
}

/// Health record type enum
enum HealthRecordType {
  vaccination('vaccination', 'Vaksin', '💉'),
  illness('illness', 'Sakit', '🤒'),
  treatment('treatment', 'Pengobatan', '💊'),
  checkup('checkup', 'Pemeriksaan', '🩺'),
  deworming('deworming', 'Cacing', '🪱');

  final String value;
  final String displayName;
  final String icon;

  const HealthRecordType(this.value, this.displayName, this.icon);

  static HealthRecordType fromString(String value) {
    return HealthRecordType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => HealthRecordType.checkup,
    );
  }
}
