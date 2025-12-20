/// Create Livestock Screen
/// 
/// Form untuk menambah indukan/pejantan baru.
/// Kode auto-generate berdasarkan ras dan gender: [BREED]-[J/B][SEQ]

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/livestock.dart';
import '../../../models/breed.dart';
import '../../../providers/livestock_provider.dart';
import '../../../providers/housing_provider.dart';
import '../../../providers/breed_provider.dart';
import '../../../providers/farm_provider.dart';

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
      await ref.read(livestockNotifierProvider.notifier).create(
        code: _generatedCode,
        gender: _selectedGender,
        housingId: _selectedHousingId,
        breedId: _selectedBreedId,
        birthDate: _birthDate,
        acquisitionDate: _acquisitionDate,
        acquisitionType: _selectedAcquisition,
        purchasePrice: _priceController.text.isEmpty 
            ? null 
            : double.tryParse(_priceController.text),
        weight: _weightController.text.isEmpty 
            ? null 
            : double.tryParse(_weightController.text),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

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
                        setState(() => _selectedGender = Gender.female);
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
                        setState(() => _selectedGender = Gender.male);
                        _updateGeneratedCode();
                      },
                    ),
                  ),
                ],
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
