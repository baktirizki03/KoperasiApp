import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';

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
      String intPart = value.split('.')[0];
      final intVal = int.parse(intPart.replaceAll(RegExp(r'[^0-9]'), ''));
      return CurrencyTextInputFormatter.currency(locale: 'id', symbol: '', decimalDigits: 0).formatString(intVal.toString());
    } catch (e) {
      return value;
    }
  }

  @override
  void initState() {
    super.initState();
    _minAmountController = TextEditingController(text: _formatInitialCurrency(widget.setting?['min_amount']?.toString()));
    _maxAmountController = TextEditingController(text: _formatInitialCurrency(widget.setting?['max_amount']?.toString()));
    _tenorController = TextEditingController(text: widget.setting?['tenor']?.toString() ?? '');
    _rateController = TextEditingController(text: widget.setting?['rate']?.toString() ?? '');
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

    final rawMinAmount = _minAmountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final rawMaxAmount = _maxAmountController.text.replaceAll(RegExp(r'[^0-9]'), '');

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan berhasil disimpan'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.setting != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Bunga' : 'Tambah Bunga', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderDecoration(isEdit),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                    children: [
                    const SizedBox(height: 16),
                    _buildFormCard(),
                    const SizedBox(height: 32),
                    _buildSaveButton(isEdit),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderDecoration(bool isEdit) {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFF0D47A1),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Center(
        child: Text(
          isEdit ? 'Perbarui Aturan Pinjaman' : 'Atur Suku Bunga Baru',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _rateController,
            label: 'Suku Bunga (%)',
            hint: 'Contoh: 10',
            icon: Icons.percent_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _tenorController,
            label: 'Tenor (Bulan)',
            hint: 'Contoh: 12',
            icon: Icons.calendar_month_rounded,
            keyboardType: TextInputType.number,
            validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _minAmountController,
            label: 'Minimal Pinjaman (Rp)',
            hint: 'Mulai dari...',
            icon: Icons.money_rounded,
            keyboardType: TextInputType.number,
            formatters: [CurrencyTextInputFormatter.currency(locale: 'id', symbol: '', decimalDigits: 0)],
            validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _maxAmountController,
            label: 'Maksimal Pinjaman (Rp)',
            hint: 'Hingga...',
            icon: Icons.account_balance_wallet_rounded,
            keyboardType: TextInputType.number,
            formatters: [CurrencyTextInputFormatter.currency(locale: 'id', symbol: '', decimalDigits: 0)],
            validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    List<dynamic>? formatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters?.cast<CurrencyTextInputFormatter>(),
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF0D47A1), size: 20),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool isEdit) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0xFF0D47A1).withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(isEdit ? 'Simpan Perubahan' : 'Buat Pengaturan', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }
}
