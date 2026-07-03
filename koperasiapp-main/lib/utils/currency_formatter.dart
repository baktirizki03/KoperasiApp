import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Shared currency formatter for the entire app.
/// Formats a number to Indonesian Rupiah format: Rp 1.500.000
/// Usage: formatRupiah(1500000) => "Rp 1.500.000"
String formatRupiah(dynamic amount) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  if (amount == null) return 'Rp 0';
  final value = double.tryParse(amount.toString()) ?? 0;
  return formatter.format(value);
}

class ThousandsFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Strip everything except digits
    String cleanedText = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (cleanedText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Parse to number
    final number = int.tryParse(cleanedText) ?? 0;

    // Format with Indonesian locale (adds dot as thousands separator)
    final formattedText = _formatter.format(number);

    // Calculate selection offset so that cursor doesn't jump incorrectly
    int selectionIndex = formattedText.length;
    
    // Count digits in the new value before the cursor
    String newText = newValue.text;
    
    int newCursor = newValue.selection.end;
    int digitsBeforeNewCursor = 0;
    for (int i = 0; i < newCursor && i < newText.length; i++) {
      if (RegExp(r'\d').hasMatch(newText[i])) {
        digitsBeforeNewCursor++;
      }
    }
    
    // Map digitsBeforeNewCursor to the formattedText index
    int formattedCursorIndex = 0;
    int digitsFound = 0;
    while (formattedCursorIndex < formattedText.length && digitsFound < digitsBeforeNewCursor) {
      if (RegExp(r'\d').hasMatch(formattedText[formattedCursorIndex])) {
        digitsFound++;
      }
      formattedCursorIndex++;
    }
    
    selectionIndex = formattedCursorIndex;
    if (selectionIndex > formattedText.length) {
      selectionIndex = formattedText.length;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

