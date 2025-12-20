/// Block Model
/// 
/// Represents a block/building containing multiple housings.

library;

class Block {
  final String id;
  final String farmId;
  final String code;  // e.g., "BLOCK-A"
  final String? name;  // e.g., "Gedung Utama" 
  final String? description;
  final DateTime createdAt;

  const Block({
    required this.id,
    required this.farmId,
    required this.code,
    this.name,
    this.description,
    required this.createdAt,
  });

  /// Display name with code
  String get displayName => name != null ? '$code - $name' : code;

  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      code: json['code'] as String,
      name: json['name'] as String?,
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
