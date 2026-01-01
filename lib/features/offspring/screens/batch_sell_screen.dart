/// Batch Sell Screen
/// 
/// Screen untuk jual banyak anakan sekaligus.

library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/offspring.dart';
import '../../../providers/offspring_provider.dart';
import '../../../core/utils/currency_formatter.dart';

class BatchSellScreen extends ConsumerStatefulWidget {
  const BatchSellScreen({super.key});

  @override
  ConsumerState<BatchSellScreen> createState() => _BatchSellScreenState();
}

class _BatchSellScreenState extends ConsumerState<BatchSellScreen> {
  final Map<String, double> _prices = {};
  final Set<String> _selected = {};
  bool _isLoading = false;

  double get _totalPrice => _selected.fold(0.0, (sum, id) => sum + (_prices[id] ?? 0));
  int get _selectedCount => _selected.length;

  Future<void> _handleSell() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 anakan')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(offspringNotifierProvider.notifier);
      
      for (final id in _selected) {
        await notifier.sellOffspring(
          offspringId: id,
          salePrice: _prices[id] ?? 0,
          description: 'Penjualan batch',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_selectedCount anakan berhasil dijual!'),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offspringsAsync = ref.watch(offspringNotifierProvider);
    final currencyFormat = NumberFormat('#,###', 'id');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jual Anakan (Batch)'),
      ),
      body: offspringsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (offsprings) {
          // Filter only ready-to-sell
          final sellable = offsprings
              .where((o) => o.status == OffspringStatus.readySell)
              .toList();

          if (sellable.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.child_care, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Tidak ada anakan siap jual'),
                  SizedBox(height: 8),
                  Text('Ubah status ke "Siap Jual" terlebih dahulu',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sellable.length,
                  itemBuilder: (context, index) {
                    final o = sellable[index];
                    final isSelected = _selected.contains(o.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selected.add(o.id);
                            } else {
                              _selected.remove(o.id);
                            }
                          });
                        },
                        title: Row(
                          children: [
                            Text(
                              o.genderIcon,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(o.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    '${o.ageFormatted}${o.weight != null ? ' • ${o.weight}kg' : ''}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextField(
                            keyboardType: TextInputType.number,
                            inputFormatters: [ThousandsSeparatorInputFormatter()],
                            decoration: const InputDecoration(
                              labelText: 'Harga',
                              prefixText: 'Rp ',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              _prices[o.id] = parseFormattedPrice(val) ?? 0;
                              setState(() {});
                            },
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  },
                ),
              ),

              // Bottom summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total: $_selectedCount ekor',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Rp ${currencyFormat.format(_totalPrice)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleSell,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.sell),
                          label: Text(_isLoading ? 'Menjual...' : 'Jual Semua'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
