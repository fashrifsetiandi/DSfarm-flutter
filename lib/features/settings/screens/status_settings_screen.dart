/// Status Settings Screen
/// 
/// CRUD screen for managing livestock statuses.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/livestock_status_model.dart';
import '../../../../providers/status_provider.dart';
import '../../../../providers/farm_provider.dart';

class StatusSettingsScreen extends ConsumerWidget {
  const StatusSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmId = ref.watch(currentFarmProvider)?.id ?? '';
    final statusesAsync = ref.watch(statusNotifierProvider(farmId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Status'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, ref, farmId, null),
        child: const Icon(Icons.add),
      ),
      body: statusesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (statuses) {
          if (statuses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada status',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(context, ref, farmId, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Status'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: statuses.length,
            itemBuilder: (context, index) {
              final status = statuses[index];
              return _StatusTile(
                status: status,
                onEdit: () => _showAddEditDialog(context, ref, farmId, status),
                onDelete: () => _confirmDelete(context, ref, farmId, status),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref, String farmId, LivestockStatusModel? status) {
    final nameController = TextEditingController(text: status?.name ?? '');
    final codeController = TextEditingController(text: status?.code ?? '');
    // Pre-filled or default
    Color selectedColor = status != null 
        ? (Color(int.tryParse(status.colorHex.replaceFirst('#', '0xFF')) ?? 0xFF808080))
        : Colors.green;
    String selectedType = status?.type ?? 'active';
    String selectedGender = status?.validForGender ?? 'both';
    
    // Simple color palette
    final List<Color> colors = [
      Colors.green, Colors.blue, Colors.purple, Colors.pink, Colors.red, Colors.orange, Colors.grey, Colors.black
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(status == null ? 'Tambah Status' : 'Edit Status'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Kode (Unik, huruf kecil)', hintText: 'siap_kawin'),
                  textCapitalization: TextCapitalization.none,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Tampilan'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                
                // Color Picker
                const Text('Warna Label', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: colors.map((c) => GestureDetector(
                    onTap: () => setState(() => selectedColor = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: selectedColor == c ? Border.all(width: 2, color: Colors.black) : null,
                      ),
                      child: selectedColor == c ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),

                // Type Dropdown
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Tipe'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active (Di Kandang)')),
                    DropdownMenuItem(value: 'sold', child: Text('Sold (Terjual)')),
                    DropdownMenuItem(value: 'deceased', child: Text('Deceased (Mati)')),
                  ],
                  onChanged: (v) => setState(() => selectedType = v!),
                ),
                const SizedBox(height: 12),

                // Gender Dropdown
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(labelText: 'Berlaku Untuk'),
                  items: const [
                    DropdownMenuItem(value: 'female', child: Text('Betina Only')),
                    DropdownMenuItem(value: 'male', child: Text('Pejantan Only')),
                    DropdownMenuItem(value: 'both', child: Text('Semua Gender')),
                  ],
                  onChanged: (v) => setState(() => selectedGender = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final code = codeController.text.trim();
                final name = nameController.text.trim();
                if (code.isEmpty || name.isEmpty) return;

                final colorHex = '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';

                final newStatus = LivestockStatusModel(
                  id: status?.id ?? '', // ID handled by DB for new items usually, but we need to pass model
                  code: code,
                  name: name,
                  colorHex: colorHex,
                  type: selectedType,
                  validForGender: selectedGender,
                  sortOrder: status?.sortOrder ?? 0, // Should implement proper sorting later
                );

                try {
                  if (status == null) {
                    await ref.read(statusNotifierProvider(farmId).notifier).create(newStatus);
                  } else {
                    await ref.read(statusNotifierProvider(farmId).notifier).update(newStatus);
                  }
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  // Show error
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String farmId, LivestockStatusModel status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Status?'),
        content: Text('Status "${status.name}" akan dihapus. Pastikan tidak ada ternak yang menggunakan status ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(statusNotifierProvider(farmId).notifier).delete(status.id);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                // Show error
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final LivestockStatusModel status;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StatusTile({required this.status, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.tryParse(status.colorHex.replaceFirst('#', '0xFF')) ?? 0xFF808080);
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        radius: 12,
      ),
      title: Text(status.name),
      subtitle: Text('${status.code} • ${status.validForGender}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: onDelete),
        ],
      ),
    );
  }
}
