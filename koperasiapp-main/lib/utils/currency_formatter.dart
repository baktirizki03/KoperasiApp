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
