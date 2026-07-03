import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/register_widgets.dart';

class SimpananTarikScreen extends StatefulWidget {
  const SimpananTarikScreen({super.key});

  @override
  State<SimpananTarikScreen> createState() => _SimpananTarikScreenState();
}

class _SimpananTarikScreenState extends State<SimpananTarikScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  double _totalSaldo = 0;

  final _nominalController = TextEditingController();
  final _tanggalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBalance();
    _tanggalController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _fetchBalance() async {
    try {
      final data = await _apiService.getDashboardData();
      setState(() {
        _totalSaldo = double.tryParse(data['total_simpanan'].toString()) ?? 0;
      });
    } catch (e) {}
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
    if (pickedDate != null) {
      setState(() => _tanggalController.text = DateFormat('yyyy-MM-dd').format(pickedDate));
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final nominalClean = _nominalController.text.replaceAll('.', '');
        await _apiService.ajukanPenarikan({'nominal': nominalClean, 'tanggal': _tanggalController.text});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penarikan berhasil diajukan!'), backgroundColor: Colors.green));
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InfoBox(text: 'Penarikan akan diambil dari saldo Tabungan Sukarela Anda. Prosesnya biasanya memakan waktu 1-2 hari kerja.', icon: Icons.info_outline_rounded),
                    const SizedBox(height: 32),
                    _buildFormHeader('Rincian Penarikan'),
                    const SizedBox(height: 16),
                    _buildLabel('Jumlah Penarikan (Rp)'),
                    _buildField(
                        controller: _nominalController,
                        hint: 'e.g. 500.000',
                        icon: Icons.account_balance_wallet_rounded,
                        keyboardType: TextInputType.number,
                        formatters: [ThousandsFormatter()],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Wajib diisi';
                          double? n = double.tryParse(v.replaceAll('.', ''));
                          if (n == null) return 'Harus berupa angka';
                          if (n < 10000) return 'Minimal penarikan Rp 10.000';
                          if (n > _totalSaldo) return 'Saldo tidak mencukupi';
                          return null;
                        }),
                    const SizedBox(height: 20),
                    _buildLabel('Tanggal Penarikan'),
                    _buildField(controller: _tanggalController, hint: 'Pilih Tanggal', icon: Icons.calendar_month_rounded, readOnly: true, onTap: _pickDate, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                    const SizedBox(height: 32),
                    _buildFormHeader('Ringkasan Saldo'),
                    const SizedBox(height: 16),
                    _buildSummaryBox(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(top: 60, bottom: 20, left: 24, right: 24),
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.vertical(bottom: Radius.circular(32))),
        child: Row(
          children: [
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2))),
            const SizedBox(width: 16),
            Text('Tarik Simpanan', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildFormHeader(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436)));
  }

  Widget _buildLabel(String label) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, size: 20, color: const Color(0xFF0D47A1)), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1))),
    );
  }

  Widget _buildSummaryBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF0D47A1).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SALDO TERSEDIA', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  Text(formatRupiah(_totalSaldo), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const Icon(Icons.account_balance_rounded, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Biaya Admin', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.9))),
              Text('GRATIS', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4, shadowColor: const Color(0xFF0D47A1).withOpacity(0.4)),
            child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Konfirmasi Penarikan', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
