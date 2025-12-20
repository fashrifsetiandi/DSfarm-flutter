/// Farm Model
/// 
/// Represents a farm owned by a user.
/// Each user can have multiple farms with different animal types.

library;

class Farm {
  final String id;
  final String userId;
  final String name;
  final String animalType; // 'rabbit', 'goat', 'fish', 'poultry'
  final String? location;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Farm({
    required this.id,
    required this.userId,
    required this.name,
    required this.animalType,
    this.location,
    this.description,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Icon emoji based on animal type
  String get icon {
    switch (animalType) {
      case 'rabbit':
        return '🐰';
      case 'goat':
        return '🐐';
      case 'fish':
        return '🐟';
      case 'poultry':
        return '🐔';
      default:
        return '🐾';
    }
  }

  /// Display name for animal type
  String get animalTypeName {
    switch (animalType) {
      case 'rabbit':
        return 'Kelinci';
      case 'goat':
        return 'Kambing/Domba';
      case 'fish':
        return 'Ikan';
      case 'poultry':
        return 'Unggas';
      default:
        return 'Hewan';
    }
  }

  /// Create Farm from JSON (Supabase response)
  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      animalType: json['animal_type'] as String,
      location: json['location'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  /// Convert Farm to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'animal_type': animalType,
      'location': location,
      'description': description,
      'is_active': isActive,
    };
  }

  /// Create a copy with updated fields
  Farm copyWith({
    String? id,
    String? userId,
    String? name,
    String? animalType,
    String? location,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Farm(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      animalType: animalType ?? this.animalType,
      location: location ?? this.location,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Farm(id: $id, name: $name, type: $animalType)';
}

/// Animal types supported by DSFarm
enum AnimalType {
  rabbit('rabbit', 'Kelinci', '🐰'),
  goat('goat', 'Kambing/Domba', '🐐'),
  fish('fish', 'Ikan', '🐟'),
  poultry('poultry', 'Unggas', '🐔');

  final String value;
  final String displayName;
  final String icon;

  const AnimalType(this.value, this.displayName, this.icon);

  /// Get AnimalType from string value
  static AnimalType fromString(String value) {
    return AnimalType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AnimalType.rabbit,
    );
  }
}
