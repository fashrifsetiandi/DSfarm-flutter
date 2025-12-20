/// Reminder Screen
/// 
/// Screen untuk melihat dan mengelola pengingat.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/reminder.dart';
import '../../../providers/reminder_provider.dart';

class ReminderScreen extends ConsumerWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(reminderNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengingat'),
      ),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reminders) {
          if (reminders.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          return _buildList(context, ref, reminders);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔔', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada pengingat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Pengingat akan muncul otomatis saat mencatat breeding',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Manual'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<Reminder> reminders) {
    // Separate overdue, today, upcoming
    final overdue = reminders.where((r) => r.isOverdue).toList();
    final today = reminders.where((r) => r.isDueToday).toList();
    final upcoming = reminders.where((r) => !r.isOverdue && !r.isDueToday).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (overdue.isNotEmpty) ...[
          _SectionHeader(title: '⚠️ Terlambat', count: overdue.length, color: Colors.red),
          ...overdue.map((r) => _ReminderCard(
            reminder: r,
            onComplete: () => _markComplete(context, ref, r),
          )),
          const SizedBox(height: 16),
        ],
        if (today.isNotEmpty) ...[
          _SectionHeader(title: '📌 Hari Ini', count: today.length, color: Colors.orange),
          ...today.map((r) => _ReminderCard(
            reminder: r,
            onComplete: () => _markComplete(context, ref, r),
          )),
          const SizedBox(height: 16),
        ],
        if (upcoming.isNotEmpty) ...[
          _SectionHeader(title: '📅 Mendatang', count: upcoming.length, color: Colors.blue),
          ...upcoming.map((r) => _ReminderCard(
            reminder: r,
            onComplete: () => _markComplete(context, ref, r),
          )),
        ],
      ],
    );
  }

  void _markComplete(BuildContext context, WidgetRef ref, Reminder reminder) async {
    await ref.read(reminderNotifierProvider.notifier).markCompleted(reminder.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${reminder.title} selesai')),
      );
    }
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    ReminderType selectedType = ReminderType.custom;
    DateTime dueDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Tambah Pengingat'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Type
                  DropdownButtonFormField<ReminderType>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Tipe'),
                    items: ReminderType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text('${type.icon} ${type.displayName}'),
                      );
                    }).toList(),
                    onChanged: (v) => setDialogState(() => selectedType = v!),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Judul'),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Deskripsi (Opsional)'),
                  ),
                  const SizedBox(height: 16),

                  // Due date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => dueDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Tanggal'),
                      child: Text('${dueDate.day}/${dueDate.month}/${dueDate.year}'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) return;

                  Navigator.pop(context);
                  await ref.read(reminderNotifierProvider.notifier).create(
                    type: selectedType,
                    title: titleController.text.trim(),
                    description: descController.text.trim().isEmpty 
                        ? null 
                        : descController.text.trim(),
                    dueDate: dueDate,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pengingat ditambahkan')),
                    );
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onComplete;

  const _ReminderCard({
    required this.reminder,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColor().withAlpha(25),
          child: Text(reminder.type.icon),
        ),
        title: Text(reminder.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminder.description != null)
              Text(
                reminder.description!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            Text(
              _formatDueDate(),
              style: TextStyle(
                fontSize: 12,
                color: reminder.isOverdue ? Colors.red : Colors.grey[500],
                fontWeight: reminder.isOverdue ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.check_circle_outline, color: _getColor()),
          onPressed: onComplete,
        ),
      ),
    );
  }

  String _formatDueDate() {
    final days = reminder.daysUntilDue;
    if (days < 0) return '${days.abs()} hari lalu';
    if (days == 0) return 'Hari ini';
    if (days == 1) return 'Besok';
    return '$days hari lagi';
  }

  Color _getColor() {
    if (reminder.isOverdue) return Colors.red;
    if (reminder.isDueToday) return Colors.orange;
    if (reminder.isDueSoon) return Colors.amber;
    return Colors.blue;
  }
}
