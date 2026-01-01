/// Create Livestock Screen
/// 
/// Form untuk menambah indukan/pejantan baru.
/// Kode auto-generate berdasarkan ras dan gender: [BREED]-[J/B][SEQ]

library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/livestock.dart';
import '../../../models/breed.dart';
import '../../../models/livestock_status_model.dart';
import '../../../providers/status_provider.dart';
import '../../../providers/livestock_provider.dart';
import '../../../providers/housing_provider.dart';
import '../../../providers/breed_provider.dart';
import '../../../providers/farm_provider.dart';
import '../../../providers/weight_record_provider.dart';
import '../../../providers/health_provider.dart';
import '../../../models/health_record.dart';
import '../../../core/utils/currency_formatter.dart';

/// Helper function to show create livestock panel from side
void showCreateLivestockPanel(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Create Livestock',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: _CreateLivestockPanel(),
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

class CreateLivestockScreen extends ConsumerStatefulWidget {
  const CreateLivestockScreen({super.key});

  @override
  ConsumerState<CreateLivestockScreen> createState() => _CreateLivestockScreenState();
}

class _CreateLivestockScreenState extends ConsumerState<CreateLivestockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  
  Gender _selectedGender = Gender.female;
  String? _selectedStatus;
  AcquisitionType _selectedAcquisition = AcquisitionType.purchased;
  String? _selectedHousingId;
  String? _selectedBreedId;
  Breed? _selectedBreed;
  String _generatedCode = '';
  DateTime? _birthDate;
  DateTime? _acquisitionDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _weightController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateGeneratedCode() async {
    if (_selectedBreed == null) {
      setState(() => _generatedCode = '');
      return;
    }

    try {
      final repository = ref.read(livestockRepositoryProvider);
      final farm = ref.read(currentFarmProvider);
      if (farm == null) return;

      final code = await repository.getNextCode(
        farmId: farm.id,
        breedCode: _selectedBreed!.code,
        gender: _selectedGender,
      );
      setState(() => _generatedCode = code);
    } catch (e) {
      // Fallback
      final prefix = _selectedGender == Gender.male ? 'J' : 'B';
      setState(() => _generatedCode = '${_selectedBreed!.code}-${prefix}01');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isBirthDate) {
          _birthDate = picked;
        } else {
          _acquisitionDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Pilih tanggal';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_generatedCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih ras terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final weight = _weightController.text.isEmpty 
          ? null 
          : double.tryParse(_weightController.text);
      
      final livestock = await ref.read(livestockNotifierProvider.notifier).create(
        code: _generatedCode,
        gender: _selectedGender,
        housingId: _selectedHousingId,
        breedId: _selectedBreedId,
        birthDate: _birthDate,
        acquisitionDate: _acquisitionDate,
        acquisitionType: _selectedAcquisition,
        purchasePrice: _priceController.text.isEmpty 
            ? null 
            : parseFormattedPrice(_priceController.text),
        status: _selectedStatus,
        weight: weight,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      // If weight was provided, also create a weight record
      if (weight != null) {
        final recordedAt = _acquisitionDate ?? DateTime.now();
        int? ageDays;
        if (_birthDate != null) {
          ageDays = recordedAt.difference(_birthDate!).inDays;
        }
        
        await ref.read(weightRecordRepositoryProvider).create(
          livestockId: livestock.id,
          weight: weight,
          ageDays: ageDays,
          recordedAt: recordedAt,
          notes: 'Berat awal saat registrasi',
        );
      }

      // Create initial health log with status "Sehat"
      try {
        debugPrint('Creating health log for livestock: ${livestock.id}');
        await ref.read(healthNotifierProvider.notifier).create(
          livestockId: livestock.id,
          type: HealthRecordType.checkup,
          title: 'Sehat',
          recordDate: DateTime.now(),
          notes: 'Status kesehatan awal saat registrasi',
        );
        // Invalidate provider to refresh UI
        ref.invalidate(healthByLivestockProvider(livestock.id));
        debugPrint('Health log created successfully');
      } catch (healthError) {
        // Log but don't fail the entire operation
        debugPrint('WARNING: Failed to create initial health log: $healthError');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_generatedCode berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddBreedDialog() {
    final codeController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Ras'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Kode',
                hintText: 'NZW, REX, etc.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama',
                hintText: 'New Zealand White',
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
              if (codeController.text.isEmpty || nameController.text.isEmpty) return;
              
              Navigator.pop(context);
              await ref.read(breedNotifierProvider.notifier).create(
                code: codeController.text.trim(),
                name: nameController.text.trim(),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final housingsAsync = ref.watch(availableHousingsProvider);
    final breedsAsync = ref.watch(breedNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Indukan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Gender Selection
              const Text(
                'Gender',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _GenderOption(
                      gender: Gender.female,
                      isSelected: _selectedGender == Gender.female,
                      onTap: () {
                        setState(() {
                          _selectedGender = Gender.female;
                          _selectedStatus = 'betina_muda'; // Default fallback
                        });
                        _updateGeneratedCode();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GenderOption(
                      gender: Gender.male,
                      isSelected: _selectedGender == Gender.male,
                      onTap: () {
                        setState(() {
                          _selectedGender = Gender.male;
                          _selectedStatus = 'pejantan_muda'; // Default fallback
                        });
                        _updateGeneratedCode();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status Selection (filtered by gender)
              Consumer(
                builder: (context, ref, child) {
                  final farmId = ref.watch(currentFarmProvider)?.id ?? '';
                  final statusAsync = ref.watch(statusNotifierProvider(farmId));
                  
                  final validStatuses = statusAsync.value?.where((s) => s.isActive && (s.validForGender == 'both' || s.validForGender == _selectedGender.value)).toList() ?? [];
                  
                  // Reset selection if invalid for new gender
                  if (_selectedStatus == null || !validStatuses.any((s) => s.code == _selectedStatus)) {
                    if (validStatuses.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() => _selectedStatus = validStatuses.first.code);
                      });
                    }
                  }
                  
                  return DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                    items: validStatuses.map((status) => DropdownMenuItem(
                          value: status.code,
                          child: Text(status.name),
                        )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedStatus = value);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Breed Selection
              Row(
                children: [
                  Expanded(
                    child: breedsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error loading breeds'),
                      data: (breeds) => DropdownButtonFormField<String>(
                        value: _selectedBreedId,
                        decoration: const InputDecoration(
                          labelText: 'Ras *',
                          prefixIcon: Icon(Icons.category),
                        ),
                        hint: const Text('Pilih ras'),
                        items: breeds.map((b) => DropdownMenuItem(
                          value: b.id,
                          child: Text(b.displayName),
                        )).toList(),
                        onChanged: (value) {
                          final breed = breeds.firstWhere((b) => b.id == value);
                          setState(() {
                            _selectedBreedId = value;
                            _selectedBreed = breed;
                          });
                          _updateGeneratedCode();
                        },
                        validator: (value) {
                          if (value == null) return 'Pilih ras';
                          return null;
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _showAddBreedDialog,
                    icon: const Icon(Icons.add_circle),
                    tooltip: 'Tambah Ras',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Generated Code Preview
              if (_generatedCode.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tag),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kode', style: TextStyle(fontSize: 12)),
                          Text(
                            _generatedCode,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Housing
              DropdownButtonFormField<String>(
                value: _selectedHousingId,
                decoration: const InputDecoration(
                  labelText: 'Kandang',
                  prefixIcon: Icon(Icons.home_work),
                ),
                hint: const Text('Pilih kandang'),
                items: housingsAsync.when(
                  loading: () => [],
                  error: (_, __) => [],
                  data: (housings) => housings.map((h) {
                    return DropdownMenuItem(
                      value: h.id,
                      child: Text(h.displayName),
                    );
                  }).toList(),
                ),
                onChanged: (value) => setState(() => _selectedHousingId = value),
              ),
              const SizedBox(height: 16),

              // Birth Date
              InkWell(
                onTap: () => _selectDate(context, true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Lahir',
                    prefixIcon: Icon(Icons.cake),
                  ),
                  child: Text(_formatDate(_birthDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Acquisition Type
              DropdownButtonFormField<AcquisitionType>(
                value: _selectedAcquisition,
                decoration: const InputDecoration(
                  labelText: 'Asal',
                  prefixIcon: Icon(Icons.shopping_cart),
                ),
                items: AcquisitionType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedAcquisition = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Acquisition Date
              if (_selectedAcquisition == AcquisitionType.purchased)
                InkWell(
                  onTap: () => _selectDate(context, false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Pembelian',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(_formatDate(_acquisitionDate)),
                  ),
                ),
              if (_selectedAcquisition == AcquisitionType.purchased)
                const SizedBox(height: 16),

              // Purchase Price
              if (_selectedAcquisition == AcquisitionType.purchased)
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Harga Beli',
                    prefixIcon: Icon(Icons.attach_money),
                    prefixText: 'Rp ',
                  ),
                ),
              if (_selectedAcquisition == AcquisitionType.purchased)
                const SizedBox(height: 16),

              // Weight
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Berat (Opsional)',
                  prefixIcon: Icon(Icons.scale),
                  suffixText: 'kg',
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Icon(Icons.notes),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final Gender gender;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.gender,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = gender == Gender.female ? Colors.pink : Colors.blue;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? color.withAlpha(25) : null,
        ),
        child: Column(
          children: [
            Text(
              gender.icon,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text(
              gender.displayName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Side Panel version of Create Livestock form
class _CreateLivestockPanel extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateLivestockPanel> createState() => _CreateLivestockPanelState();
}

class _CreateLivestockPanelState extends ConsumerState<_CreateLivestockPanel> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  
  Gender _selectedGender = Gender.female;
  String? _selectedStatus;
  AcquisitionType _selectedAcquisition = AcquisitionType.purchased;
  String? _selectedHousingId;
  String? _selectedBreedId;
  Breed? _selectedBreed;
  String _generatedCode = '';
  DateTime? _birthDate;
  DateTime? _acquisitionDate;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _weightController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateGeneratedCode() async {
    if (_selectedBreed == null) {
      setState(() => _generatedCode = '');
      return;
    }

    try {
      final repository = ref.read(livestockRepositoryProvider);
      final farm = ref.read(currentFarmProvider);
      if (farm == null) return;

      final code = await repository.getNextCode(
        farmId: farm.id,
        breedCode: _selectedBreed!.code,
        gender: _selectedGender,
      );
      setState(() => _generatedCode = code);
    } catch (e) {
      final prefix = _selectedGender == Gender.male ? 'J' : 'B';
      setState(() => _generatedCode = '${_selectedBreed!.code}-${prefix}01');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isBirthDate) {
          _birthDate = picked;
        } else {
          _acquisitionDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Pilih tanggal';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleSubmit() async {
    setState(() => _errorMessage = null); // Clear previous error
    
    if (!_formKey.currentState!.validate()) return;
    
    // Validate required fields with inline error message
    if (_selectedBreedId == null || _generatedCode.isEmpty) {
      setState(() => _errorMessage = 'Pilih ras terlebih dahulu');
      return;
    }
    if (_birthDate == null) {
      setState(() => _errorMessage = 'Tanggal lahir wajib diisi');
      return;
    }
    if (_selectedHousingId == null) {
      setState(() => _errorMessage = 'Kandang wajib dipilih');
      return;
    }
    if (_acquisitionDate == null) {
      setState(() => _errorMessage = 'Tanggal pembelian wajib diisi');
      return;
    }
    if (_priceController.text.isEmpty) {
      setState(() => _errorMessage = 'Harga beli wajib diisi');
      return;
    }
    if (_weightController.text.isEmpty) {
      setState(() => _errorMessage = 'Berat wajib diisi');
      return;
    }
    
    // Validate weight range (0.1 - 15 kg for rabbits)
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight < 0.1 || weight > 15) {
      setState(() => _errorMessage = 'Berat tidak wajar (harus 0.1 - 15 kg)');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final weight = double.tryParse(_weightController.text);
      
      final livestock = await ref.read(livestockNotifierProvider.notifier).create(
        code: _generatedCode,
        gender: _selectedGender,
        housingId: _selectedHousingId,
        breedId: _selectedBreedId,
        birthDate: _birthDate,
        acquisitionDate: _acquisitionDate,
        acquisitionType: AcquisitionType.purchased, // Always purchased
        purchasePrice: parseFormattedPrice(_priceController.text),
        status: _selectedStatus,
        weight: weight,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      if (weight != null) {
        final recordedAt = _acquisitionDate ?? DateTime.now();
        int? ageDays;
        if (_birthDate != null) {
          ageDays = recordedAt.difference(_birthDate!).inDays;
        }
        
        await ref.read(weightRecordRepositoryProvider).create(
          livestockId: livestock.id,
          weight: weight,
          ageDays: ageDays,
          recordedAt: recordedAt,
          notes: 'Berat awal saat registrasi',
        );
      }

      // Create initial health log with status "Sehat"
      try {
        debugPrint('Creating health log for livestock: ${livestock.id}');
        await ref.read(healthNotifierProvider.notifier).create(
          livestockId: livestock.id,
          type: HealthRecordType.checkup,
          title: 'Sehat',
          recordDate: DateTime.now(),
          notes: 'Status kesehatan awal saat registrasi',
        );
        // Invalidate provider to refresh UI
        ref.invalidate(healthByLivestockProvider(livestock.id));
        debugPrint('Health log created successfully');
      } catch (healthError) {
        // Log but don't fail the entire operation
        debugPrint('WARNING: Failed to create initial health log: $healthError');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_generatedCode berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddBreedDialog() {
    final codeController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Ras'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Kode',
                hintText: 'NZW, REX, etc.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama',
                hintText: 'New Zealand White',
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
              if (codeController.text.isEmpty || nameController.text.isEmpty) return;
              
              Navigator.pop(context);
              await ref.read(breedNotifierProvider.notifier).create(
                code: codeController.text.trim(),
                name: nameController.text.trim(),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth > 600 ? 480.0 : screenWidth * 0.92;
    final housingsAsync = ref.watch(availableHousingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final breedsAsync = ref.watch(breedNotifierProvider);

    return Container(
      width: panelWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(-8, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ═══════════════════════════════════════════
          // HEADER
          // ═══════════════════════════════════════════
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tambah Indukan',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'DATA HEWAN BARU',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant, letterSpacing: 0.5),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 22, color: colorScheme.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════
          // FORM CONTENT
          // ═══════════════════════════════════════════
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Gender (Jenis Kelamin)
                    _buildStyledDropdown<Gender>(
                      value: _selectedGender,
                      hint: 'Jenis Kelamin *',
                      icon: Icons.wc,
                      items: Gender.values.map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(g == Gender.female ? 'Betina' : 'Jantan'),
                      )).toList(),
                      onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedGender = value;
                              _selectedStatus = value == Gender.female 
                                  ? 'betina_muda' 
                                  : 'pejantan_muda';
                            });
                            _updateGeneratedCode();
                          }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Status Reproduksi
                    // Status Reproduksi
                    Consumer(
                      builder: (context, ref, _) {
                        final farmId = ref.watch(currentFarmProvider)?.id ?? '';
                        final statusAsync = ref.watch(statusNotifierProvider(farmId));
                        final validStatuses = statusAsync.value?.where((s) => s.isActive && (s.validForGender == 'both' || s.validForGender == _selectedGender.value)).toList() ?? [];

                        return _buildStyledDropdown<String>(
                          value: _selectedStatus,
                          hint: 'Status Reproduksi',
                          icon: Icons.favorite_border,
                          items: validStatuses.map((status) => DropdownMenuItem(
                                value: status.code,
                                child: Text(status.name),
                              )).toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _selectedStatus = value);
                          },
                        );
                      }
                    ),
                    const SizedBox(height: 16),

                    // Ras (Required)
                    breedsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error loading breeds'),
                      data: (breeds) => _buildStyledDropdown<String>(
                        value: _selectedBreedId,
                        hint: 'Ras *',
                        icon: Icons.pets,
                        items: breeds.map((b) => DropdownMenuItem(
                          value: b.id,
                          child: Text(b.displayName),
                        )).toList(),
                        onChanged: (value) {
                          final breed = breeds.firstWhere((b) => b.id == value);
                          setState(() {
                            _selectedBreedId = value;
                            _selectedBreed = breed;
                          });
                          _updateGeneratedCode();
                        },
                        validator: (value) => value == null ? 'Pilih ras' : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Generated Code Preview
                    if (_generatedCode.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFF1F2937), const Color(0xFF374151)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.qr_code_2, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('KODE TERNAK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 1)),
                                const SizedBox(height: 2),
                                Text(_generatedCode, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Kandang (Required)
                    _buildStyledDropdown<String>(
                      value: _selectedHousingId,
                      hint: 'Kandang *',
                      icon: Icons.home_work_outlined,
                      items: housingsAsync.when(
                        loading: () => [],
                        error: (_, __) => [],
                        data: (housings) => housings.map((h) {
                          return DropdownMenuItem(value: h.id, child: Text(h.displayName));
                        }).toList(),
                      ),
                      onChanged: (value) => setState(() => _selectedHousingId = value),
                    ),
                    const SizedBox(height: 16),

                    // Date Fields (Side by side)
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: 'Tanggal Lahir *',
                            icon: Icons.cake_outlined,
                            value: _birthDate,
                            onTap: () => _selectDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateField(
                            label: 'Tgl Beli *',
                            icon: Icons.calendar_today_outlined,
                            value: _acquisitionDate,
                            onTap: () => _selectDate(context, false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Purchase Price (Required - numbers only)
                    _buildStyledTextField(
                      controller: _priceController,
                      label: 'Harga Beli *',
                      icon: Icons.payments_outlined,
                      prefix: 'Rp ',
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                    ),
                    const SizedBox(height: 16),

                    // Weight (Required - numbers and decimal only)
                    _buildStyledTextField(
                      controller: _weightController,
                      label: 'Berat *',
                      icon: Icons.scale_outlined,
                      suffix: 'kg',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    _buildStyledTextField(
                      controller: _notesController,
                      label: 'Catatan (Opsional)',
                      icon: Icons.note_alt_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Error Message (if any)
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ──────────────────────────────────────
                    // SUBMIT BUTTON
                    // ──────────────────────────────────────
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: _isLoading 
                            ? [Colors.grey[400]!, Colors.grey[500]!]
                            : [const Color(0xFF10B981), const Color(0xFF059669)],
                        ),
                        boxShadow: _isLoading ? [] : [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 20),
                                  SizedBox(width: 10),
                                  Text('Simpan Ternak', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildStyledDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    IconData? icon,
    FormFieldValidator<T>? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: colorScheme.onSurfaceVariant, size: 22),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: DropdownButtonFormField<T>(
              value: value,
              decoration: InputDecoration(
                labelText: hint.toUpperCase(),
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: hint.contains('*') ? null : colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              hint: Text(hint.replaceAll(' *', ''), style: TextStyle(color: colorScheme.onSurfaceVariant)),
              items: items,
              onChanged: onChanged,
              validator: validator,
              dropdownColor: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurfaceVariant),
              style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? prefix,
    String? suffix,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
            child: Icon(icon, color: colorScheme.onSurfaceVariant, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              inputFormatters: inputFormatters,
              style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: label.toUpperCase(),
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: prefix ?? (suffix != null ? '0' : null),
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                suffixText: suffix,
                suffixStyle: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.onSurfaceVariant, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(value),
                    style: TextStyle(
                      fontSize: 15,
                      color: value != null ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium Gender Option Card
class _PremiumGenderOption extends StatelessWidget {
  final Gender gender;
  final bool isSelected;
  final VoidCallback onTap;

  const _PremiumGenderOption({
    required this.gender,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFemale = gender == Gender.female;
    final primaryColor = isFemale ? const Color(0xFFEC4899) : const Color(0xFF3B82F6);
    final bgColor = isFemale ? const Color(0xFFFDF2F8) : const Color(0xFFEFF6FF);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : [],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withValues(alpha: 0.15) : const Color(0xFFE5E7EB),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  isFemale ? '♀' : '♂',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? primaryColor : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              gender.displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? primaryColor : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

