/// Health Screen
/// 
/// Screen untuk melihat dan mencatat riwayat kesehatan.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/health_record.dart';
import '../../../providers/health_provider.dart';
import '../../../providers/livestock_provider.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kesehatan'),
      ),
      body: healthAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (records) {
          if (records.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          return _buildList(context, ref, records);
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
            const Text('🩺', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Belum ada catatan kesehatan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Catat vaksin, pengobatan, dan pemeriksaan',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Catatan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<HealthRecord> records) {
    // Group by type
    final grouped = <HealthRecordType, List<HealthRecord>>{};
    for (final record in records) {
      grouped.putIfAbsent(record.type, () => []);
      grouped[record.type]!.add(record);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(entry.key.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    entry.key.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${entry.value.length}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
            ...entry.value.map((record) => _HealthCard(record: record)),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final medicineController = TextEditingController();
    final dosageController = TextEditingController();
    final costController = TextEditingController();
    final notesController = TextEditingController();
    HealthRecordType selectedType = HealthRecordType.vaccination;
    String? selectedLivestockId;
    DateTime recordDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        final livestocksAsync = ref.watch(livestockNotifierProvider);

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Tambah Catatan Kesehatan'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Type
                  DropdownButtonFormField<HealthRecordType>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Tipe'),
                    items: HealthRecordType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text('${type.icon} ${type.displayName}'),
                      );
                    }).toList(),
                    onChanged: (v) => setDialogState(() => selectedType = v!),
                  ),
                  const SizedBox(height: 16),

                  // Animal
                  livestocksAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error loading'),
                    data: (livestocks) => DropdownButtonFormField<String>(
                      value: selectedLivestockId,
                      decoration: const InputDecoration(labelText: 'Hewan'),
                      hint: const Text('Pilih hewan'),
                      items: livestocks.map((l) => DropdownMenuItem(
                        value: l.id,
                        child: Text(l.displayName),
                      )).toList(),
                      onChanged: (v) => setDialogState(() => selectedLivestockId = v),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul',
                      hintText: selectedType == HealthRecordType.vaccination 
                          ? 'Vaksin RHD' 
                          : 'Pengobatan scabies',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: recordDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => recordDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Tanggal'),
                      child: Text('${recordDate.day}/${recordDate.month}/${recordDate.year}'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Medicine
                  if (selectedType != HealthRecordType.checkup)
                    TextField(
                      controller: medicineController,
                      decoration: const InputDecoration(
                        labelText: 'Obat/Vaksin',
                        hintText: 'Nama obat atau vaksin',
                      ),
                    ),
                  if (selectedType != HealthRecordType.checkup)
                    const SizedBox(height: 16),

                  // Dosage
                  if (selectedType != HealthRecordType.checkup)
                    TextField(
                      controller: dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosis',
                        hintText: '0.5 ml',
                      ),
                    ),
                  if (selectedType != HealthRecordType.checkup)
                    const SizedBox(height: 16),

                  // Cost
                  TextField(
                    controller: costController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Biaya',
                      prefixText: 'Rp ',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan',
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
                  await ref.read(healthNotifierProvider.notifier).create(
                    livestockId: selectedLivestockId,
                    type: selectedType,
                    title: titleController.text.trim(),
                    recordDate: recordDate,
                    medicine: medicineController.text.trim().isEmpty 
                        ? null 
                        : medicineController.text.trim(),
                    dosage: dosageController.text.trim().isEmpty 
                        ? null 
                        : dosageController.text.trim(),
                    cost: double.tryParse(costController.text),
                    notes: notesController.text.trim().isEmpty 
                        ? null 
                        : notesController.text.trim(),
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Catatan kesehatan ditambahkan')),
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

class _HealthCard extends StatelessWidget {
  final HealthRecord record;

  const _HealthCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColor().withAlpha(25),
          child: Text(record.type.icon),
        ),
        title: Text(record.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record.animalDisplayName != 'Unknown')
              Text(record.animalDisplayName),
            Text(
              '${record.recordDate.day}/${record.recordDate.month}/${record.recordDate.year}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: record.medicine != null 
            ? Text(record.medicine!, style: TextStyle(color: Colors.grey[600]))
            : null,
      ),
    );
  }

  Color _getColor() {
    switch (record.type) {
      case HealthRecordType.vaccination:
        return Colors.blue;
      case HealthRecordType.illness:
        return Colors.red;
      case HealthRecordType.treatment:
        return Colors.orange;
      case HealthRecordType.checkup:
        return Colors.green;
      case HealthRecordType.deworming:
        return Colors.purple;
    }
  }
}
