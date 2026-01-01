/// Sell Offspring Dialog
/// 
/// Dialog for selling an offspring with price input.

library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/offspring.dart';
import '../../../providers/offspring_provider.dart';
import '../../../core/utils/currency_formatter.dart';

class SellOffspringDialog extends ConsumerStatefulWidget {
  final Offspring offspring;

  const SellOffspringDialog({super.key, required this.offspring});

  static Future<bool?> show(BuildContext context, Offspring offspring) {
    return showDialog<bool>(
      context: context,
      builder: (context) => SellOffspringDialog(offspring: offspring),
    );
  }

  @override
  ConsumerState<SellOffspringDialog> createState() => _SellOffspringDialogState();
}

class _SellOffspringDialogState extends ConsumerState<SellOffspringDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _saleDate = DateTime.now();
  bool _isLoading = false;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSell() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final priceText = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final price = double.parse(priceText);

      await ref.read(offspringNotifierProvider.notifier).sellOffspring(
        offspringId: widget.offspring.id,
        salePrice: price,
        saleDate: _saleDate,
        description: _descriptionController.text.trim().isEmpty
            ? 'Penjualan ${widget.offspring.code}'
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.offspring.code} terjual ${_currencyFormat.format(price)}'),
            backgroundColor: Colors.green,
          ),
        );
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
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.sell, color: Colors.green),
          const SizedBox(width: 8),
          Text('Jual ${widget.offspring.code}'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(widget.offspring.genderIcon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.offspring.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${widget.offspring.ageFormatted} • ${widget.offspring.breedName ?? ""}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Price
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Harga Jual *',
                prefixText: 'Rp ',
                hintText: '50.000',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Harga wajib diisi';
                final num = parseFormattedPrice(value);
                if (num == null || num <= 0) return 'Harga harus lebih dari 0';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Tanggal Jual'),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_saleDate)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _saleDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _saleDate = date);
              },
            ),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                hintText: 'Jual ke Pak Budi',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleSell,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          icon: _isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.sell),
          label: const Text('Jual'),
        ),
      ],
    );
  }
}
