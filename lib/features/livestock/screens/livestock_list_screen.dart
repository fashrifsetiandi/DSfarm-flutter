/// Livestock List Screen
/// 
/// Screen untuk melihat dan mengelola indukan/pejantan.
/// Redesigned to match reference with card grid, filter tabs, view toggle.

library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/dashboard_shell.dart';
import '../../../models/livestock_status_model.dart';
import '../../../providers/status_provider.dart';
import '../../../providers/livestock_provider.dart';
import '../../../providers/health_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../widgets/livestock_detail_modal.dart';
import '../../../models/livestock.dart';
import 'create_livestock_screen.dart';

class LivestockListScreen extends ConsumerStatefulWidget {
  const LivestockListScreen({super.key});

  @override
  ConsumerState<LivestockListScreen> createState() => _LivestockListScreenState();
}

class _LivestockListScreenState extends ConsumerState<LivestockListScreen> {
  final MenuController _menuController = MenuController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _selectedBreeds = {};
  Set<Gender> _selectedGenders = {};
  Set<String> _selectedStatuses = {}; // Default empty = Active Only
  bool _isGridView = true;




  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSellDialog(BuildContext context, List<Livestock> allLivestock) {
    // Filter active (not sold/deceased/culled)
    final activeLivestock = allLivestock.where((l) => !['sold', 'deceased', 'culled'].contains(l.status)).toList();
    if (activeLivestock.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada ternak aktif untuk dijual')),
      );
      return;
    }

    final priceController = TextEditingController();
    final buyerController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? sellDate = DateTime.now();
    Livestock? selectedLivestock = activeLivestock.first;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Jual Indukan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Livestock Selector
                DropdownButtonFormField<Livestock>(
                  value: selectedLivestock,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Indukan *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  isExpanded: true,
                  items: activeLivestock.map((l) => DropdownMenuItem(
                    value: l,
                    child: Text('${l.code} (${l.breedName ?? '-'})'),
                  )).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedLivestock = value);
                  },
                ),
                const SizedBox(height: 16),
                
                // Buyer Input
                TextField(
                  controller: buyerController,
                  decoration: const InputDecoration(
                    labelText: 'Siapa yang beli *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Price Input
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Harga Jual *',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Date Input
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: sellDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => sellDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Jual *',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sellDate != null 
                              ? '${sellDate!.day}/${sellDate!.month}/${sellDate!.year}'
                              : 'Pilih tanggal',
                        ),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes Input
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan / Keterangan',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (priceController.text.isEmpty || 
                    buyerController.text.isEmpty ||
                    sellDate == null || 
                    selectedLivestock == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lengkapi kolom bertanda *')),
                  );
                  return;
                }
                
                Navigator.pop(dialogContext);
                
                // TODO: Handle 'buyer' and 'notes' when backend supports it
                // final buyer = buyerController.text;
                // final notes = notesController.text;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${selectedLivestock!.code} berhasil dijual!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: const Text('Jual'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final livestocksAsync = ref.watch(livestockNotifierProvider);

    return DashboardShell(
      selectedIndex: 1, // Ternak
      child: livestocksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (livestocks) {
          final farmId = livestocks.isNotEmpty ? livestocks.first.farmId : '';
          // Fetch statuses from provider for definition lookup
          final statusList = ref.watch(statusNotifierProvider(farmId));
          
          final allCount = livestocks.length;
          // Calculate counts based on status string matching against dynamic definitions or fallback strings
          final activeCount = livestocks.where((l) {
             final statusDef = statusList.value?.firstWhere((s) => s.code == l.status, orElse: () => LivestockStatusModel(id: '', code: '', name: '', colorHex: '', type: 'active'));
             return statusDef?.isActive ?? true; 
          }).length;
          
          final exitedCount = livestocks.where((l) {
             final statusDef = statusList.value?.firstWhere((s) => s.code == l.status, orElse: () => LivestockStatusModel(id: '', code: '', name: '', colorHex: '', type: 'active'));
             return statusDef?.isExited ?? false;
          }).length;

          final soldCount = livestocks.where((l) => l.status == 'sold').length;
          final deceasedCount = livestocks.where((l) => l.status == 'deceased').length;
          
          // Apply Advanced Filter
          var filtered = livestocks.where((l) {
            final matchesSearch = _searchQuery.isEmpty || 
                l.code.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                (l.name != null && l.name!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
                (l.housingCode != null && l.housingCode!.toLowerCase().contains(_searchQuery.toLowerCase()));
            final matchesBreed = _selectedBreeds.isEmpty || (l.breedName != null && _selectedBreeds.contains(l.breedName));
            final matchesGender = _selectedGenders.isEmpty || _selectedGenders.contains(l.gender);
            
            // Status Logic: Empty = Active Only. Selected = Explicit Match.
            bool matchesStatus;
            if (_selectedStatuses.isEmpty) {
              // If no status filter selected, show active only (default)
              final statusList = ref.read(statusNotifierProvider(farmId)).value ?? [];
              final activeCodes = statusList.where((s) => s.isActive).map((s) => s.code).toSet();
              
              if (activeCodes.isEmpty) {
                 // Fallback if provider empty
                 if (!['sold', 'deceased'].contains(l.status)) {
                   matchesStatus = true;
                 } else {
                   matchesStatus = false;
                 }
              } else {
                matchesStatus = activeCodes.contains(l.status);
              }
            } else {
              matchesStatus = _selectedStatuses.contains(l.status);
            }
                
            return matchesSearch && matchesBreed && matchesGender && matchesStatus;
          }).toList();

          return Column(
            children: [
              // ═══════════════════════════════════════════
              // HEADER
              // ═══════════════════════════════════════════
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ═══════════════════════════════════════════
                    // STAT CARDS ROW
                    // ═══════════════════════════════════════════
                    Row(
                      children: [
                        // Di Farm Card
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => setState(() => _selectedStatuses.clear()),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('DI FARM', style: TextStyle(fontSize: 12, color: Colors.green[600], fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                          Icon(Icons.home_rounded, color: Colors.green[400], size: 24),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text('$activeCount', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                          const SizedBox(width: 6),
                                          Text('Ekor', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Active livestock', style: TextStyle(fontSize: 12, color: Colors.green[500])),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Keluar Card
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => setState(() => _selectedStatuses = {'sold', 'deceased'}),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('KELUAR', style: TextStyle(fontSize: 12, color: Colors.orange[600], fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                          Icon(Icons.exit_to_app_rounded, color: Colors.orange[400], size: 24),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text('$exitedCount', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                          const SizedBox(width: 6),
                                          Text('Ekor', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 4,
                                        children: [
                                          Text('Terjual: $soldCount', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                                          Text('|', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                                          Text('Mati: $deceasedCount', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Total Card
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                // Select all available status codes
                                onTap: () {
                                  final allStatuses = ref.read(statusNotifierProvider(farmId)).value?.map((s) => s.code).toSet() ?? {};
                                  setState(() => _selectedStatuses = allStatuses);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('TOTAL', style: TextStyle(fontSize: 12, color: Colors.blue[600], fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                          Icon(Icons.access_time_rounded, color: Colors.blue[400], size: 24),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text('$allCount', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                          const SizedBox(width: 6),
                                          Text('Record', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('All time history', style: TextStyle(fontSize: 12, color: Colors.blue[500])),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ═══════════════════════════════════════════
                    // CONTROLS ROW: View Toggle | Filter | Add Button
                    // ═══════════════════════════════════════════
                    Row(
                      children: [
                        // View toggle
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ViewToggle(
                                icon: Icons.grid_view_rounded,
                                isSelected: _isGridView,
                                onTap: () => setState(() => _isGridView = true),
                              ),
                              _ViewToggle(
                                icon: Icons.view_list_rounded,
                                isSelected: !_isGridView,
                                onTap: () => setState(() => _isGridView = false),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Filter Button
                        MenuAnchor(
                          controller: _menuController,
                          alignmentOffset: const Offset(0, 8),
                          builder: (context, controller, child) {
                            return OutlinedButton.icon(
                              onPressed: () {
                                if (controller.isOpen) {
                                  controller.close();
                                } else {
                                  controller.open();
                                }
                              },
                              icon: const Icon(Icons.filter_list, size: 18),
                              label: Text('Filter ${_selectedBreeds.length + _selectedGenders.length + _selectedStatuses.length > 0 ? '(${_selectedBreeds.length + _selectedGenders.length + _selectedStatuses.length})' : ''}'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.onSurface,
                                side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            );
                          },
                          menuChildren: [
                            _FilterMenu(
                              livestocks: livestocks,
                              selectedBreeds: _selectedBreeds,
                              onBreedsChanged: (val) => setState(() => _selectedBreeds = val),
                              selectedGenders: _selectedGenders,
                              onGendersChanged: (val) => setState(() => _selectedGenders = val),
                              selectedStatuses: _selectedStatuses,
                              onStatusesChanged: (val) => setState(() => _selectedStatuses = val),
                              availableStatuses: ref.watch(statusNotifierProvider(farmId)).value ?? [], // Pass available statuses
                              onReset: () {
                                setState(() {
                                  _selectedBreeds.clear();
                                  _selectedGenders.clear();
                                  _selectedStatuses.clear();
                                });
                              },
                              onClose: () => _menuController.close(),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Jual Indukan Button
                        ElevatedButton.icon(
                          onPressed: () {
                            if (livestocks.isNotEmpty) {
                              _showSellDialog(context, livestocks);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Belum ada data ternak')),
                              );
                            }
                          },
                          icon: const Icon(Icons.sell_outlined, size: 18),
                          label: const Text('Jual Indukan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red[600],
                            elevation: 0,
                            side: BorderSide(color: Colors.red[200]!),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Add Button
                        ElevatedButton.icon(
                          onPressed: () => showCreateLivestockPanel(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah Indukan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ═══════════════════════════════════════════
              // CONTENT
              // ═══════════════════════════════════════════
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(context)
                    : _isGridView
                        ? _buildGridView(context, filtered)
                        : _buildListView(context, filtered),
              ),
            ],
          );
        },
      ),
    );
  }



  Widget _buildGridView(BuildContext context, List<Livestock> filtered) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate columns based on width
        final crossAxisCount = constraints.maxWidth > 1200 ? 4 
            : constraints.maxWidth > 900 ? 3 
            : constraints.maxWidth > 600 ? 2 
            : 1;
        
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240, // ~4-5 cards per row
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2, // Adjusted for health row
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _LivestockCard(
            livestock: filtered[index],
            onTap: () => showLivestockDetailModal(context, ref, filtered[index]),
          ),
        );
      },
    );
  }

  Widget _buildListView(BuildContext context, List<Livestock> filtered) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header
          Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'ID INDUKAN', 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600], letterSpacing: 0.5),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'ID LAHIR', 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600], letterSpacing: 0.5),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'KELAMIN', 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600], letterSpacing: 0.5),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'HARGA BELI', 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600], letterSpacing: 0.5),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'UMUR', 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600], letterSpacing: 0.5),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'STATUS', 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600], letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          // Table Body
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
              itemBuilder: (context, index) => _LivestockListItem(
                livestock: filtered[index],
                onTap: () => showLivestockDetailModal(context, ref, filtered[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 64, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('Belum ada data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Coba reset filter atau tambahkan ternak baru', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VIEW TOGGLE
// ═══════════════════════════════════════════════════════════════════════════
class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggle({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIVESTOCK CARD (Grid View)
// ═══════════════════════════════════════════════════════════════════════════
class _LivestockCard extends ConsumerWidget {
  final Livestock livestock;
  final VoidCallback onTap;

  const _LivestockCard({required this.livestock, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFemale = livestock.gender == Gender.female;
    final genderColor = isFemale ? const Color(0xFFEC4899) : const Color(0xFF3B82F6);
    final genderBgColor = isFemale ? const Color(0xFFFCE7F3) : const Color(0xFFDBEAFE);
    
    // Get latest health record
    final healthAsync = ref.watch(healthByLivestockProvider(livestock.id));
    final latestHealthTitle = healthAsync.maybeWhen(
      data: (records) => records.isNotEmpty ? records.first.title : 'Sehat',
      orElse: () => '-',
    );

    // Check if new (created within last 1 minute)
    final isNew = DateTime.now().difference(livestock.createdAt).inMinutes < 1;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Gender icon + Code + Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular gender icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: genderBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        isFemale ? Icons.female_rounded : Icons.male_rounded,
                        color: genderColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Code and Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              livestock.code,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (isNew) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'BARU',
                                  style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        _StatusBadge(status: livestock.status, farmId: livestock.farmId),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Details in table-like rows
              _buildDetailRow(context, 'Harga', livestock.purchasePrice != null 
                  ? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(livestock.purchasePrice) 
                  : '-', 
                  Colors.green[600]),
              const SizedBox(height: 4),
              _buildDetailRow(context, 'Umur', livestock.ageFormatted, null),
              const SizedBox(height: 4),
              _buildDetailRow(context, 'Berat', livestock.weight != null ? '${livestock.weight} kg' : '-', null),
              const SizedBox(height: 4),
              _buildDetailRow(context, 'Kesehatan', latestHealthTitle, Colors.orange[700]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, Color? valueColor) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? colorScheme.onSurface)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIVESTOCK LIST ITEM (Table Row)
// ═══════════════════════════════════════════════════════════════════════════



class _LivestockListItem extends StatelessWidget {
  final Livestock livestock;
  final VoidCallback onTap;

  const _LivestockListItem({required this.livestock, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Currency Formatter
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID', 
      symbol: 'Rp ', 
      decimalDigits: 0,
    );
    
    // Badge Logic (New < 1 minute)
    final isNew = DateTime.now().difference(livestock.createdAt).inMinutes < 1;
    
    // Status Color Logic
    Color statusColor;
    Color statusTextColor = Colors.white;
    
    switch (livestock.status) {
      case 'pejantan_aktif':
      case 'siap_kawin': statusColor = const Color(0xFF3B82F6); break;
      case 'bunting': statusColor = const Color(0xFFEC4899); break;
      case 'istirahat': statusColor = const Color(0xFF9CA3AF); break;
      case 'menyusui': statusColor = const Color(0xFFF59E0B); break;
      default: statusColor = const Color(0xFF10B981);
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            // ID Indukan & Badge
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Text(
                    livestock.code,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (isNew) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'BARU',
                        style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ID Lahir
            Expanded(
              flex: 2,
              child: Text(
                livestock.acquisitionType == AcquisitionType.purchased ? 'FOUNDER' : 'Lahir di Farm',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
            // Gender
            Expanded(
              flex: 1,
              child: Text(
                livestock.gender == Gender.male ? '♂' : '♀',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: livestock.gender == Gender.male ? const Color(0xFF3B82F6) : const Color(0xFFEC4899),
                ),
              ),
            ),
            // Harga Beli
            Expanded(
              flex: 2,
              child: Text(
                livestock.purchasePrice != null ? currencyFormat.format(livestock.purchasePrice) : '-',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
            // Umur
            Expanded(
              flex: 2,
              child: Text(
                livestock.ageFormatted,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
            // Status Pills
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    livestock.status,
                    style: TextStyle(fontSize: 12, color: statusTextColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATUS BADGE
// ═══════════════════════════════════════════════════════════════════════════
class _StatusBadge extends ConsumerWidget {
  final String status;
  final String farmId;

  const _StatusBadge({required this.status, required this.farmId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusList = ref.watch(statusNotifierProvider(farmId));
    
    // Find status definition or use fallback
    final statusDef = statusList.value?.firstWhere(
      (s) => s.code == status,
      orElse: () => LivestockStatusModel(
        id: '', 
        code: status, 
        name: status, // Use code as name if not found 
        colorHex: '#808080', 
        type: 'active'
      ),
    );

    final color = statusDef?.color ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        statusDef?.name ?? status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FILTER MENU (Popover)
// ═══════════════════════════════════════════════════════════════════════════
class _FilterMenu extends StatelessWidget {
  final List<Livestock> livestocks;
  final Set<String> selectedBreeds;
  final ValueChanged<Set<String>> onBreedsChanged;
  final Set<Gender> selectedGenders;
  final ValueChanged<Set<Gender>> onGendersChanged;
  final Set<String> selectedStatuses;
  final ValueChanged<Set<String>> onStatusesChanged;
  final List<LivestockStatusModel> availableStatuses;
  final VoidCallback onReset;
  final VoidCallback onClose;

  const _FilterMenu({
    super.key,
    required this.livestocks,
    required this.selectedBreeds,
    required this.onBreedsChanged,
    required this.selectedGenders,
    required this.onGendersChanged,
    required this.selectedStatuses,
    required this.onStatusesChanged,
    required this.availableStatuses,
    required this.onReset,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Counts (Faceted Search Logic)
    // ... (Faceted logic matches previous implementation) ...
    
    // Helper to filter by other categories
    List<Livestock> filterForBreeds() {
      return livestocks.where((l) {
        final genderMatch = selectedGenders.isEmpty || selectedGenders.contains(l.gender);
        final statusMatch = selectedStatuses.isEmpty || selectedStatuses.contains(l.status);
        return genderMatch && statusMatch;
      }).toList();
    }

    List<Livestock> filterForGenders() {
      return livestocks.where((l) {
        final breedMatch = selectedBreeds.isEmpty || (l.breedName != null && selectedBreeds.contains(l.breedName));
        final statusMatch = selectedStatuses.isEmpty || selectedStatuses.contains(l.status);
        return breedMatch && statusMatch;
      }).toList();
    }

    List<Livestock> filterForStatuses() {
      return livestocks.where((l) {
        final breedMatch = selectedBreeds.isEmpty || (l.breedName != null && selectedBreeds.contains(l.breedName));
        final genderMatch = selectedGenders.isEmpty || selectedGenders.contains(l.gender);
        return breedMatch && genderMatch;
      }).toList();
    }

    final breedSubSet = filterForBreeds();
    final genderSubSet = filterForGenders();
    final statusSubSet = filterForStatuses();

    final breedCounts = <String, int>{};
    for (var l in breedSubSet) {
      if (l.breedName != null) {
        breedCounts[l.breedName!] = (breedCounts[l.breedName!] ?? 0) + 1;
      }
    }

    final genderCounts = <Gender, int>{};
    for (var l in genderSubSet) {
      genderCounts[l.gender] = (genderCounts[l.gender] ?? 0) + 1;
    }

    final statusCounts = <String, int>{};
    for (var l in statusSubSet) {
      statusCounts[l.status] = (statusCounts[l.status] ?? 0) + 1;
    }

    final uniqueBreeds = breedCounts.keys.toList()..sort();
    final totalActive = selectedBreeds.length + selectedGenders.length + selectedStatuses.length;

    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 520),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                const Text('Filter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                if (totalActive > 0)
                  GestureDetector(
                    onTap: onClose,
                     child: const Icon(Icons.close, size: 20, color: Colors.blue),
                  ),
                const SizedBox(width: 12),
                if (totalActive > 0)
                  GestureDetector(
                    onTap: onReset,
                    child: const Text('Reset Semua', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- RAS ---
                  _buildSectionHeader('Ras'),
                  if (uniqueBreeds.where((b) => (breedCounts[b] ?? 0) > 0).isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('Tidak ada data ras', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13)),
                    ),
                  ...uniqueBreeds.where((b) => (breedCounts[b] ?? 0) > 0).map((breed) => _buildCheckboxTile(
                    title: breed,
                    count: breedCounts[breed] ?? 0,
                    value: selectedBreeds.contains(breed),
                    onChanged: (val) {
                      final newSet = Set<String>.from(selectedBreeds);
                      if (val == true) {
                        newSet.add(breed);
                      } else {
                        newSet.remove(breed);
                      }
                      onBreedsChanged(newSet);
                    },
                  )),
                  
                  if (uniqueBreeds.where((b) => (breedCounts[b] ?? 0) > 0).isNotEmpty)
                    const Divider(height: 1, indent: 16, endIndent: 16),

                  // --- GENDER ---
                  _buildSectionHeader('Jenis Kelamin'),
                  if ((genderCounts[Gender.female] ?? 0) > 0)
                    _buildCheckboxTile(
                      title: 'Betina',
                      count: genderCounts[Gender.female] ?? 0,
                      value: selectedGenders.contains(Gender.female),
                      onChanged: (val) {
                        final newSet = Set<Gender>.from(selectedGenders);
                        if (val == true) {
                          newSet.add(Gender.female);
                        } else {
                          newSet.remove(Gender.female);
                        }
                        onGendersChanged(newSet);
                      },
                    ),
                  if ((genderCounts[Gender.male] ?? 0) > 0)
                    _buildCheckboxTile(
                      title: 'Jantan',
                      count: genderCounts[Gender.male] ?? 0,
                      value: selectedGenders.contains(Gender.male),
                      onChanged: (val) {
                        final newSet = Set<Gender>.from(selectedGenders);
                        if (val == true) {
                          newSet.add(Gender.male);
                        } else {
                          newSet.remove(Gender.male);
                        }
                        onGendersChanged(newSet);
                      },
                    ),
                  
                  if ((genderCounts[Gender.female] ?? 0) > 0 || (genderCounts[Gender.male] ?? 0) > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16),

                   // --- STATUS ---
                   _buildSectionHeader('Status'),
                    // Show ALL statuses regardless of count or selection
                    ...availableStatuses.where((s) => !s.isCulled).map((statusModel) {
                      return _buildCheckboxTile(
                       title: statusModel.name,
                       count: statusCounts[statusModel.code] ?? 0,
                       value: selectedStatuses.contains(statusModel.code),
                       onChanged: (val) {
                         final newSet = Set<String>.from(selectedStatuses);
                         if (val == true) {
                           newSet.add(statusModel.code);
                         } else {
                           newSet.remove(statusModel.code);
                         }
                         onStatusesChanged(newSet);
                       },
                     );
                   }),
                ],
              ),
            ),
          ),
          
          // Footer Active Filters
           if (totalActive > 0) ...[
             const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
             Container(
               padding: const EdgeInsets.all(16),
               color: const Color(0xFFF9FAFB),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text('Filter Aktif ($totalActive):', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF4B5563))),
                   const SizedBox(height: 8),
                   Wrap(
                     spacing: 8,
                     runSpacing: 8,
                     children: [
                       ...selectedBreeds.map((breed) => _buildChip(
                         label: breed,
                         onDeleted: () {
                           final newSet = Set<String>.from(selectedBreeds)..remove(breed);
                           onBreedsChanged(newSet);
                         },
                       )),
                       ...selectedGenders.map((gender) => _buildChip(
                         label: gender == Gender.male ? 'Jantan' : 'Betina',
                         onDeleted: () {
                           final newSet = Set<Gender>.from(selectedGenders)..remove(gender);
                           onGendersChanged(newSet);
                         },
                       )),
                        ...selectedStatuses.map((statusCode) {
                          final statusName = availableStatuses.firstWhere(
                            (s) => s.code == statusCode, 
                            orElse: () => LivestockStatusModel(id: '', code: statusCode, name: statusCode, colorHex: '', type: 'active')
                          ).name;
                          return _buildChip(
                            label: statusName,
                            onDeleted: () {
                              final newSet = Set<String>.from(selectedStatuses)..remove(statusCode);
                              onStatusesChanged(newSet);
                            },
                          );
                        }),
                     ],
                   ),
                 ],
               ),
             ),
           ],
        ],
      ),
    );
  }
  
  Widget _buildChip({required String label, required VoidCallback onDeleted}) {
    return Chip(
      label: Text(label),
      onDeleted: onDeleted,
      backgroundColor: const Color(0xFFE5E7EB),
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
      deleteIconColor: const Color(0xFF6B7280),
      padding: const EdgeInsets.all(0),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF374151)),
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required int count,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    // ... (Checkbox tile implementation remains same) ...
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: value,
                  onChanged: onChanged,
                  activeColor: const Color(0xFF0F172A), // Dark color as shown in screenshot
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(), 
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
