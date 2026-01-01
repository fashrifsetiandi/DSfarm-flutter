/// Currency Input Formatter
/// 
/// TextInputFormatter untuk format angka dengan pemisah ribuan (titik)
/// Contoh: 1000000 -> 1.000.000

import 'package:flutter/services.dart';

/// Formatter yang menambahkan titik sebagai pemisah ribuan
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (newText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Format with dots as thousands separator
    final buffer = StringBuffer();
    final length = newText.length;
    
    for (int i = 0; i < length; i++) {
      buffer.write(newText[i]);
      final remaining = length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    final formatted = buffer.toString();
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Helper function to parse formatted price back to double
double? parseFormattedPrice(String text) {
  if (text.isEmpty) return null;
  final cleaned = text.replaceAll('.', '');
  return double.tryParse(cleaned);
}
