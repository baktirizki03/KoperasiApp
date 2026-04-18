import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../widgets/secure_image_widget.dart';

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic> anggota;

  const ProfileEditScreen({super.key, required this.anggota});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  XFile? _imageFile;

  late TextEditingController _namaController;
  late TextEditingController _tempatLahirController;
  late TextEditingController _tanggalLahirController;
  late TextEditingController _alamatController;
  late TextEditingController _teleponController;
  late TextEditingController _noKtpController;
  late TextEditingController _pekerjaanController;
  late TextEditingController _departemenController;
  late TextEditingController _namaBankController;
  late TextEditingController _noRekeningController;
  late TextEditingController _namaIbuKandungController;

  String? _jenisKelaminValue;
  String? _pendidikanValue;
  String? _agamaValue;
  String? _statusPernikahanValue;

  final List<String> _pendidikanOptions = ['SD', 'SMP', 'SMA', 'D3', 'S1', 'S2', 'S3'];
  final List<String> _agamaOptions = ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'];
  final List<String> _statusPernikahanOptions = ['Belum Menikah', 'Menikah', 'Cerai Hidup', 'Cerai Mati'];
  final List<String> _jenisKelaminOptions = ['laki-laki', 'perempuan'];

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.anggota['nama_lengkap']);
    _tempatLahirController = TextEditingController(text: widget.anggota['tempat_lahir']);
    _tanggalLahirController = TextEditingController(text: widget.anggota['tanggal_lahir']);
    _alamatController = TextEditingController(text: widget.anggota['domisili'] ?? widget.anggota['alamat']);
    _teleponController = TextEditingController(text: widget.anggota['no_telepon']);
    _noKtpController = TextEditingController(text: widget.anggota['nomor_ktp']);
    _pekerjaanController = TextEditingController(text: widget.anggota['pekerjaan']);
    _departemenController = TextEditingController(text: widget.anggota['departemen'] ?? '');
    _namaBankController = TextEditingController(text: widget.anggota['nama_bank'] ?? '');
    _noRekeningController = TextEditingController(text: widget.anggota['no_rekening'] ?? '');
    _namaIbuKandungController = TextEditingController(text: widget.anggota['nama_ibu_kandung']);

    void setupDropdown(String? rawValue, List<String> options, Function(String?) setValue) {
      if (rawValue == null || rawValue.isEmpty) {
        setValue(null);
        return;
      }
      String cleanValue = rawValue.toString().trim();
      String? existingOption;
      try {
        existingOption = options.firstWhere((opt) => opt.toLowerCase() == cleanValue.toLowerCase());
      } catch (e) {
        existingOption = null;
      }
      if (existingOption != null) {
        setValue(existingOption);
      } else {
        options.add(cleanValue);
        setValue(cleanValue);
      }
    }

    setupDropdown(widget.anggota['pendidikan'], _pendidikanOptions, (val) => _pendidikanValue = val);
    setupDropdown(widget.anggota['agama'], _agamaOptions, (val) => _agamaValue = val);
    setupDropdown(widget.anggota['status_pernikahan'], _statusPernikahanOptions, (val) => _statusPernikahanValue = val);

    String? rawJK = widget.anggota['jenis_kelamin'];
    if (rawJK != null && rawJK.isNotEmpty) {
      String cleanJK = rawJK.toString().trim();
      bool exists = _jenisKelaminOptions.any((opt) => opt.toLowerCase() == cleanJK.toLowerCase());
      if (!exists) _jenisKelaminOptions.add(cleanJK);
      String? match = _jenisKelaminOptions.firstWhere((opt) => opt.toLowerCase() == cleanJK.toLowerCase(), orElse: () => cleanJK);
      _jenisKelaminValue = match;
    } else {
      _jenisKelaminValue = null;
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) setState(() => _imageFile = pickedFile);
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_imageFile != null) {
          final bytes = await File(_imageFile!.path).readAsBytes();
          await _apiService.uploadProfilePhoto(bytes, _imageFile!.name);
        }
        await _apiService.updateMyProfile({
          'nama_lengkap': _namaController.text,
          'tempat_lahir': _tempatLahirController.text,
          'tanggal_lahir': _tanggalLahirController.text,
          'jenis_kelamin': _jenisKelaminValue!,
          'domisili': _alamatController.text,
          'no_telepon': _teleponController.text,
          'nomor_ktp': _noKtpController.text,
          'pekerjaan': _pekerjaanController.text,
          'departemen': _departemenController.text,
          'nama_bank': _namaBankController.text,
          'no_rekening': _noRekeningController.text,
          'pendidikan': _pendidikanValue ?? '',
          'agama': _agamaValue ?? '',
          'status_pernikahan': _statusPernikahanValue ?? '',
          'nama_ibu_kandung': _namaIbuKandungController.text,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui!'), backgroundColor: Colors.green));
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
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
                  children: [
                    _buildPhotoPicker(),
                    const SizedBox(height: 32),
                    _buildSection('Data Pribadi Utama', [
                      _buildField(controller: _namaController, label: 'Nama Lengkap', icon: Icons.person_rounded),
                      _buildField(controller: _noKtpController, label: 'No. KTP / SIM', icon: Icons.badge_rounded),
                      _buildRowFields(
                        _buildField(controller: _tempatLahirController, label: 'Tempat Lahir', icon: Icons.location_city_rounded),
                        _buildField(controller: _tanggalLahirController, label: 'Tgl Lahir', icon: Icons.cake_rounded, hint: 'YYYY-MM-DD'),
                      ),
                      _buildDropdown('Jenis Kelamin', _jenisKelaminOptions, _jenisKelaminValue, (val) => setState(() => _jenisKelaminValue = val), icon: Icons.wc_rounded),
                    ]),
                    _buildSection('Kontak & Alamat', [
                      _buildField(controller: _alamatController, label: 'Alamat Lengkap', icon: Icons.home_rounded, maxLines: 2),
                      _buildField(controller: _teleponController, label: 'No. Telepon', icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
                    ]),
                    _buildSection('Pekerjaan', [
                      _buildField(controller: _pekerjaanController, label: 'Pekerjaan', icon: Icons.work_rounded),
                      _buildField(controller: _departemenController, label: 'Departemen / Unit Kerja', icon: Icons.business_rounded),
                    ]),
                    _buildSection('Rekening Bank', [
                      _buildField(controller: _namaBankController, label: 'Nama Bank', icon: Icons.account_balance_rounded),
                      _buildField(controller: _noRekeningController, label: 'No. Rekening', icon: Icons.credit_card_rounded, keyboardType: TextInputType.number),
                    ]),
                    _buildSection('Data Tambahan', [
                      _buildDropdown('Pendidikan', _pendidikanOptions, _pendidikanValue, (val) => setState(() => _pendidikanValue = val), icon: Icons.school_rounded),
                      _buildDropdown('Agama', _agamaOptions, _agamaValue, (val) => setState(() => _agamaValue = val), icon: Icons.mosque_rounded),
                      _buildDropdown('Status Pernikahan', _statusPernikahanOptions, _statusPernikahanValue, (val) => setState(() => _statusPernikahanValue = val), icon: Icons.favorite_rounded),
                      _buildField(controller: _namaIbuKandungController, label: 'Nama Ibu Kandung', icon: Icons.family_restroom_rounded),
                    ]),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),
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
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
            const SizedBox(width: 8),
            Text('Edit Profil', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[100],
                child: _imageFile != null
                    ? ClipOval(child: Image.file(File(_imageFile!.path), width: 120, height: 120, fit: BoxFit.cover))
                    : widget.anggota['foto_profile_path'] != null
                        ? ClipOval(child: SecureImageWidget(imageUrl: widget.anggota['foto_profile_path'], width: 120, height: 120, fit: BoxFit.cover))
                        : Icon(Icons.person_rounded, size: 60, color: Colors.grey[400]),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFF0D47A1), shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2))),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1))),
          const SizedBox(height: 16),
          ...children.expand((w) => [w, const SizedBox(height: 16)]).toList()..removeLast(),
        ],
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, String? hint, int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF0D47A1)),
        filled: true,
        fillColor: const Color(0xFFF1F5FF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(16),
      ),
      validator: (v) => v!.isEmpty && label != 'Departemen / Unit Kerja' && label != 'Nama Bank' && label != 'No. Rekening' ? 'Wajib diisi' : null,
    );
  }

  Widget _buildDropdown(String label, List<String> options, String? value, Function(String?) onChanged, {required IconData icon}) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: options.map((s) => DropdownMenuItem(value: s, child: Text(s.contains('-') ? s.toUpperCase() : s, style: GoogleFonts.poppins(fontSize: 14)))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF0D47A1)),
        filled: true,
        fillColor: const Color(0xFFF1F5FF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(16),
      ),
      validator: (v) => v == null ? 'Wajib diisi' : null,
    );
  }

  Widget _buildRowFields(Widget f1, Widget f2) {
    return Row(children: [Expanded(child: f1), const SizedBox(width: 12), Expanded(child: f2)]);
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
            child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Simpan Perubahan', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
