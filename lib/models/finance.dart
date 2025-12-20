/// Finance Transaction Model
/// 
/// Represents income and expense transactions for the farm.
/// Supports categorization and linkage to sales/purchases.

library;

class FinanceTransaction {
  final String id;
  final String farmId;
  final TransactionType type;
  final String categoryId;
  final String? categoryName;
  final double amount;
  final DateTime transactionDate;
  final String? description;
  final String? referenceId;    // Link to sale, purchase, etc.
  final String? referenceType;  // 'offspring_sale', 'livestock_sale', etc.
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FinanceTransaction({
    required this.id,
    required this.farmId,
    required this.type,
    required this.categoryId,
    this.categoryName,
    required this.amount,
    required this.transactionDate,
    this.description,
    this.referenceId,
    this.referenceType,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if income
  bool get isIncome => type == TransactionType.income;

  /// Check if expense
  bool get isExpense => type == TransactionType.expense;

  /// Formatted amount with sign
  String get formattedAmount {
    final prefix = isIncome ? '+' : '-';
    return '$prefix Rp ${_formatNumber(amount)}';
  }

  static String _formatNumber(double num) {
    return num.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }

  /// Create from JSON
  factory FinanceTransaction.fromJson(Map<String, dynamic> json) {
    return FinanceTransaction(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      type: TransactionType.fromString(json['type'] as String),
      categoryId: json['category_id'] as String,
      categoryName: json['finance_categories']?['name'] as String?,
      amount: (json['amount'] as num).toDouble(),
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      description: json['description'] as String?,
      referenceId: json['reference_id'] as String?,
      referenceType: json['reference_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'farm_id': farmId,
      'type': type.value,
      'category_id': categoryId,
      'amount': amount,
      'transaction_date': transactionDate.toIso8601String().split('T').first,
      'description': description,
      'reference_id': referenceId,
      'reference_type': referenceType,
    };
  }

  FinanceTransaction copyWith({
    String? id,
    String? farmId,
    TransactionType? type,
    String? categoryId,
    String? categoryName,
    double? amount,
    DateTime? transactionDate,
    String? description,
    String? referenceId,
    String? referenceType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      description: description ?? this.description,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Transaction type enum
enum TransactionType {
  income('income', 'Pemasukan'),
  expense('expense', 'Pengeluaran');

  final String value;
  final String displayName;

  const TransactionType(this.value, this.displayName);

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionType.expense,
    );
  }
}

/// Finance Category Model
class FinanceCategory {
  final String id;
  final String farmId;
  final String name;
  final TransactionType type;
  final String? icon;
  final bool isSystem;
  final DateTime createdAt;

  const FinanceCategory({
    required this.id,
    required this.farmId,
    required this.name,
    required this.type,
    this.icon,
    this.isSystem = false,
    required this.createdAt,
  });

  factory FinanceCategory.fromJson(Map<String, dynamic> json) {
    return FinanceCategory(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      name: json['name'] as String,
      type: TransactionType.fromString(json['type'] as String),
      icon: json['icon'] as String?,
      isSystem: json['is_system'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farm_id': farmId,
      'name': name,
      'type': type.value,
      'icon': icon,
      'is_system': isSystem,
    };
  }
}
