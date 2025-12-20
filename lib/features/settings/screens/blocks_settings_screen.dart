/// Blocks Settings Screen
/// 
/// CRUD screen for managing blocks.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/block.dart';
import '../../../providers/block_provider.dart';

class BlocksSettingsScreen extends ConsumerWidget {
  const BlocksSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocksAsync = ref.watch(blockNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Block'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: blocksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (blocks) {
          if (blocks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.apartment, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada block',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(context, ref, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Block'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: blocks.length,
            itemBuilder: (context, index) {
              final block = blocks[index];
              return _BlockTile(
                block: block,
                onEdit: () => _showAddEditDialog(context, ref, block),
                onDelete: () => _confirmDelete(context, ref, block),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref, Block? block) {
    final codeController = TextEditingController(text: block?.code ?? '');
    final nameController = TextEditingController(text: block?.name ?? '');
    final isEditing = block != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Block' : 'Tambah Block'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Kode *',
                hintText: 'BLOCK-A, GEDUNG-1',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama',
                hintText: 'Gedung Utama, Kandang Anakan',
                prefixIcon: Icon(Icons.apartment),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              final name = nameController.text.trim();
              
              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kode wajib diisi')),
                );
                return;
              }

              Navigator.pop(context);

              try {
                if (isEditing) {
                  await ref.read(blockNotifierProvider.notifier).update(
                    id: block.id,
                    code: code,
                    name: name.isEmpty ? null : name,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Block $code berhasil diupdate')),
                    );
                  }
                } else {
                  await ref.read(blockNotifierProvider.notifier).create(
                    code: code,
                    name: name.isEmpty ? null : name,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Block $code berhasil ditambahkan')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Block block) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Block?'),
        content: Text('Block "${block.displayName}" akan dihapus. Kandang di block ini tidak akan terhapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(blockNotifierProvider.notifier).delete(block.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Block ${block.code} dihapus')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
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

class _BlockTile extends StatelessWidget {
  final Block block;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BlockTile({
    required this.block,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: const Icon(Icons.apartment),
      ),
      title: Text(block.code),
      subtitle: Text(block.name ?? 'Tidak ada nama'),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') onEdit();
          if (value == 'delete') onDelete();
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          const PopupMenuItem(value: 'delete', child: Text('Hapus')),
        ],
      ),
    );
  }
}
