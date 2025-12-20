/// Reminder Model
/// 
/// Tracks reminders for breeding, health, and other events.

library;

class Reminder {
  final String id;
  final String farmId;
  final ReminderType type;
  final String title;
  final String? description;
  final DateTime dueDate;
  final String? referenceId;
  final String? referenceType;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;

  const Reminder({
    required this.id,
    required this.farmId,
    required this.type,
    required this.title,
    this.description,
    required this.dueDate,
    this.referenceId,
    this.referenceType,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
  });

  /// Days until due (negative = overdue)
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  /// Check if overdue
  bool get isOverdue => !isCompleted && daysUntilDue < 0;

  /// Check if due today
  bool get isDueToday => !isCompleted && daysUntilDue == 0;

  /// Check if due soon (within 3 days)
  bool get isDueSoon => !isCompleted && daysUntilDue > 0 && daysUntilDue <= 3;

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      type: ReminderType.fromString(json['type'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      referenceId: json['reference_id'] as String?,
      referenceType: json['reference_type'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farm_id': farmId,
      'type': type.value,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String().split('T').first,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  Reminder copyWith({
    String? id,
    String? farmId,
    ReminderType? type,
    String? title,
    String? description,
    DateTime? dueDate,
    String? referenceId,
    String? referenceType,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Reminder type enum
enum ReminderType {
  palpation('palpation', 'Palpasi', '🤰'),
  expectedBirth('expected_birth', 'Perkiraan Lahir', '🐣'),
  weaning('weaning', 'Penyapihan', '🍼'),
  vaccination('vaccination', 'Vaksin', '💉'),
  healthCheck('health_check', 'Pemeriksaan', '🩺'),
  mating('mating', 'Kawin', '❤️'),
  custom('custom', 'Lainnya', '📌');

  final String value;
  final String displayName;
  final String icon;

  const ReminderType(this.value, this.displayName, this.icon);

  static ReminderType fromString(String value) {
    return ReminderType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReminderType.custom,
    );
  }
}
