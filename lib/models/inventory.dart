/// Inventory Model
/// 
/// Represents inventory items (feed, equipment, supplies).

library;

class InventoryItem {
  final String id;
  final String farmId;
  final String name;
  final InventoryType type;
  final String? unit;           // kg, pcs, liter, etc.
  final double quantity;
  final double? minimumStock;   // Alert threshold
  final double? unitPrice;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const InventoryItem({
    required this.id,
    required this.farmId,
    required this.name,
    required this.type,
    this.unit,
    this.quantity = 0,
    this.minimumStock,
    this.unitPrice,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if stock is low
  bool get isLowStock {
    if (minimumStock == null) return false;
    return quantity <= minimumStock!;
  }

  /// Total value
  double get totalValue => quantity * (unitPrice ?? 0);

  /// Formatted quantity with unit
  String get formattedQuantity => '$quantity ${unit ?? ''}';

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      name: json['name'] as String,
      type: InventoryType.fromString(json['type'] as String),
      unit: json['unit'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      minimumStock: (json['minimum_stock'] as num?)?.toDouble(),
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farm_id': farmId,
      'name': name,
      'type': type.value,
      'unit': unit,
      'quantity': quantity,
      'minimum_stock': minimumStock,
      'unit_price': unitPrice,
      'notes': notes,
    };
  }

  InventoryItem copyWith({
    String? id,
    String? farmId,
    String? name,
    InventoryType? type,
    String? unit,
    double? quantity,
    double? minimumStock,
    double? unitPrice,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      name: name ?? this.name,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      minimumStock: minimumStock ?? this.minimumStock,
      unitPrice: unitPrice ?? this.unitPrice,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Inventory type enum
enum InventoryType {
  feed('feed', 'Pakan', '🌾'),
  medicine('medicine', 'Obat', '💊'),
  equipment('equipment', 'Peralatan', '🔧'),
  supply('supply', 'Bahan', '📦');

  final String value;
  final String displayName;
  final String icon;

  const InventoryType(this.value, this.displayName, this.icon);

  static InventoryType fromString(String value) {
    return InventoryType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InventoryType.supply,
    );
  }
}

/// Stock Movement (for tracking usage/purchase)
class StockMovement {
  final String id;
  final String inventoryItemId;
  final MovementType type;
  final double quantity;
  final DateTime movementDate;
  final String? notes;
  final DateTime createdAt;

  const StockMovement({
    required this.id,
    required this.inventoryItemId,
    required this.type,
    required this.quantity,
    required this.movementDate,
    this.notes,
    required this.createdAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] as String,
      inventoryItemId: json['inventory_item_id'] as String,
      type: MovementType.fromString(json['type'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      movementDate: DateTime.parse(json['movement_date'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventory_item_id': inventoryItemId,
      'type': type.value,
      'quantity': quantity,
      'movement_date': movementDate.toIso8601String().split('T').first,
      'notes': notes,
    };
  }
}

enum MovementType {
  purchase('purchase', 'Pembelian'),
  usage('usage', 'Pemakaian'),
  adjustment('adjustment', 'Penyesuaian');

  final String value;
  final String displayName;

  const MovementType(this.value, this.displayName);

  static MovementType fromString(String value) {
    return MovementType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MovementType.usage,
    );
  }
}
