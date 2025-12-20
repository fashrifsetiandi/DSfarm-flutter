/// Finance Repository
/// 
/// Handles database operations for finance transactions and categories.

library;

import '../core/services/supabase_service.dart';
import '../models/finance.dart';

class FinanceRepository {
  static const String _transactionsTable = 'finance_transactions';
  static const String _categoriesTable = 'finance_categories';

  // ═══════════════════════════════════════════════════════════
  // TRANSACTIONS
  // ═══════════════════════════════════════════════════════════

  Future<List<FinanceTransaction>> getTransactions(String farmId, {
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
  }) async {
    var query = SupabaseService.client
        .from(_transactionsTable)
        .select('''
          *,
          finance_categories:category_id(name)
        ''')
        .eq('farm_id', farmId);

    if (type != null) {
      query = query.eq('type', type.value);
    }
    if (startDate != null) {
      query = query.gte('transaction_date', startDate.toIso8601String().split('T').first);
    }
    if (endDate != null) {
      query = query.lte('transaction_date', endDate.toIso8601String().split('T').first);
    }

    final response = await query.order('transaction_date', ascending: false);

    return (response as List)
        .map((json) => FinanceTransaction.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<FinanceTransaction> createTransaction({
    required String farmId,
    required TransactionType type,
    required String categoryId,
    required double amount,
    required DateTime transactionDate,
    String? description,
    String? referenceId,
    String? referenceType,
  }) async {
    final response = await SupabaseService.client
        .from(_transactionsTable)
        .insert({
          'farm_id': farmId,
          'type': type.value,
          'category_id': categoryId,
          'amount': amount,
          'transaction_date': transactionDate.toIso8601String().split('T').first,
          'description': description,
          'reference_id': referenceId,
          'reference_type': referenceType,
        })
        .select('''
          *,
          finance_categories:category_id(name)
        ''')
        .single();

    return FinanceTransaction.fromJson(response);
  }

  Future<void> deleteTransaction(String id) async {
    await SupabaseService.client
        .from(_transactionsTable)
        .delete()
        .eq('id', id);
  }

  // ═══════════════════════════════════════════════════════════
  // SUMMARY
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, double>> getSummary(String farmId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await getTransactions(
      farmId,
      startDate: startDate,
      endDate: endDate,
    );

    double totalIncome = 0;
    double totalExpense = 0;

    for (final t in transactions) {
      if (t.isIncome) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }

  // ═══════════════════════════════════════════════════════════
  // CATEGORIES
  // ═══════════════════════════════════════════════════════════

  Future<List<FinanceCategory>> getCategories(String farmId, {TransactionType? type}) async {
    var query = SupabaseService.client
        .from(_categoriesTable)
        .select()
        .eq('farm_id', farmId);

    if (type != null) {
      query = query.eq('type', type.value);
    }

    final response = await query.order('name');

    return (response as List)
        .map((json) => FinanceCategory.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<FinanceCategory> createCategory({
    required String farmId,
    required String name,
    required TransactionType type,
    String? icon,
  }) async {
    final response = await SupabaseService.client
        .from(_categoriesTable)
        .insert({
          'farm_id': farmId,
          'name': name,
          'type': type.value,
          'icon': icon,
          'is_system': false,
        })
        .select()
        .single();

    return FinanceCategory.fromJson(response);
  }

  Future<void> deleteCategory(String id) async {
    await SupabaseService.client
        .from(_categoriesTable)
        .delete()
        .eq('id', id);
  }
}
