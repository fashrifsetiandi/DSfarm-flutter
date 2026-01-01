/// Housing List Screen (Grid View)
/// 
/// Screen untuk melihat kandang dalam format grid yang compact.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/housing.dart';
import '../../../providers/housing_provider.dart';
import '../../../providers/livestock_provider.dart';
import 'create_housing_screen.dart';

class HousingListScreen extends ConsumerStatefulWidget {
  const HousingListScreen({super.key});

  @override
  ConsumerState<HousingListScreen> createState() => _HousingListScreenState();
}

class _HousingListScreenState extends ConsumerState<HousingListScreen> {
  bool _isSelectMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (!_isSelectMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<Housing> housings) {
    setState(() {
      if (_selectedIds.length == housings.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(housings.map((h) => h.id));
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kandang?'),
        content: Text('Hapus ${_selectedIds.length} kandang yang dipilih?\n\nTernak di kandang tersebut akan dipindahkan ke status "Tidak ada kandang".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(housingNotifierProvider.notifier).deleteBatch(_selectedIds.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedIds.length} kandang berhasil dihapus')),
        );
        _toggleSelectMode();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final housingsAsync = ref.watch(housingNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSelectMode 
            ? Text('${_selectedIds.length} dipilih')
            : const Text('Kandang'),
        actions: [
          if (_isSelectMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Pilih Semua',
              onPressed: () => housingsAsync.whenData((h) => _selectAll(h)),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Hapus',
              onPressed: _selectedIds.isNotEmpty ? _deleteSelected : null,
            ),
          ],
          IconButton(
            icon: Icon(_isSelectMode ? Icons.close : Icons.checklist),
            tooltip: _isSelectMode ? 'Batal' : 'Pilih',
            onPressed: _toggleSelectMode,
          ),
        ],
      ),
      body: housingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (housings) => housings.isEmpty
            ? _buildEmptyState(context)
            : _buildGridView(context, housings),
      ),
      floatingActionButton: _isSelectMode ? null : FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateHousingScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Belum ada kandang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tambahkan kandang untuk mulai', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildGridView(BuildContext context, List<Housing> housings) {
    // Group by block (from code prefix, e.g., "AA-01" -> "AA")
    final grouped = <String, List<Housing>>{};
    for (final h in housings) {
      final parts = h.code.split('-');
      final block = parts.length >= 2 ? parts.first : 'Lainnya';
      grouped.putIfAbsent(block, () => []).add(h);
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(housingNotifierProvider),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final block = grouped.keys.elementAt(index);
          final items = grouped[block]!..sort((a, b) => a.code.compareTo(b.code));
          final available = items.where((h) => (h.currentOccupancy ?? 0) < h.capacity).length;

          return _BlockSection(
            block: block,
            housings: items,
            availableCount: available,
            isSelectMode: _isSelectMode,
            selectedIds: _selectedIds,
            onHousingTap: (h) => _isSelectMode 
                ? _toggleSelection(h.id)
                : _showHousingDetail(context, h),
            onLongPress: (h) {
              if (!_isSelectMode) {
                _toggleSelectMode();
                _toggleSelection(h.id);
              }
            },
          );
        },
      ),
    );
  }

  void _showHousingDetail(BuildContext context, Housing housing) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _HousingDetailSheet(housing: housing),
    );
  }
}

class _BlockSection extends StatelessWidget {
  final String block;
  final List<Housing> housings;
  final int availableCount;
  final Function(Housing) onHousingTap;
  final bool isSelectMode;
  final Set<String> selectedIds;
  final Function(Housing)? onLongPress;

  const _BlockSection({
    required this.block,
    required this.housings,
    required this.availableCount,
    required this.onHousingTap,
    this.isSelectMode = false,
    this.selectedIds = const {},
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Block name + levels + count
            Row(
              children: [
                Text(
                  '${housings.length}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Blok $block',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$availableCount',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                    Text('tersedia', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Grid of housing cards
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: housings.map((h) => _HousingCard(
                housing: h,
                isSelected: selectedIds.contains(h.id),
                isSelectMode: isSelectMode,
                onTap: () => onHousingTap(h),
                onLongPress: onLongPress != null ? () => onLongPress!(h) : null,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HousingCard extends StatelessWidget {
  final Housing housing;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isSelectMode;
  final VoidCallback? onLongPress;

  const _HousingCard({
    required this.housing, 
    required this.onTap,
    this.isSelected = false,
    this.isSelectMode = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 72,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withAlpha(30) : Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[600]!, 
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.home, size: 16, color: Colors.grey[400]),
                    const SizedBox(height: 2),
                    Text(
                      housing.code,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[300],
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 8, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HousingDetailSheet extends ConsumerWidget {
  final Housing housing;

  const _HousingDetailSheet({required this.housing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get livestock in this housing
    final livestockAsync = ref.watch(livestockNotifierProvider);
    final occupants = livestockAsync.valueOrNull
        ?.where((l) => l.housingId == housing.id)
        .toList() ?? [];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - grey theme
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: Icon(Icons.home_work, color: Colors.grey[400]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(housing.code, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Kapasitas: ${housing.currentOccupancy ?? 0}/${housing.capacity}'),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                onPressed: () => _showDeleteConfirmation(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Location info row - grey theme
          if (housing.level != null && housing.level!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Text('Lokasi: ', style: TextStyle(color: Colors.grey[500])),
                  Text(
                    housing.level!,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[300]),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          
          // Occupants
          Text(
            'Ternak di Kandang Ini:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          if (occupants.isEmpty)
            Text('Kosong', style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic))
          else
            ...occupants.map((l) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: l.gender.value == 'female' ? Colors.pink[50] : Colors.blue[50],
                child: Text(l.gender.value == 'female' ? '♀' : '♂'),
              ),
              title: Text(l.code),
              subtitle: l.name != null ? Text(l.name!) : null,
              trailing: Text(l.status),
            )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kandang?'),
        content: Text(
          'Apakah yakin ingin menghapus kandang ${housing.code}?\n\n'
          'Ternak di dalam kandang ini akan dipindahkan ke status "Tidak ada kandang".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              
              await ref.read(housingNotifierProvider.notifier).delete(housing.id);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Kandang ${housing.code} berhasil dihapus')),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
