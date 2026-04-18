import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/currency_formatter.dart';

class SimpananFormScreen extends StatefulWidget {
  const SimpananFormScreen({super.key});

  @override
  State<SimpananFormScreen> createState() => _SimpananFormScreenState();
}

class _SimpananFormScreenState extends State<SimpananFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  double _totalSaldo = 0;

  final _nominalController = TextEditingController();
  final _tanggalController = TextEditingController();
  String? _jenisTransaksiValue;
  XFile? _buktiFile;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickFile() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) setState(() => _buktiFile = image);
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _buktiFile != null) {
      setState(() => _isLoading = true);
      try {
        final bytes = await _buktiFile!.readAsBytes();
        await _apiService.ajukanSimpanan({'nominal': _nominalController.text, 'jenis_transaksi': _jenisTransaksiValue!, 'tanggal': _tanggalController.text}, bytes, _buktiFile!.name);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Setoran berhasil diajukan!'), backgroundColor: Colors.green));
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_buktiFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap unggah bukti transfer'), backgroundColor: Colors.orange));
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
                    _buildWalletCard(),
                    const SizedBox(height: 32),
                    _buildFormHeader('Data Setoran'),
                    const SizedBox(height: 16),
                    _buildLabel('Nominal Setoran (Rp)'),
                    _buildField(controller: _nominalController, hint: 'Rp 0', icon: Icons.payments_rounded, keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                    const SizedBox(height: 20),
                    _buildLabel('Jenis Setoran'),
                    _buildDropdown(),
                    const SizedBox(height: 20),
                    _buildLabel('Tanggal Transfer'),
                    _buildField(controller: _tanggalController, hint: 'Pilih Tanggal', icon: Icons.calendar_month_rounded, readOnly: true, onTap: _pickDate, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                    const SizedBox(height: 32),
                    _buildFormHeader('Bukti Transaksi'),
                    const SizedBox(height: 16),
                    _buildUploadBox(),
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
            Text('Setor Simpanan', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF0D47A1).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Saldo Saat Ini', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                Text(formatRupiah(_totalSaldo), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildFormHeader(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436)));
  }

  Widget _buildLabel(String label) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])));
  }

  Widget _buildField({required TextEditingController controller, required String hint, required IconData icon, bool readOnly = false, VoidCallback? onTap, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, size: 20, color: const Color(0xFF0D47A1)), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1))),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _jenisTransaksiValue,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(prefixIcon: const Icon(Icons.category_rounded, size: 20, color: Color(0xFF0D47A1)), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)),
      items: ['Simpanan Wajib', 'Simpanan Sukarela'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: (v) => setState(() => _jenisTransaksiValue = v),
      validator: (v) => v == null ? 'Pilih jenis setoran' : null,
      hint: Text('Pilih Jenis Simpanan', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400])),
    );
  }

  Widget _buildUploadBox() {
    bool hasFile = _buktiFile != null;
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: hasFile ? Colors.green : const Color(0xFF0D47A1).withOpacity(0.1), width: 2, style: BorderStyle.solid)),
        child: Column(
          children: [
            Icon(hasFile ? Icons.check_circle_rounded : Icons.cloud_upload_rounded, size: 40, color: hasFile ? Colors.green : const Color(0xFF0D47A1)),
            const SizedBox(height: 12),
            Text(hasFile ? 'Bukti Terunggah' : 'Ketuk untuk Unggah Bukti', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: hasFile ? Colors.green : const Color(0xFF0D47A1))),
            const SizedBox(height: 4),
            Text(hasFile ? _buktiFile!.name : 'Maksimal 5MB (JPG, PNG)', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
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
            child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Kirim Setoran Sekarang', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
