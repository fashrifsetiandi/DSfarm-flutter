/// Inventory Screen
/// 
/// Screen untuk melihat dan mengelola inventaris.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/inventory.dart';
import '../../../providers/inventory_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaris'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: InventoryType.values.map((type) {
            return Tab(text: type.displayName);
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: InventoryType.values.map((type) {
          return _InventoryTab(type: type);
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    final qtyController = TextEditingController(text: '0');
    final minController = TextEditingController();
    final priceController = TextEditingController();
    InventoryType selectedType = InventoryType.feed;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Tambah Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Type
                  DropdownButtonFormField<InventoryType>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Tipe'),
                    items: InventoryType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text('${type.icon} ${type.displayName}'),
                      );
                    }).toList(),
                    onChanged: (v) => setDialogState(() => selectedType = v!),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama'),
                  ),
                  const SizedBox(height: 16),

                  // Unit
                  TextField(
                    controller: unitController,
                    decoration: const InputDecoration(
                      labelText: 'Satuan',
                      hintText: 'kg, pcs, liter',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quantity
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stok Awal'),
                  ),
                  const SizedBox(height: 16),

                  // Minimum Stock
                  TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stok Minimum (Opsional)',
                      hintText: 'Alert jika stok rendah',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Harga Satuan (Opsional)',
                      prefixText: 'Rp ',
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
                  if (nameController.text.isEmpty) return;

                  Navigator.pop(context);
                  await ref.read(inventoryNotifierProvider.notifier).createItem(
                    name: nameController.text.trim(),
                    type: selectedType,
                    unit: unitController.text.trim().isEmpty 
                        ? null 
                        : unitController.text.trim(),
                    quantity: double.tryParse(qtyController.text) ?? 0,
                    minimumStock: double.tryParse(minController.text),
                    unitPrice: double.tryParse(priceController.text),
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${nameController.text} ditambahkan')),
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

class _InventoryTab extends ConsumerWidget {
  final InventoryType type;

  const _InventoryTab({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(inventoryNotifierProvider);

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        final filtered = items.where((i) => i.type == type).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(type.icon, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  'Belum ada ${type.displayName.toLowerCase()}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];
            return _InventoryCard(
              item: item,
              onTap: () => _showDetail(context, ref, item),
            );
          },
        );
      },
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref, InventoryItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(item.type.icon, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Stok Rendah!',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _DetailRow(label: 'Stok', value: item.formattedQuantity),
            if (item.minimumStock != null)
              _DetailRow(label: 'Stok Minimum', value: '${item.minimumStock} ${item.unit ?? ""}'),
            if (item.unitPrice != null)
              _DetailRow(label: 'Harga Satuan', value: 'Rp ${item.unitPrice}'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showStockDialog(context, ref, item, isAdd: false),
                    icon: const Icon(Icons.remove),
                    label: const Text('Pakai'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showStockDialog(context, ref, item, isAdd: true),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStockDialog(BuildContext context, WidgetRef ref, InventoryItem item, {required bool isAdd}) {
    final qtyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdd ? 'Tambah Stok' : 'Kurangi Stok'),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Jumlah',
            suffixText: item.unit,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = double.tryParse(qtyController.text) ?? 0;
              if (qty <= 0) return;

              Navigator.pop(context);
              Navigator.pop(context);

              if (isAdd) {
                await ref.read(inventoryNotifierProvider.notifier)
                    .addStock(item.id, qty);
              } else {
                await ref.read(inventoryNotifierProvider.notifier)
                    .useStock(item.id, qty);
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Stok ${item.name} diperbarui')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;

  const _InventoryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(item.type.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      item.formattedQuantity,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (item.isLowStock)
                Icon(Icons.warning, color: Colors.red[400]),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
