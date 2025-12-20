/// Breed Model
/// 
/// Represents animal breeds (ras) for livestock.

library;

class Breed {
  final String id;
  final String farmId;
  final String code;  // e.g., "NZW", "REX"
  final String name;  // e.g., "New Zealand White", "Rex"
  final String? description;
  final DateTime createdAt;

  const Breed({
    required this.id,
    required this.farmId,
    required this.code,
    required this.name,
    this.description,
    required this.createdAt,
  });

  /// Display name with code
  String get displayName => '$code - $name';

  factory Breed.fromJson(Map<String, dynamic> json) {
    return Breed(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farm_id': farmId,
      'code': code,
      'name': name,
      'description': description,
    };
  }
}
