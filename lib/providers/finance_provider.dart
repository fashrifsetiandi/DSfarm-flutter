/// Finance Provider
/// 
/// Riverpod providers for finance state management.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/finance.dart';
import '../repositories/finance_repository.dart';
import '../providers/farm_provider.dart';

/// Repository provider
final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository();
});

/// Provider for transactions of current farm
final transactionsProvider = FutureProvider<List<FinanceTransaction>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getTransactions(farm.id);
});

/// Provider for finance summary
final financeSummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return {'income': 0, 'expense': 0, 'balance': 0};
  
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getSummary(farm.id);
});

/// Provider for categories by type
final categoriesProvider = FutureProvider.family<List<FinanceCategory>, TransactionType?>((ref, type) async {
  final farm = ref.watch(currentFarmProvider);
  if (farm == null) return [];
  
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getCategories(farm.id, type: type);
});

/// Notifier for finance CRUD
class FinanceNotifier extends StateNotifier<AsyncValue<List<FinanceTransaction>>> {
  final FinanceRepository _repository;
  final String? _farmId;

  FinanceNotifier(this._repository, this._farmId) 
      : super(_farmId == null ? const AsyncValue.data([]) : const AsyncValue.loading()) {
    if (_farmId != null) loadTransactions();
  }

  Future<void> loadTransactions() async {
    if (_farmId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    try {
      final transactions = await _repository.getTransactions(_farmId);
      state = AsyncValue.data(transactions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<FinanceTransaction> createTransaction({
    required TransactionType type,
    required String categoryId,
    required double amount,
    required DateTime transactionDate,
    String? description,
    String? referenceId,
    String? referenceType,
  }) async {
    if (_farmId == null) throw Exception('No farm selected');
    
    final transaction = await _repository.createTransaction(
      farmId: _farmId,
      type: type,
      categoryId: categoryId,
      amount: amount,
      transactionDate: transactionDate,
      description: description,
      referenceId: referenceId,
      referenceType: referenceType,
    );
    
    await loadTransactions();
    return transaction;
  }

  Future<void> delete(String id) async {
    await _repository.deleteTransaction(id);
    await loadTransactions();
  }
}

/// Provider for FinanceNotifier
final financeNotifierProvider = StateNotifierProvider<FinanceNotifier, AsyncValue<List<FinanceTransaction>>>((ref) {
  final repository = ref.watch(financeRepositoryProvider);
  final farm = ref.watch(currentFarmProvider);
  return FinanceNotifier(repository, farm?.id);
});

/// Notifier for finance categories CRUD
class FinanceCategoriesNotifier extends StateNotifier<AsyncValue<List<FinanceCategory>>> {
  final FinanceRepository _repository;
  final String? _farmId;

  FinanceCategoriesNotifier(this._repository, this._farmId) 
      : super(_farmId == null ? const AsyncValue.data([]) : const AsyncValue.loading()) {
    if (_farmId != null) loadCategories();
  }

  Future<void> loadCategories() async {
    if (_farmId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    try {
      final categories = await _repository.getCategories(_farmId);
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<FinanceCategory> create({
    required String name,
    required TransactionType type,
    String? icon,
  }) async {
    if (_farmId == null) throw Exception('No farm selected');
    
    final category = await _repository.createCategory(
      farmId: _farmId,
      name: name,
      type: type,
      icon: icon,
    );
    
    await loadCategories();
    return category;
  }

  Future<void> delete(String id) async {
    await _repository.deleteCategory(id);
    await loadCategories();
  }
}

/// Provider for FinanceCategoriesNotifier
final financeCategoriesNotifierProvider = StateNotifierProvider<FinanceCategoriesNotifier, AsyncValue<List<FinanceCategory>>>((ref) {
  final repository = ref.watch(financeRepositoryProvider);
  final farm = ref.watch(currentFarmProvider);
  return FinanceCategoriesNotifier(repository, farm?.id);
});

