/// Livestock Detail Modal
/// 
/// Modal bottom sheet dengan tabs untuk menampilkan detail ternak.

library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/breeding_record.dart';
import '../../../models/health_record.dart';
import '../../../models/livestock_status_model.dart';
import '../../../providers/status_provider.dart';
import '../../../models/livestock.dart';
import '../../../models/weight_record.dart';
import '../../../providers/breeding_provider.dart';
import '../../../providers/farm_provider.dart';
import '../../../providers/health_provider.dart';
import '../../../providers/livestock_provider.dart';
import '../../../providers/offspring_provider.dart';
import '../../../providers/weight_record_provider.dart';
import '../../../core/utils/currency_formatter.dart';

/// Helper function to show livestock detail modal
void showLivestockDetailModal(
  BuildContext context, 
  WidgetRef ref, 
  Livestock livestock,
) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Livestock Detail',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: _LivestockDetailPanel(
            livestock: livestock,
            onDelete: () async {
              Navigator.pop(context);
              await _confirmDelete(context, ref, livestock);
            },
            onEdit: () {
              Navigator.pop(context);
              // TODO: Navigate to edit screen
            },
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final slideAnimation = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      
      return SlideTransition(position: slideAnimation, child: child);
    },
  );
}

Future<void> _confirmDelete(
  BuildContext context, 
  WidgetRef ref, 
  Livestock livestock,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Hapus Indukan?'),
      content: Text('Apakah Anda yakin ingin menghapus ${livestock.displayName}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );

  if (result == true && context.mounted) {
    await ref.read(livestockNotifierProvider.notifier).delete(livestock.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${livestock.displayName} dihapus')),
      );
    }
  }
}

class _LivestockDetailPanel extends StatefulWidget {
  final Livestock livestock;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _LivestockDetailPanel({
    required this.livestock,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_LivestockDetailPanel> createState() => _LivestockDetailPanelState();
}

class _LivestockDetailPanelState extends State<_LivestockDetailPanel> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _tabCount;

  @override
  void initState() {
    super.initState();
    // Pejantan tidak memiliki tab Breeding
    _tabCount = widget.livestock.isFemale ? 4 : 3;
    _tabController = TabController(length: _tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSellDialog(BuildContext context) {
    final priceController = TextEditingController();
    DateTime? sellDate = DateTime.now();
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Jual Indukan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jual ${widget.livestock.code}?',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (priceController.text.isEmpty || sellDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lengkapi semua data')),
                  );
                  return;
                }
                
                Navigator.pop(dialogContext);
                Navigator.pop(context); // Close detail panel
                
                // Update livestock status to sold
                // Note: This requires updating the notifier to support status change
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${widget.livestock.code} berhasil dijual dengan harga Rp ${priceController.text}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: const Text('Jual'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSilsilahPopup(BuildContext context, Livestock livestock) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.account_tree, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 12),
                  const Text(
                    'Silsilah',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Current livestock
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4CAF50)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            livestock.genderIcon,
                            style: TextStyle(
                              fontSize: 24,
                              color: livestock.isFemale 
                                  ? const Color(0xFFE91E63) 
                                  : const Color(0xFF2196F3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  livestock.code,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (livestock.breedName != null)
                                  Text(
                                    livestock.breedName!,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'SAAT INI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Parents
                    Row(
                      children: [
                        // Mother
                        Expanded(
                          child: _buildParentCard(
                            icon: '♀',
                            iconColor: const Color(0xFFE91E63),
                            label: 'Induk Betina',
                            code: livestock.motherCode,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Father
                        Expanded(
                          child: _buildParentCard(
                            icon: '♂',
                            iconColor: const Color(0xFF2196F3),
                            label: 'Induk Jantan',
                            code: livestock.fatherCode,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentCard({
    required String icon,
    required Color iconColor,
    required String label,
    required String? code,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: TextStyle(fontSize: 28, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            code ?? '-',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final livestock = widget.livestock;
    final genderColor = livestock.isFemale 
        ? const Color(0xFFE91E63) 
        : const Color(0xFF2196F3);
    final screenWidth = MediaQuery.of(context).size.width;
    // Panel width: 400px on desktop, 85% on mobile
    final panelWidth = screenWidth > 600 ? 600.0 : screenWidth * 0.95;

    return Container(
      width: panelWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Close button row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detail Ternak',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 22),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ),
          ),
          // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: genderColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        livestock.genderIcon,
                        style: TextStyle(
                          fontSize: 24,
                          color: genderColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          livestock.code,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: genderColor,
                          ),
                        ),
                        if (livestock.breedName != null)
                          Text(
                            livestock.breedName!,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: widget.onEdit,
                  ),

                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: const Color(0xFF4CAF50),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: const Color(0xFF4CAF50),
                indicatorWeight: 2,
                tabs: [
                  const Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 18),
                        SizedBox(width: 6),
                        Text('Informasi'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.show_chart, size: 18),
                        SizedBox(width: 6),
                        Text('Pertumbuhan'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_border, size: 18),
                        SizedBox(width: 6),
                        Text('Kesehatan'),
                      ],
                    ),
                  ),
                  // Breeding tab only for females
                  if (livestock.isFemale)
                    const Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pets, size: 18),
                          SizedBox(width: 6),
                          Text('Breeding'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _InformasiTab(livestock: livestock),
                  _PertumbuhanTab(livestock: livestock),
                  _KesehatanTab(livestock: livestock),
                  if (livestock.isFemale)
                    _BreedingTab(livestock: livestock),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

/// Tab 1: Informasi
class _InformasiTab extends ConsumerWidget {
  final Livestock livestock;

  const _InformasiTab({required this.livestock});

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _formatCurrency(double? value) {
    if (value == null) return '-';
    final formatted = value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }

  Color _getStatusColor(String statusCode, WidgetRef ref) {
    final statusList = ref.watch(statusNotifierProvider(livestock.farmId));
    final statusDef = statusList.value?.firstWhere((s) => s.code == statusCode, orElse: () => LivestockStatusModel(id: '', code: statusCode, name: statusCode, colorHex: '#808080', type: 'active'));
    return statusDef?.color ?? Colors.grey;
  }

  IconData _getStatusIcon(String status) {
    // Dynamic icons map (fallback to generic)
    switch (status) {
      case 'siap_kawin': return Icons.favorite;
      case 'bunting': return Icons.pregnant_woman;
      case 'menyusui': return Icons.child_care;
      case 'pejantan_aktif': return Icons.bolt;
      case 'betina_muda':
      case 'pejantan_muda': return Icons.pets;
      case 'istirahat': return Icons.pause_circle;
      case 'sold': return Icons.attach_money;
      case 'deceased': return Icons.error;

      default: return Icons.info;
    }
  }

  Future<void> _showChangeStatusDialog(BuildContext context, WidgetRef ref) async {
    final statusList = ref.read(statusNotifierProvider(livestock.farmId)).value ?? [];
    // Filter statuses valid for gender (or 'both')
    final validStatuses = statusList.where((s) => s.validForGender == 'both' || s.validForGender == livestock.gender.value).toList();
    
    String? selectedStatus = livestock.status;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ubah Status Kelinci'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih status baru untuk ${livestock.code}:',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
               ...validStatuses.map((status) => RadioListTile<String>(
                title: Text(status.name),
                value: status.code,
                groupValue: selectedStatus,
                onChanged: (value) => setState(() => selectedStatus = value),
                dense: true,
                contentPadding: EdgeInsets.zero,
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: selectedStatus != livestock.status
                  ? () => Navigator.pop(context, selectedStatus)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result != null && context.mounted) {
      await ref.read(livestockNotifierProvider.notifier).updateStatus(
        livestock.id,
        result,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status ${livestock.code} diubah menjadi $result'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider to get reactive updates
    final livestocksAsync = ref.watch(livestockNotifierProvider);
    
    // Find the current livestock from the provider (to get updated status)
    final currentLivestock = livestocksAsync.when(
      data: (list) => list.firstWhere(
        (l) => l.id == livestock.id,
        orElse: () => livestock,
      ),
      loading: () => livestock,
      error: (_, __) => livestock,
    );
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Informasi Dasar
          _SectionCard(
            title: 'Informasi Dasar',
            children: [
              _InfoRow(
                label: 'Jenis Kelamin',
                value: livestock.gender.displayName,
                valueWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      livestock.genderIcon,
                      style: TextStyle(
                        color: livestock.isFemale 
                            ? const Color(0xFFE91E63) 
                            : const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      livestock.gender.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              _InfoRow(
                label: 'Tanggal Lahir',
                value: _formatDate(livestock.birthDate),
              ),
              _InfoRow(
                label: 'Umur',
                value: livestock.ageFormatted,
              ),
              // Get weight from weight records
              Consumer(
                builder: (context, ref, _) {
                  final recordsAsync = ref.watch(weightRecordNotifierProvider(livestock.id));
                  return recordsAsync.when(
                    loading: () => _InfoRow(
                      label: 'Berat',
                      value: '-',
                    ),
                    error: (_, __) => _InfoRow(
                      label: 'Berat',
                      value: currentLivestock.weight != null 
                          ? '${currentLivestock.weight} kg' 
                          : '-',
                    ),
                    data: (records) {
                      if (records.isEmpty) {
                        return _InfoRow(
                          label: 'Berat',
                          value: currentLivestock.weight != null 
                              ? '${currentLivestock.weight} kg' 
                              : '-',
                        );
                      }
                      // Records are sorted descending, so first = latest
                      final latestWeight = records.first.weight;
                      return _InfoRow(
                        label: 'Berat',
                        value: '$latestWeight kg',
                      );
                    },
                  );
                },
              ),
              _InfoRow(
                label: 'Kandang',
                value: livestock.housingCode ?? '-',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Informasi Akuisisi
          _SectionCard(
            title: 'Informasi Akuisisi',
            children: [
              _InfoRow(
                label: 'Sumber',
                value: livestock.acquisitionType.displayName,
              ),
              if (livestock.acquisitionType == AcquisitionType.purchased) ...[
                _InfoRow(
                  label: 'Harga',
                  value: _formatCurrency(livestock.purchasePrice),
                ),
                _InfoRow(
                  label: 'Tanggal',
                  value: _formatDate(livestock.acquisitionDate),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Status
          _SectionCard(
            title: 'Status',
            children: [
              // Status Kelinci dropdown
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Status Kelinci',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Consumer(
                        builder: (context, ref, _) {
                          final statusList = ref.watch(statusNotifierProvider(currentLivestock.farmId)).value ?? [];
                          final validStatuses = statusList.where((s) => s.validForGender == 'both' || s.validForGender == currentLivestock.gender.value).toList();

                          return PopupMenuButton<String>(
                            onSelected: (statusCode) async {
                              if (statusCode != currentLivestock.status) {
                                await ref.read(livestockNotifierProvider.notifier).updateStatus(
                                  currentLivestock.id,
                                  statusCode,
                                );
                                if (context.mounted) {
                                  // Find status name
                                  final statusName = validStatuses.firstWhere((s) => s.code == statusCode, orElse: () => LivestockStatusModel(id:'', code:statusCode, name:statusCode, colorHex:'', type:'active')).name;
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Status ${currentLivestock.code} diubah ke $statusName'),
                                      backgroundColor: const Color(0xFF4CAF50),
                                    ),
                                  );
                                }
                              }
                            },
                            itemBuilder: (context) => validStatuses
                                .map((status) => PopupMenuItem<String>(
                                      value: status.code,
                                      child: Row(
                                        children: [
                                          if (status.code == currentLivestock.status)
                                            const Icon(Icons.check, size: 18, color: Color(0xFF4CAF50))
                                          else
                                            const SizedBox(width: 18),
                                          const SizedBox(width: 8),
                                          Text(status.name),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: currentLivestock.status == 'sold' || currentLivestock.status == 'deceased' 
                                    ? Colors.grey[200] 
                                    : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: currentLivestock.status == 'sold' || currentLivestock.status == 'deceased'
                                      ? Colors.grey[400]!
                                      : const Color(0xFF4CAF50),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    // Helper to display name (simple mapping or just code for now if helper missing)
                                    // Optimally we'd use the resolved name from the provider list above
                                    validStatuses.firstWhere((s) => s.code == currentLivestock.status, orElse: () => LivestockStatusModel(id:'', code:currentLivestock.status ?? '-', name:currentLivestock.status ?? '-', colorHex:'', type:'active')).name,
                                    style: TextStyle(
                                      color: currentLivestock.status == 'sold' || currentLivestock.status == 'deceased'
                                          ? Colors.grey[700]
                                          : const Color(0xFF2E7D32),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    size: 16,
                                    color: currentLivestock.status == 'sold' || currentLivestock.status == 'deceased'
                                        ? Colors.grey[700]
                                        : const Color(0xFF2E7D32),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      ),
              ),
                    ],
                  ),
                ),
              // Get health status from health records
              Consumer(
                builder: (context, ref, _) {
                  final healthAsync = ref.watch(healthByLivestockProvider(livestock.id));
                   return healthAsync.when(
                    loading: () => _InfoRow(label: 'Kesehatan', value: '...'),
                    error: (_, __) => _InfoRow(label: 'Kesehatan', value: 'Sehat'),
                    data: (records) {
                      if (records.isNotEmpty) {
                        // Show the latest health record title
                        final latest = records.first;
                        final isIllness = latest.type == HealthRecordType.illness;
                        return _InfoRow(
                          label: 'Kesehatan', 
                          value: isIllness ? '⚠️ ${latest.title}' : latest.title,
                        );
                      }
                      return _InfoRow(label: 'Kesehatan', value: 'Sehat');
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Silsilah
          _SectionCard(
            title: 'Silsilah',
            children: [
              _InfoRow(
                label: 'Induk Betina',
                value: livestock.motherCode ?? '-',
              ),
              _InfoRow(
                label: 'Induk Jantan',
                value: livestock.fatherCode ?? '-',
              ),
            ],
          ),
          if (livestock.notes != null)
            const SizedBox(height: 12),
          if (livestock.notes != null)
            _SectionCard(
              title: 'Catatan',
              children: [
                Text(livestock.notes!),
              ],
            ),
        ],
      ),
    );
  }
}

/// Tab 2: Pertumbuhan
class _PertumbuhanTab extends ConsumerWidget {
  final Livestock livestock;

  const _PertumbuhanTab({required this.livestock});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(weightRecordNotifierProvider(livestock.id));

    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (records) {
        if (records.isEmpty) {
          return _buildEmptyState(context, ref);
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chart
              _buildChart(records),
              const SizedBox(height: 16),
              // Add button
              _buildAddButton(context, ref),
              const SizedBox(height: 16),
              // Log list
              _buildLogList(context, ref, records),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAgeCard() {
    final ageInDays = livestock.birthDate != null 
        ? DateTime.now().difference(livestock.birthDate!).inDays 
        : 0;
    final years = (ageInDays / 365).floor();
    final months = ((ageInDays % 365) / 30).floor();
    final days = ageInDays % 30;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    '$years',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                  const Text('Tahun', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Container(width: 1, height: 40, color: Colors.grey[300]),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '$months',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  const Text('Bulan', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Container(width: 1, height: 40, color: Colors.grey[300]),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '$days',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const Text('Hari', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
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
            Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Data Berat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan data berat untuk melihat grafik pertumbuhan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddWeightDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Data Berat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<WeightRecord> records) {
    // Sort by date ascending for chart
    final sortedRecords = List<WeightRecord>.from(records)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    if (sortedRecords.length < 2) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Berat Saat Ini',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${sortedRecords.first.weight} kg',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tambahkan lebih banyak data untuk melihat grafik',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Build line chart data
    final spots = sortedRecords.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight);
    }).toList();

    final minWeight = sortedRecords.map((r) => r.weight).reduce((a, b) => a < b ? a : b);
    final maxWeight = sortedRecords.map((r) => r.weight).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grafik Pertumbuhan Berat',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxWeight - minWeight) / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toStringAsFixed(1)}',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedRecords.length) {
                            final date = sortedRecords[index].recordedAt;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${date.day}/${date.month}',
                                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF4CAF50),
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF4CAF50),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF4CAF50).withAlpha(30),
                      ),
                    ),
                  ],
                  minY: minWeight - 0.5,
                  maxY: maxWeight + 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showAddWeightDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Data Berat'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4CAF50),
          side: const BorderSide(color: Color(0xFF4CAF50)),
        ),
      ),
    );
  }

  Widget _buildLogList(BuildContext context, WidgetRef ref, List<WeightRecord> records) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, size: 20, color: Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                const Text(
                  'Riwayat Pengukuran',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...records.asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              final isFirst = index == 0;
              final isLast = index == records.length - 1;
              
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline indicator
                    SizedBox(
                      width: 24,
                      child: Column(
                        children: [
                          // Dot
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFirst ? const Color(0xFF4CAF50) : Colors.white,
                              border: Border.all(
                                color: const Color(0xFF4CAF50),
                                width: 2,
                              ),
                            ),
                          ),
                          // Line
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: const Color(0xFF4CAF50).withAlpha(100),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isFirst 
                              ? const Color(0xFF4CAF50).withAlpha(15) 
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isFirst 
                                ? const Color(0xFF4CAF50).withAlpha(50) 
                                : Colors.grey[200]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Date and Weight
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    record.formattedDate,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isFirst ? const Color(0xFF2E7D32) : Colors.grey[700],
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    record.formattedWeight,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Hapus Data?'),
                                        content: Text('Hapus data berat ${record.formattedWeight} pada ${record.formattedDate}?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Batal'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                            child: const Text('Hapus'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      ref.read(weightRecordNotifierProvider(livestock.id).notifier).delete(record.id);
                                    }
                                  },
                                  child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Age
                            Text(
                              'Umur: ${record.ageFormatted}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            // Notes
                            if (record.notes != null && record.notes!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '"${record.notes}"',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAddWeightDialog(BuildContext context, WidgetRef ref) {
    final weightController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    // Calculate age in days
    int? calculateAgeDays() {
      if (livestock.birthDate == null) return null;
      return selectedDate.difference(livestock.birthDate!).inDays;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final ageDays = calculateAgeDays();
          
          return AlertDialog(
            title: const Text('Tambah Data Berat'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Berat (kg)',
                      hintText: '3.5',
                      suffixText: 'kg',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: livestock.birthDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Pengukuran',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                          const Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
                    ),
                  ),
                  if (ageDays != null) ...[ 
                    const SizedBox(height: 8),
                    Text(
                      'Umur saat pengukuran: ${_formatAge(ageDays)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan (Opsional)',
                      hintText: 'Contoh: Setelah sapih, sebelum jual, dll.',
                      border: OutlineInputBorder(),
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
                onPressed: () {
                  final weight = double.tryParse(weightController.text);
                  if (weight == null || weight <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Masukkan berat yang valid')),
                    );
                    return;
                  }
                  
                  ref.read(weightRecordNotifierProvider(livestock.id).notifier).create(
                    weight: weight,
                    ageDays: calculateAgeDays(),
                    recordedAt: selectedDate,
                    notes: notesController.text.trim().isEmpty 
                        ? null 
                        : notesController.text.trim(),
                  );
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data berat berhasil ditambahkan'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatAge(int days) {
    final months = days ~/ 30;
    final remainingDays = days % 30;
    if (months > 0 && remainingDays > 0) {
      return '${months}bln ${remainingDays}hr';
    } else if (months > 0) {
      return '${months}bln';
    } else {
      return '${days}hr';
    }
  }
}

/// Tab 3: Kesehatan (Placeholder)
class _KesehatanTab extends ConsumerWidget {
  final Livestock livestock;

  const _KesehatanTab({required this.livestock});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(healthByLivestockProvider(livestock.id));

    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (records) {
        if (records.isEmpty) {
          return _buildEmptyState(context, ref);
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAddButton(context, ref),
              const SizedBox(height: 16),
              _buildRecordList(context, ref, records),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.health_and_safety, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Riwayat Kesehatan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Catat vaksinasi, penyakit, dan pengobatan di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddHealthDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Catatan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showAddHealthDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Catatan Kesehatan'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE91E63),
          side: const BorderSide(color: Color(0xFFE91E63)),
        ),
      ),
    );
  }

  Widget _buildRecordList(BuildContext context, WidgetRef ref, List<HealthRecord> records) {
    // Sort by date descending
    final sortedRecords = List<HealthRecord>.from(records)
      ..sort((a, b) => b.recordDate.compareTo(a.recordDate));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services, size: 20, color: Color(0xFFE91E63)),
                const SizedBox(width: 8),
                const Text(
                  'Riwayat Kesehatan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedRecords.asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              final isLast = index == sortedRecords.length - 1;
              
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline indicator
                    SizedBox(
                      width: 24,
                      child: Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getTypeColor(record.type).withAlpha(30),
                              border: Border.all(
                                color: _getTypeColor(record.type),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                record.type.icon,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: Colors.grey[300],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getTypeColor(record.type).withAlpha(10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getTypeColor(record.type).withAlpha(30),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getTypeColor(record.type),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          record.type.displayName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        record.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _confirmDelete(context, ref, record),
                                  child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Date
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(record.recordDate),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            // Medicine & Dosage
                            if (record.medicine != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.medication, size: 12, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${record.medicine}${record.dosage != null ? ' (${record.dosage})' : ''}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                            // Next Due Date
                            if (record.nextDueDate != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.schedule, size: 12, color: Colors.orange[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Jadwal: ${_formatDate(record.nextDueDate!)}',
                                      style: TextStyle(fontSize: 11, color: Colors.orange[700]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            // Notes
                            if (record.notes != null && record.notes!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '"${record.notes}"',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(HealthRecordType type) {
    switch (type) {
      case HealthRecordType.vaccination:
        return const Color(0xFF2196F3);
      case HealthRecordType.illness:
        return const Color(0xFFE91E63);
      case HealthRecordType.treatment:
        return const Color(0xFF4CAF50);
      case HealthRecordType.checkup:
        return const Color(0xFF9C27B0);
      case HealthRecordType.deworming:
        return const Color(0xFFFF9800);
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, HealthRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: Text('Hapus "${record.title}" pada ${_formatDate(record.recordDate)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(healthNotifierProvider.notifier).delete(record.id);
      // Invalidate to refresh
      ref.invalidate(healthByLivestockProvider(livestock.id));
    }
  }

  void _showAddHealthDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final medicineController = TextEditingController();
    final dosageController = TextEditingController();
    final costController = TextEditingController();
    final notesController = TextEditingController();
    HealthRecordType selectedType = HealthRecordType.vaccination;
    DateTime recordDate = DateTime.now();
    DateTime? nextDueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Tambah Catatan Kesehatan'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type
                  const Text('Jenis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: HealthRecordType.values.map((type) => 
                      ChoiceChip(
                        label: Text('${type.icon} ${type.displayName}'),
                        selected: selectedType == type,
                        onSelected: (selected) {
                          if (selected) setState(() => selectedType = type);
                        },
                        selectedColor: _getTypeColor(type).withAlpha(50),
                        labelStyle: TextStyle(
                          color: selectedType == type ? _getTypeColor(type) : null,
                          fontSize: 12,
                        ),
                      ),
                    ).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul *',
                      hintText: 'Myxomatosis, Diare, dll',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: recordDate,
                        firstDate: livestock.birthDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => recordDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDate(recordDate)),
                          const Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Medicine & Dosage
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: medicineController,
                          decoration: const InputDecoration(
                            labelText: 'Obat/Vaksin',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: dosageController,
                          decoration: const InputDecoration(
                            labelText: 'Dosis',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Cost
                  TextField(
                    controller: costController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Biaya (Opsional)',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Next Due Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: nextDueDate ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      setState(() => nextDueDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Jadwal Ulang (Opsional)',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(nextDueDate != null ? _formatDate(nextDueDate!) : 'Pilih tanggal'),
                          const Icon(Icons.schedule, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Notes
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan',
                      border: OutlineInputBorder(),
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
                  if (titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Judul harus diisi')),
                    );
                    return;
                  }
                  
                  await ref.read(healthNotifierProvider.notifier).create(
                    livestockId: livestock.id,
                    type: selectedType,
                    title: titleController.text.trim(),
                    recordDate: recordDate,
                    medicine: medicineController.text.trim().isEmpty ? null : medicineController.text.trim(),
                    dosage: dosageController.text.trim().isEmpty ? null : dosageController.text.trim(),
                    cost: costController.text.isEmpty ? null : double.tryParse(costController.text),
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    nextDueDate: nextDueDate,
                  );
                  
                  // Refresh
                  ref.invalidate(healthByLivestockProvider(livestock.id));
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Catatan kesehatan berhasil ditambahkan'),
                        backgroundColor: Color(0xFF4CAF50),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Tab 4: Breeding (Placeholder)
class _BreedingTab extends ConsumerWidget {
  final Livestock livestock;

  const _BreedingTab({required this.livestock});

  // Scientific breeding parameters
  static const int minBreedingAgeDays = 120; // ~4 months
  static const int palpationDaysAfterMating = 12; // 10-14 days recommended
  static const int gestationDays = 31; // 28-35 days, 31 typical
  static const int weaningDaysAfterBirth = 35; // 4-8 weeks, ~5 weeks standard

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breedingsAsync = ref.watch(breedingsByDamProvider(livestock.id));

    return breedingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (breedings) {
        if (breedings.isEmpty) {
          return _buildEmptyState(context, ref);
        }
        
        // Separate active and completed breedings
        final activeBreedings = breedings.where((b) => 
            b.status == BreedingStatus.mated || 
            b.status == BreedingStatus.palpated ||
            b.status == BreedingStatus.pregnant ||
            b.status == BreedingStatus.birthed).toList();
        final completedBreedings = breedings.where((b) => 
            b.status == BreedingStatus.weaned ||
            b.status == BreedingStatus.failed).toList();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact stats bar (always shown)
              _buildCompactStats(breedings),
              const SizedBox(height: 12),
              
              // Active breeding card (priority if exists)
              if (activeBreedings.isNotEmpty) ...[
                _buildActiveBreedingCard(activeBreedings.first, ref),
                const SizedBox(height: 12),
              ] else if (livestock.isFemale) ...[
                // Add new breeding button when no active breeding
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddBreedingDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Kawin Baru'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9C27B0),
                      side: const BorderSide(color: Color(0xFF9C27B0)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // History (collapsible, max 3 shown initially)
              if (completedBreedings.isNotEmpty)
                _buildCollapsibleHistory(context, completedBreedings),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final canBreed = livestock.birthDate != null && 
        DateTime.now().difference(livestock.birthDate!).inDays >= minBreedingAgeDays;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Riwayat Breeding',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              livestock.isFemale
                  ? 'Riwayat kawin dan kelahiran akan muncul di sini.'
                  : 'Kelinci ini belum pernah dijodohkan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            if (!canBreed && livestock.birthDate != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Siap kawin dalam ${minBreedingAgeDays - DateTime.now().difference(livestock.birthDate!).inDays} hari',
                      style: TextStyle(color: Colors.orange[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            if (canBreed && livestock.isFemale) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showAddBreedingDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Kawin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(List<BreedingRecord> breedings) {
    // Calculate statistics
    final total = breedings.length;
    final successful = breedings.where((b) => 
        b.status == BreedingStatus.birthed || 
        b.status == BreedingStatus.weaned).length;
    final failed = breedings.where((b) => b.status == BreedingStatus.failed).length;
    final totalBorn = breedings.fold<int>(0, (sum, b) => sum + (b.aliveCount ?? 0));
    final totalWeaned = breedings.fold<int>(0, (sum, b) => sum + (b.weanedCount ?? 0));
    
    final successRate = total > 0 ? (successful / total * 100) : 0.0;
    final weaningRate = totalBorn > 0 ? (totalWeaned / totalBorn * 100) : 0.0;
    final avgLitterSize = successful > 0 ? (totalBorn / successful) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, size: 20, color: Color(0xFF9C27B0)),
                const SizedBox(width: 8),
                const Text(
                  'Statistik Breeding',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem('Total', '$total kali', Icons.repeat, Colors.blue),
                _buildStatItem('Berhasil', '$successful', Icons.check_circle, Colors.green),
                _buildStatItem('Gagal', '$failed', Icons.cancel, Colors.red),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _buildStatItem('Lahir', '$totalBorn ekor', Icons.child_friendly, Colors.orange),
                _buildStatItem('Sapih', '$totalWeaned ekor', Icons.check, Colors.teal),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _buildPercentItem('Keberhasilan', successRate, Colors.green),
                _buildPercentItem('Sapih', weaningRate, Colors.teal),
                _buildPercentItem('Avg. Litter', avgLitterSize, Colors.purple, suffix: ''),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentItem(String label, double value, Color color, {String suffix = '%'}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            suffix == '%' ? '${value.toStringAsFixed(0)}$suffix' : value.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // === OPTION C METHODS ===

  Widget _buildCompactStats(List<BreedingRecord> breedings) {
    final total = breedings.length;
    final successful = breedings.where((b) => 
        b.status == BreedingStatus.birthed || 
        b.status == BreedingStatus.weaned).length;
    final failed = breedings.where((b) => b.status == BreedingStatus.failed).length;
    
    // Gender breakdown
    final totalMaleBorn = breedings.fold<int>(0, (sum, b) => sum + (b.maleBorn ?? 0));
    final totalFemaleBorn = breedings.fold<int>(0, (sum, b) => sum + (b.femaleBorn ?? 0));
    final totalBorn = breedings.fold<int>(0, (sum, b) => sum + (b.aliveCount ?? 0));
    final totalMaleWeaned = breedings.fold<int>(0, (sum, b) => sum + (b.maleWeaned ?? 0));
    final totalFemaleWeaned = breedings.fold<int>(0, (sum, b) => sum + (b.femaleWeaned ?? 0));
    final totalWeaned = breedings.fold<int>(0, (sum, b) => sum + (b.weanedCount ?? 0));
    
    final successRate = total > 0 ? (successful / total * 100) : 0.0;
    final weaningRate = totalBorn > 0 ? (totalWeaned / totalBorn * 100) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Row 1: Basic counts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('${total}x', 'Total', Colors.blue),
                _buildMiniStat('${successRate.toStringAsFixed(0)}%', 'Sukses', Colors.green),
                _buildMiniStat('$failed', 'Gagal', Colors.red),
              ],
            ),
            const Divider(height: 16),
            // Row 2: Birth/Weaning with gender
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('🐣 $totalBorn lahir', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    if (totalMaleBorn > 0 || totalFemaleBorn > 0)
                      Text('♂$totalMaleBorn ♀$totalFemaleBorn', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  ],
                ),
                Column(
                  children: [
                    Text('🏠 $totalWeaned sapih (${weaningRate.toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    if (totalMaleWeaned > 0 || totalFemaleWeaned > 0)
                      Text('♂$totalMaleWeaned ♀$totalFemaleWeaned', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildActiveBreedingCard(BreedingRecord breeding, WidgetRef ref) {
    final progress = _calculateProgress(breeding);
    final nextAction = _getNextAction(breeding);
    final daysInfo = _getDaysInfo(breeding);
    
    return Card(
      color: _getStatusColor(breeding.status).withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active, size: 16, color: Color(0xFF9C27B0)),
                const SizedBox(width: 6),
                const Text('Breeding Aktif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(breeding.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    breeding.status.displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Sire & dates
            Row(
              children: [
                Icon(Icons.male, size: 14, color: Colors.blue[700]),
                const SizedBox(width: 4),
                Text('${breeding.sireCode ?? "?"} • ${_formatDate(breeding.matingDate)}', style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(_getStatusColor(breeding.status)),
            ),
            const SizedBox(height: 6),
            // Progress labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                Text(daysInfo, style: TextStyle(fontSize: 10, color: Colors.orange[700], fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 8),
            // Next action hint
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _getStatusColor(breeding.status).withAlpha(50)),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_forward, size: 14, color: _getStatusColor(breeding.status)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      nextAction,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Action button based on status
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showUpdateDialog(breeding, ref),
                icon: Icon(_getActionIcon(breeding.status), size: 16),
                label: Text(_getActionLabel(breeding.status)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getStatusColor(breeding.status),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActionIcon(BreedingStatus status) {
    switch (status) {
      case BreedingStatus.mated:
        return Icons.touch_app;
      case BreedingStatus.palpated:
      case BreedingStatus.pregnant:
        return Icons.child_friendly;
      case BreedingStatus.birthed:
        return Icons.check_circle;
      default:
        return Icons.edit;
    }
  }

  String _getActionLabel(BreedingStatus status) {
    switch (status) {
      case BreedingStatus.mated:
        return 'Input Palpasi';
      case BreedingStatus.palpated:
      case BreedingStatus.pregnant:
        return 'Input Kelahiran';
      case BreedingStatus.birthed:
        return 'Input Sapih';
      default:
        return 'Update';
    }
  }

  void _showUpdateDialog(BreedingRecord breeding, WidgetRef ref) {
    switch (breeding.status) {
      case BreedingStatus.mated:
        _showPalpationDialog(breeding, ref);
        break;
      case BreedingStatus.palpated:
      case BreedingStatus.pregnant:
        _showBirthDialog(breeding, ref);
        break;
      case BreedingStatus.birthed:
        _showWeaningDialog(breeding, ref);
        break;
      default:
        break;
    }
  }

  double _calculateProgress(BreedingRecord breeding) {
    switch (breeding.status) {
      case BreedingStatus.mated:
        return 0.25;
      case BreedingStatus.palpated:
        return breeding.isPalpationPositive == true ? 0.5 : 0.25;
      case BreedingStatus.pregnant:
        return 0.75;
      case BreedingStatus.birthed:
        return 0.9;
      case BreedingStatus.weaned:
        return 1.0;
      case BreedingStatus.failed:
        return 0.0;
    }
  }

  String _getNextAction(BreedingRecord breeding) {
    switch (breeding.status) {
      case BreedingStatus.mated:
        final palpationDate = breeding.matingDate.add(const Duration(days: palpationDaysAfterMating));
        return 'Palpasi: ${_formatDate(palpationDate)}';
      case BreedingStatus.palpated:
        if (breeding.isPalpationPositive == true) {
          return 'Perkiraan lahir: ${_formatDate(breeding.expectedBirthDate ?? breeding.matingDate.add(const Duration(days: gestationDays)))}';
        }
        return 'Palpasi negatif - update status';
      case BreedingStatus.pregnant:
        return 'Perkiraan lahir: ${_formatDate(breeding.expectedBirthDate ?? breeding.matingDate.add(const Duration(days: gestationDays)))}';
      case BreedingStatus.birthed:
        final weaningDate = (breeding.actualBirthDate ?? DateTime.now()).add(const Duration(days: weaningDaysAfterBirth));
        return 'Sapih: ${_formatDate(weaningDate)}';
      default:
        return '';
    }
  }

  String _getDaysInfo(BreedingRecord breeding) {
    final daysSinceMating = DateTime.now().difference(breeding.matingDate).inDays;
    switch (breeding.status) {
      case BreedingStatus.mated:
        final daysUntilPalpation = palpationDaysAfterMating - daysSinceMating;
        return daysUntilPalpation > 0 ? 'Palpasi dalam $daysUntilPalpation hari' : 'Waktunya palpasi!';
      case BreedingStatus.palpated:
      case BreedingStatus.pregnant:
        final expectedBirth = breeding.expectedBirthDate ?? breeding.matingDate.add(const Duration(days: gestationDays));
        final daysUntilBirth = expectedBirth.difference(DateTime.now()).inDays;
        return daysUntilBirth > 0 ? 'Lahir dalam $daysUntilBirth hari' : 'Waktunya melahirkan!';
      case BreedingStatus.birthed:
        final weaningDate = (breeding.actualBirthDate ?? DateTime.now()).add(const Duration(days: weaningDaysAfterBirth));
        final daysUntilWeaning = weaningDate.difference(DateTime.now()).inDays;
        return daysUntilWeaning > 0 ? 'Sapih dalam $daysUntilWeaning hari' : 'Waktunya sapih!';
      default:
        return '';
    }
  }

  Widget _buildCollapsibleHistory(BuildContext context, List<BreedingRecord> breedings) {
    // Sort by mating date descending
    final sorted = List<BreedingRecord>.from(breedings)
      ..sort((a, b) => b.matingDate.compareTo(a.matingDate));
    
    final showAll = sorted.length <= 3;
    final displayRecords = showAll ? sorted : sorted.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 16, color: Color(0xFF9C27B0)),
                const SizedBox(width: 6),
                Text('Riwayat (${sorted.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            ...displayRecords.map((b) => _buildHistoryItem(b)),
            if (!showAll)
              Center(
                child: TextButton(
                  onPressed: () => _showFullHistoryDialog(context, sorted),
                  child: Text('Lihat semua ${sorted.length} riwayat'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFullHistoryDialog(BuildContext context, List<BreedingRecord> breedings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.history, color: Color(0xFF9C27B0)),
            const SizedBox(width: 8),
            Text('Riwayat Breeding (${breedings.length})'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: breedings.length,
            itemBuilder: (context, index) => _buildHistoryItem(breedings[index]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BreedingRecord breeding) {
    final isSuccess = breeding.status == BreedingStatus.weaned;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.withAlpha(10) : Colors.red.withAlpha(10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: (isSuccess ? Colors.green : Colors.red).withAlpha(30)),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isSuccess ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatDate(breeding.matingDate)} • ${breeding.sireCode ?? "?"}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
                if (isSuccess && breeding.weanedCount != null)
                  Text(
                    '${breeding.weanedCount} sapih${breeding.maleWeaned != null || breeding.femaleWeaned != null ? " (♂${breeding.maleWeaned ?? 0} ♀${breeding.femaleWeaned ?? 0})" : ""} • ${breeding.weaningRate != null ? "${(breeding.weaningRate! * 100).toStringAsFixed(0)}%" : "-"}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  )
                else if (!isSuccess)
                  Text(
                    breeding.isPalpationPositive == false ? 'Palpasi negatif' : 'Gagal',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Color _getStatusColor(BreedingStatus status) {
    switch (status) {
      case BreedingStatus.mated:
        return Colors.blue;
      case BreedingStatus.palpated:
        return Colors.amber;
      case BreedingStatus.pregnant:
        return Colors.orange;
      case BreedingStatus.birthed:
        return Colors.green;
      case BreedingStatus.weaned:
        return Colors.teal;
      case BreedingStatus.failed:
        return Colors.red;
    }
  }

  /// Get minimum breeding date (birth date + 4 months)
  DateTime _getMinimumBreedingDate() {
    if (livestock.birthDate == null) return DateTime(2020);
    // Minimum breeding age is 4 months (120 days)
    final minBreedingDate = livestock.birthDate!.add(const Duration(days: minBreedingAgeDays));
    // Ensure the date is not in the future
    final today = DateTime.now();
    return minBreedingDate.isAfter(today) ? today : minBreedingDate;
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showAddBreedingDialog(BuildContext context, WidgetRef ref) {
    final notesController = TextEditingController();
    DateTime matingDate = DateTime.now();
    String? selectedSireId;

    showDialog(
      context: context,
      builder: (context) {
        // Fetch male livestock for sire selection
        final livestockAsync = ref.watch(livestockNotifierProvider);
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tambah Kawin'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sire selection
                    const Text('Pejantan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    livestockAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('Error loading'),
                      data: (allLivestock) {
                        final males = allLivestock.where((l) => !l.isFemale).toList();
                        return DropdownButtonFormField<String>(
                          value: selectedSireId,
                          hint: const Text('Pilih Pejantan'),
                          items: males.map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(m.code ?? m.name ?? 'Unknown'),
                          )).toList(),
                          onChanged: (value) => setState(() => selectedSireId = value),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Mating date
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: matingDate.isBefore(_getMinimumBreedingDate()) ? _getMinimumBreedingDate() : matingDate,
                          firstDate: _getMinimumBreedingDate(),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => matingDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Kawin',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDate(matingDate)),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Expected birth info
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Colors.blue[700]),
                          const SizedBox(width: 6),
                          Text(
                            'Perkiraan lahir: ${_formatDate(matingDate.add(const Duration(days: gestationDays)))}',
                            style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Notes
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (Opsional)',
                        border: OutlineInputBorder(),
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
                    await ref.read(breedingNotifierProvider.notifier).create(
                      damId: livestock.id,
                      matingDate: matingDate,
                      sireId: selectedSireId,
                      expectedBirthDate: matingDate.add(const Duration(days: gestationDays)),
                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    );
                    
                    // Refresh breeding list
                    ref.invalidate(breedingsByDamProvider(livestock.id));
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data kawin berhasil ditambahkan'),
                          backgroundColor: Color(0xFF4CAF50),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C27B0)),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPalpationDialog(BreedingRecord breeding, WidgetRef ref) {
    DateTime palpationDate = DateTime.now();
    bool? isPositive;

    showDialog(
      context: livestock.id.isNotEmpty ? ref.context : ref.context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Input Palpasi'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Palpation date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: palpationDate,
                        firstDate: breeding.matingDate,
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => palpationDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Palpasi',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDate(palpationDate)),
                          const Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Result selection
                  const Text('Hasil Palpasi:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isPositive = true),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isPositive == true ? Colors.green.withAlpha(30) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isPositive == true ? Colors.green : Colors.grey[300]!,
                                width: isPositive == true ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.check_circle, color: isPositive == true ? Colors.green : Colors.grey, size: 32),
                                const SizedBox(height: 4),
                                Text('Positif', style: TextStyle(color: isPositive == true ? Colors.green : Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isPositive = false),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isPositive == false ? Colors.red.withAlpha(30) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isPositive == false ? Colors.red : Colors.grey[300]!,
                                width: isPositive == false ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.cancel, color: isPositive == false ? Colors.red : Colors.grey, size: 32),
                                const SizedBox(height: 4),
                                Text('Negatif', style: TextStyle(color: isPositive == false ? Colors.red : Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: isPositive == null ? null : () async {
                    await ref.read(breedingNotifierProvider.notifier).updatePalpation(
                      id: breeding.id,
                      palpationDate: palpationDate,
                      isPositive: isPositive!,
                    );
                    ref.invalidate(breedingsByDamProvider(livestock.id));
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Palpasi ${isPositive! ? "positif" : "negatif"} disimpan'),
                        backgroundColor: isPositive! ? Colors.green : Colors.red,
                      ));
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBirthDialog(BreedingRecord breeding, WidgetRef ref) {
    DateTime birthDate = DateTime.now();
    int maleCount = 0;
    int femaleCount = 0;
    int deadCount = 0;

    showDialog(
      context: livestock.id.isNotEmpty ? ref.context : ref.context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final aliveCount = maleCount + femaleCount;
            return AlertDialog(
              title: const Text('Input Kelahiran'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Birth date
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: birthDate,
                          firstDate: breeding.matingDate,
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => birthDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Lahir',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDate(birthDate)),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Counter row - Male
                    _buildCounterRow('♂ Jantan Hidup', maleCount, (v) => setState(() => maleCount = v)),
                    const SizedBox(height: 8),
                    // Counter row - Female
                    _buildCounterRow('♀ Betina Hidup', femaleCount, (v) => setState(() => femaleCount = v)),
                    const SizedBox(height: 8),
                    // Counter row - Dead
                    _buildCounterRow('💀 Mati', deadCount, (v) => setState(() => deadCount = v)),
                    const SizedBox(height: 12),
                    // Summary
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Total: ${aliveCount + deadCount} anak ($aliveCount hidup, $deadCount mati)',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: aliveCount == 0 && deadCount == 0 ? null : () async {
                    await ref.read(breedingNotifierProvider.notifier).updateBirth(
                      id: breeding.id,
                      birthDate: birthDate,
                      aliveCount: aliveCount,
                      deadCount: deadCount,
                      maleBorn: maleCount,
                      femaleBorn: femaleCount,
                    );
                    ref.invalidate(breedingsByDamProvider(livestock.id));
                    // Auto-refresh Anakan page
                    ref.invalidate(offspringNotifierProvider);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Data kelahiran disimpan'),
                        backgroundColor: Colors.green,
                      ));
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showWeaningDialog(BreedingRecord breeding, WidgetRef ref) {
    DateTime weaningDate = DateTime.now();
    int maleWeaned = breeding.maleBorn ?? 0;
    int femaleWeaned = breeding.femaleBorn ?? 0;

    showDialog(
      context: livestock.id.isNotEmpty ? ref.context : ref.context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final totalWeaned = maleWeaned + femaleWeaned;
            final maxMale = breeding.maleBorn ?? (breeding.aliveCount ?? 0);
            final maxFemale = breeding.femaleBorn ?? (breeding.aliveCount ?? 0);
            return AlertDialog(
              title: const Text('Input Sapih'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Weaning date
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: weaningDate,
                          firstDate: breeding.actualBirthDate ?? breeding.matingDate,
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => weaningDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Sapih',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDate(weaningDate)),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Info
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                      child: Text('Lahir: ${breeding.aliveCount ?? 0} hidup', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    ),
                    const SizedBox(height: 12),
                    // Counter row - Male
                    _buildCounterRow('♂ Jantan Sapih', maleWeaned, (v) => setState(() => maleWeaned = v), max: maxMale),
                    const SizedBox(height: 8),
                    // Counter row - Female
                    _buildCounterRow('♀ Betina Sapih', femaleWeaned, (v) => setState(() => femaleWeaned = v), max: maxFemale),
                    const SizedBox(height: 12),
                    // Summary
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.teal[50], borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        'Total Sapih: $totalWeaned ekor (${breeding.aliveCount != null && breeding.aliveCount! > 0 ? (totalWeaned / breeding.aliveCount! * 100).toStringAsFixed(0) : "0"}%)',
                        style: TextStyle(fontSize: 12, color: Colors.teal[700]),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () async {
                    await ref.read(breedingNotifierProvider.notifier).updateWeaning(
                      id: breeding.id,
                      weaningDate: weaningDate,
                      weanedCount: totalWeaned,
                      maleWeaned: maleWeaned,
                      femaleWeaned: femaleWeaned,
                    );
                    ref.invalidate(breedingsByDamProvider(livestock.id));
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Data sapih disimpan'),
                        backgroundColor: Colors.teal,
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCounterRow(String label, int value, Function(int) onChanged, {int max = 99}) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        IconButton(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          iconSize: 28,
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          iconSize: 28,
        ),
      ],
    );
  }
}

/// Section card container
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// Info row with label and value
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? valueWidget;

  const _InfoRow({
    required this.label, 
    required this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: valueWidget ?? Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status row with colored badge
class _StatusRow extends StatelessWidget {
  final String label;
  final String status;
  final Color color;
  final IconData icon;

  const _StatusRow({
    required this.label,
    required this.status,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
