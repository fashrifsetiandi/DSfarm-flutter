/// Inventory Provider
/// 
/// Riverpod providers for inventory state management.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory.dart';
import '../repositories/inventory_repository.dart';
import '../providers/farm_provider.dart';

/// Repository provider
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository();
});

/// Provider for all inventory items
final inventoryItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getItems(farm.id);
});

/// Provider for items by type
final inventoryByTypeProvider = FutureProvider.family<List<InventoryItem>, InventoryType>((ref, type) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getItems(farm.id, type: type);
});

/// Provider for low stock alerts
final lowStockItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getLowStockItems(farm.id);
});

/// Notifier for inventory CRUD
class InventoryNotifier extends StateNotifier<AsyncValue<List<InventoryItem>>> {
  final InventoryRepository _repository;
  final String? _farmId;

  InventoryNotifier(this._repository, this._farmId) : super(const AsyncValue.loading()) {
    if (_farmId != null) loadItems();
  }

  Future<void> loadItems() async {
    if (_farmId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getItems(_farmId);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<InventoryItem> createItem({
    required String name,
    required InventoryType type,
    String? unit,
    double quantity = 0,
    double? minimumStock,
    double? unitPrice,
    String? notes,
  }) async {
    if (_farmId == null) throw Exception('No farm selected');
    
    final item = await _repository.createItem(
      farmId: _farmId,
      name: name,
      type: type,
      unit: unit,
      quantity: quantity,
      minimumStock: minimumStock,
      unitPrice: unitPrice,
      notes: notes,
    );
    
    await loadItems();
    return item;
  }

  Future<void> update(InventoryItem item) async {
    await _repository.updateItem(item);
    await loadItems();
  }

  Future<void> addStock(String itemId, double quantity, {String? notes}) async {
    await _repository.addMovement(
      inventoryItemId: itemId,
      type: MovementType.purchase,
      quantity: quantity,
      movementDate: DateTime.now(),
      notes: notes,
    );
    await loadItems();
  }

  Future<void> useStock(String itemId, double quantity, {String? notes}) async {
    await _repository.addMovement(
      inventoryItemId: itemId,
      type: MovementType.usage,
      quantity: quantity,
      movementDate: DateTime.now(),
      notes: notes,
    );
    await loadItems();
  }

  Future<void> delete(String id) async {
    await _repository.deleteItem(id);
    await loadItems();
  }
}

/// Provider for InventoryNotifier
final inventoryNotifierProvider = StateNotifierProvider<InventoryNotifier, AsyncValue<List<InventoryItem>>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  final farm = ref.watch(currentFarmProvider);
  return InventoryNotifier(repository, farm?.id);
});
