/// Inventory Repository
/// 
/// Handles database operations for inventory items and movements.

library;

import '../core/services/supabase_service.dart';
import '../models/inventory.dart';

class InventoryRepository {
  static const String _itemsTable = 'inventory_items';
  static const String _movementsTable = 'stock_movements';

  // ═══════════════════════════════════════════════════════════
  // INVENTORY ITEMS
  // ═══════════════════════════════════════════════════════════

  Future<List<InventoryItem>> getItems(String farmId, {InventoryType? type}) async {
    var query = SupabaseService.client
        .from(_itemsTable)
        .select()
        .eq('farm_id', farmId);

    if (type != null) {
      query = query.eq('type', type.value);
    }

    final response = await query.order('name');

    return (response as List)
        .map((json) => InventoryItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<InventoryItem>> getLowStockItems(String farmId) async {
    final items = await getItems(farmId);
    return items.where((item) => item.isLowStock).toList();
  }

  Future<InventoryItem?> getById(String id) async {
    final response = await SupabaseService.client
        .from(_itemsTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return InventoryItem.fromJson(response);
  }

  Future<InventoryItem> createItem({
    required String farmId,
    required String name,
    required InventoryType type,
    String? unit,
    double quantity = 0,
    double? minimumStock,
    double? unitPrice,
    String? notes,
  }) async {
    final response = await SupabaseService.client
        .from(_itemsTable)
        .insert({
          'farm_id': farmId,
          'name': name,
          'type': type.value,
          'unit': unit,
          'quantity': quantity,
          'minimum_stock': minimumStock,
          'unit_price': unitPrice,
          'notes': notes,
        })
        .select()
        .single();

    return InventoryItem.fromJson(response);
  }

  Future<InventoryItem> updateItem(InventoryItem item) async {
    final response = await SupabaseService.client
        .from(_itemsTable)
        .update({
          'name': item.name,
          'type': item.type.value,
          'unit': item.unit,
          'quantity': item.quantity,
          'minimum_stock': item.minimumStock,
          'unit_price': item.unitPrice,
          'notes': item.notes,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', item.id)
        .select()
        .single();

    return InventoryItem.fromJson(response);
  }

  Future<void> deleteItem(String id) async {
    await SupabaseService.client
        .from(_itemsTable)
        .delete()
        .eq('id', id);
  }

  // ═══════════════════════════════════════════════════════════
  // STOCK MOVEMENTS
  // ═══════════════════════════════════════════════════════════

  Future<StockMovement> addMovement({
    required String inventoryItemId,
    required MovementType type,
    required double quantity,
    required DateTime movementDate,
    String? notes,
  }) async {
    // Create movement
    final response = await SupabaseService.client
        .from(_movementsTable)
        .insert({
          'inventory_item_id': inventoryItemId,
          'type': type.value,
          'quantity': quantity,
          'movement_date': movementDate.toIso8601String().split('T').first,
          'notes': notes,
        })
        .select()
        .single();

    // Update item quantity
    final item = await getById(inventoryItemId);
    if (item != null) {
      double newQuantity = item.quantity;
      if (type == MovementType.purchase) {
        newQuantity += quantity;
      } else if (type == MovementType.usage) {
        newQuantity -= quantity;
      } else {
        newQuantity = quantity; // Adjustment sets absolute value
      }

      await SupabaseService.client
          .from(_itemsTable)
          .update({'quantity': newQuantity})
          .eq('id', inventoryItemId);
    }

    return StockMovement.fromJson(response);
  }

  Future<List<StockMovement>> getMovements(String inventoryItemId) async {
    final response = await SupabaseService.client
        .from(_movementsTable)
        .select()
        .eq('inventory_item_id', inventoryItemId)
        .order('movement_date', ascending: false);

    return (response as List)
        .map((json) => StockMovement.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
