import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';

class PinjamanFormScreen extends StatefulWidget {
  final Map<String, dynamic>? pinjaman;

  const PinjamanFormScreen({super.key, this.pinjaman});

  @override
  State<PinjamanFormScreen> createState() => _PinjamanFormScreenState();
}

class _PinjamanFormScreenState extends State<PinjamanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  int _currentStep = 0; // 0: Form, 1: Documents

  final _pendapatanController = TextEditingController();
  final _saudaraController = TextEditingController();
  final _teleponSaudaraController = TextEditingController();
  final _alamatSaudaraController = TextEditingController();
  final _keperluanController = TextEditingController();
  final _nominalController = TextEditingController();
  final _bankController = TextEditingController();
  final _noRekeningController = TextEditingController();

  String? _tenorValue;
  final List<String> _tenorOptions = ['3', '6', '10', '12'];

  XFile? _slipGajiFile;
  XFile? _kkFile;
  XFile? _idKaryawanFile;
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    if (widget.pinjaman != null) {
      _populateForm();
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await _apiService.getMyProfile();
      setState(() {
        _userProfile = profile;
        if (_bankController.text.isEmpty && profile['anggota'] != null) {
          _bankController.text = profile['anggota']['nama_bank'] ?? '';
        }
        if (_noRekeningController.text.isEmpty && profile['anggota'] != null) {
          _noRekeningController.text = profile['anggota']['no_rekening'] ?? '';
        }
      });
    } catch (e) {
      debugPrint('Failed to fetch profile: $e');
    }
  }

  void _populateForm() {
    final p = widget.pinjaman!;
    _pendapatanController.text = p['pendapatan_per_bulan']?.toString() ?? '';
    _saudaraController.text = p['nama_saudara_terdekat'] ?? '';
    _teleponSaudaraController.text = p['no_telepon_saudara'] ?? '';
    _alamatSaudaraController.text = p['alamat_tempat_tinggal'] ?? '';
    _keperluanController.text = p['untuk_keperluan'] ?? '';
    _nominalController.text = p['nominal']?.toString() ?? '';
    _tenorValue = p['tenor_cicilan']?.toString();
    _bankController.text = p['nama_bank'] ?? '';
    _noRekeningController.text = p['no_rekening'] ?? '';
  }

  @override
  void dispose() {
    _pendapatanController.dispose();
    _saudaraController.dispose();
    _teleponSaudaraController.dispose();
    _alamatSaudaraController.dispose();
    _keperluanController.dispose();
    _nominalController.dispose();
    _bankController.dispose();
    _noRekeningController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String type, ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 50);

    if (image != null) {
      setState(() {
        if (type == 'slip_gaji') _slipGajiFile = image;
        else if (type == 'kk') _kkFile = image;
        else if (type == 'id_karyawan') _idKaryawanFile = image;
      });
    }
  }

  void _showImageSourceActionSheet(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Ambil Foto'), onTap: () { Navigator.pop(context); _pickFile(type, ImageSource.camera); }),
              ListTile(leading: const Icon(Icons.photo_library), title: const Text('Pilih dari Galeri'), onTap: () { Navigator.pop(context); _pickFile(type, ImageSource.gallery); }),
            ],
          ),
        );
      },
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (widget.pinjaman == null) {
        if (_slipGajiFile == null || _kkFile == null || _idKaryawanFile == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap unggah semua dokumen yang diperlukan'), backgroundColor: Colors.orange));
          return;
        }
      }

      setState(() => _isLoading = true);
      try {
        final data = {
          'pendapatan_per_bulan': _pendapatanController.text,
          'nama_saudara_terdekat': _saudaraController.text,
          'no_telepon_saudara': _teleponSaudaraController.text,
          'alamat_tempat_tinggal': _alamatSaudaraController.text,
          'untuk_keperluan': _keperluanController.text,
          'nominal': _nominalController.text,
          'tenor_cicilan': _tenorValue!,
          'nama_bank': _bankController.text,
          'no_rekening': _noRekeningController.text,
        };

        final Map<String, List<int>> fileBytes = {};
        final Map<String, String> fileNames = {};

        if (_slipGajiFile != null) { fileBytes['slip_gaji'] = await _slipGajiFile!.readAsBytes(); fileNames['slip_gaji'] = _slipGajiFile!.name; }
        if (_kkFile != null) { fileBytes['foto_kk'] = await _kkFile!.readAsBytes(); fileNames['foto_kk'] = _kkFile!.name; }
        if (_idKaryawanFile != null) { fileBytes['foto_id_karyawan'] = await _idKaryawanFile!.readAsBytes(); fileNames['foto_id_karyawan'] = _idKaryawanFile!.name; }

        dynamic response;
        if (widget.pinjaman != null) {
          response = await _apiService.updatePinjaman(widget.pinjaman!['id'], data, fileBytes, fileNames);
        } else {
          response = await _apiService.ajukanPinjaman(data, fileBytes, fileNames);
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Berhasil dikirim'), backgroundColor: Colors.green));
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildHeader(),
                SliverToBoxAdapter(
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _currentStep == 0 ? null : _buildBottomAction(),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(top: 60, bottom: 32, left: 24, right: 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => _currentStep == 1 ? setState(() => _currentStep = 0) : Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
                ),
                const SizedBox(width: 16),
                Text(
                  _currentStep == 0 ? 'Pengajuan Pinjaman' : 'Dokumen Pendukung',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _currentStep == 0 ? 0.5 : 1.0,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('DATA FINANSIAL', 'Langkah 1/3'),
        _buildFormCard([
          _buildInputField(
            controller: _pendapatanController,
            label: 'Pendapatan Per Bulan',
            icon: Icons.account_balance_wallet_rounded,
            hint: '0',
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            prefixText: 'Rp ',
          ),
        ]),
        const SizedBox(height: 24),
        _buildSectionHeader('KONTAK DARURAT', 'Langkah 2/3'),
        _buildFormCard([
          _buildInputField(controller: _saudaraController, label: 'Nama Saudara Terdekat', icon: Icons.person_rounded, hint: 'Nama Sesuai KTP'),
          const SizedBox(height: 16),
          _buildInputField(controller: _teleponSaudaraController, label: 'No. Telepon', icon: Icons.phone_rounded, hint: '08xxxxxxxxxx', keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _buildInputField(controller: _alamatSaudaraController, label: 'Alamat Lengkap', icon: Icons.location_on_rounded, hint: 'Alamat tempat tinggal saudara', maxLines: 2),
        ]),
        const SizedBox(height: 24),
        _buildSectionHeader('INFORMASI REKENING', 'Langkah 3/3'),
        _buildFormCard([
          _buildInputField(controller: _bankController, label: 'Nama Bank Penerima', icon: Icons.account_balance_rounded, hint: 'BCA, BNI, Mandiri, dll'),
          const SizedBox(height: 16),
          _buildInputField(controller: _noRekeningController, label: 'Nomor Rekening', icon: Icons.numbers_rounded, hint: 'Masukkan No. Rekening', keyboardType: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly]),
        ]),
        const SizedBox(height: 24),
        _buildSectionHeader('DETAIL PINJAMAN', 'Konfirmasi'),
        _buildFormCard([
          _buildDropdownField(label: 'Tujuan Pinjaman', icon: Icons.info_rounded, value: _keperluanController.text.isEmpty ? null : _keperluanController.text, items: ['Modal Usaha', 'Pendidikan', 'Renovasi', 'Kesehatan', 'Kebutuhan Mendesak', 'Lainnya'], onChanged: (v) => setState(() => _keperluanController.text = v!)),
          const SizedBox(height: 16),
          _buildInputField(controller: _nominalController, label: 'Jumlah Pinjaman', icon: Icons.monetization_on_rounded, hint: '0', keyboardType: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly], prefixText: 'Rp '),
          const SizedBox(height: 16),
          _buildDropdownField(label: 'Tenor (Bulan)', icon: Icons.calendar_month_rounded, value: _tenorValue, items: _tenorOptions, onChanged: (v) => setState(() => _tenorValue = v!)),
        ]),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () { if (_formKey.currentState!.validate()) setState(() => _currentStep = 1); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Lanjut ke Dokumen', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)), const SizedBox(width: 8), const Icon(Icons.arrow_forward_rounded, size: 20)]),
          ),
        ),
        const SizedBox(height: 40),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDocCard(title: 'KTP (Terintegrasi)', subtitle: 'Identitas utama Anda', status: _getKtpStatus(), icon: Icons.badge_rounded, canChange: false),
        _buildDocCard(title: 'Slip Gaji', subtitle: 'Slip gaji 1 bulan terakhir', status: _slipGajiFile != null ? 'Terunggah' : 'Wajib', icon: Icons.receipt_long_rounded, onEdit: () => _showImageSourceActionSheet(context, 'slip_gaji'), file: _slipGajiFile),
        _buildDocCard(title: 'Kartu Keluarga', subtitle: 'Foto lembar asli KK', status: _kkFile != null ? 'Terunggah' : 'Wajib', icon: Icons.family_restroom_rounded, onEdit: () => _showImageSourceActionSheet(context, 'kk'), file: _kkFile),
        _buildDocCard(title: 'ID Karyawan', subtitle: 'Kartu tanda anggota', status: _idKaryawanFile != null ? 'Terunggah' : 'Wajib', icon: Icons.badge_outlined, onEdit: () => _showImageSourceActionSheet(context, 'id_karyawan'), file: _idKaryawanFile),
        const SizedBox(height: 40),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF0D47A1).withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))]),
      child: Column(children: children),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon, required String hint, String? prefixText, TextInputType keyboardType = TextInputType.text, List<TextInputFormatter>? formatters, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 16, color: const Color(0xFF0D47A1)), const SizedBox(width: 8), Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800], letterSpacing: 0.5))]),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.normal),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            prefixStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
            filled: true,
            fillColor: const Color(0xFFF8F9FF),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField({required String label, required IconData icon, required String? value, required List<String> items, required Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 16, color: const Color(0xFF0D47A1)), const SizedBox(width: 8), Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]))]),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8F9FF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
          items: items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: onChanged,
          validator: (v) => (v == null) ? 'Harp pilih $label' : null,
        ),
      ],
    );
  }

  Widget _buildDocCard({required String title, required String subtitle, required String status, required IconData icon, VoidCallback? onEdit, XFile? file, bool canChange = true}) {
    bool isUploaded = status == 'Terunggah' || status == 'Berhasil';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isUploaded ? Colors.green.withOpacity(0.2) : Colors.transparent), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF8F9FF), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: const Color(0xFF0D47A1), size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          if (canChange)
            IconButton(onPressed: onEdit, icon: Icon(isUploaded ? Icons.check_circle_rounded : Icons.cloud_upload_rounded, color: isUploaded ? Colors.green : const Color(0xFF0D47A1)))
          else
            const Icon(Icons.verified_rounded, color: Colors.blue, size: 20),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: Text(widget.pinjaman != null ? 'Simpan Perubahan' : 'Ajukan Sekarang', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 12, color: const Color(0xFF0D47A1), letterSpacing: 1.2)),
          Text(step, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  String _getKtpStatus() {
    if (_userProfile == null) return 'Belum Ada';
    final verified = _userProfile!['anggota']?['is_ktp_verified'];
    return (verified == 1 || verified == true || verified.toString() == '1') ? 'Berhasil' : 'Proses';
  }
}
