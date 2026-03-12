import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:koperasiapp/services/api_service.dart';

class BungaSettingFormScreen extends StatefulWidget {
  final Map<String, dynamic>? setting;

  const BungaSettingFormScreen({super.key, this.setting});

  @override
  State<BungaSettingFormScreen> createState() => _BungaSettingFormScreenState();
}

class _BungaSettingFormScreenState extends State<BungaSettingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  late TextEditingController _tenorController;
  late TextEditingController _rateController;

  String _formatInitialCurrency(String? value) {
    if (value == null || value.isEmpty) return '';
    try {
      // API might return '1000000.00' due to decimal(15,2) in DB.
      // We only take the integer part before the dot.
      String intPart = value.split('.')[0];
      final intVal = int.parse(intPart.replaceAll(RegExp(r'[^0-9]'), ''));
      return CurrencyTextInputFormatter.currency(
        locale: 'id',
        symbol: '',
        decimalDigits: 0,
      ).formatString(intVal.toString());
    } catch (e) {
      return value;
    }
  }

  @override
  void initState() {
    super.initState();
    _minAmountController = TextEditingController(
      text: _formatInitialCurrency(widget.setting?['min_amount']?.toString()),
    );
    _maxAmountController = TextEditingController(
      text: _formatInitialCurrency(widget.setting?['max_amount']?.toString()),
    );
    _tenorController = TextEditingController(
      text: widget.setting?['tenor']?.toString() ?? '',
    );
    _rateController = TextEditingController(
      text: widget.setting?['rate']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _tenorController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Remove formatting (. and ,) before sending to API
    final rawMinAmount = _minAmountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final rawMaxAmount = _maxAmountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final data = {
      'min_amount': rawMinAmount,
      'max_amount': rawMaxAmount,
      'tenor': _tenorController.text,
      'rate': _rateController.text,
    };

    try {
      if (widget.setting == null) {
        await _apiService.createBungaSetting(data);
      } else {
        await _apiService.updateBungaSetting(widget.setting!['id'], data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan berhasil disimpan')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildDecoration(String label, {String? helperText}) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      labelStyle: GoogleFonts.poppins(),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.setting != null;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Pengaturan Bunga' : 'Tambah Pengaturan Bunga',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _minAmountController,
                        decoration: _buildDecoration('Minimal Pinjaman (Rp)'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          CurrencyTextInputFormatter.currency(
                            locale: 'id',
                            symbol: '',
                            decimalDigits: 0,
                          ),
                        ],
                        validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _maxAmountController,
                        decoration: _buildDecoration('Maksimal Pinjaman (Rp)'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          CurrencyTextInputFormatter.currency(
                            locale: 'id',
                            symbol: '',
                            decimalDigits: 0,
                          ),
                        ],
                        validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tenorController,
                        decoration: _buildDecoration('Tenor (Bulan)'),
                        keyboardType: TextInputType.number,
                        validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _rateController,
                        decoration: _buildDecoration(
                          'Bunga (%) per Total Pinjaman',
                          helperText: 'Contoh: 10 untuk 10%',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(isEdit ? 'Simpan Perubahan' : 'Buat Pengaturan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
