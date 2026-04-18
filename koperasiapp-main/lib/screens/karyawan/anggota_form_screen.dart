import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/api_service.dart';

class AnggotaFormScreen extends StatefulWidget {
  final Map<String, dynamic>? anggota;

  const AnggotaFormScreen({super.key, this.anggota});

  @override
  _AnggotaFormScreenState createState() => _AnggotaFormScreenState();
}

class _AnggotaFormScreenState extends State<AnggotaFormScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Dropdown Options
  final List<String> _jenisKelaminOptions = ['LAKI-LAKI', 'PEREMPUAN'];
  final List<String> _agamaOptions = ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu', 'Lainnya'];
  final List<String> _pendidikanOptions = ['SD', 'SMP', 'SMA/SMK', 'D3', 'S1', 'S2', 'S3', 'Lainnya'];
  final List<String> _statusPernikahanOptions = ['Belum Menikah', 'Menikah', 'Cerai Hidup', 'Cerai Mati'];

  // Controllers & Values
  late TextEditingController _namaController;
  late TextEditingController _tempatLahirController;
  late TextEditingController _tanggalLahirController;
  String? _jenisKelaminValue;
  late TextEditingController _noKtpController;
  late TextEditingController _alamatController;
  late TextEditingController _teleponController;
  late TextEditingController _pekerjaanController;
  late TextEditingController _departemenController;
  late TextEditingController _namaBankController;
  late TextEditingController _noRekeningController;
  String? _pendidikanValue;
  String? _agamaValue;
  String? _statusPernikahanValue;
  late TextEditingController _namaIbuKandungController;
  DateTime? _selectedTanggalLahir;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  bool _isEditMode = false;
  bool _isLoading = false;
  XFile? _ktpFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.anggota != null;
    final data = widget.anggota ?? {};

    _namaController = TextEditingController(text: data['nama_lengkap'] ?? '');
    _tempatLahirController = TextEditingController(text: data['tempat_lahir'] ?? '');
    _tanggalLahirController = TextEditingController(text: data['tanggal_lahir'] ?? '');
    
    if (data['tanggal_lahir'] != null && data['tanggal_lahir'].toString().isNotEmpty) {
      try { _selectedTanggalLahir = DateTime.parse(data['tanggal_lahir']); } catch (_) { _selectedTanggalLahir = null; }
    }
    _jenisKelaminValue = data['jenis_kelamin'];
    _noKtpController = TextEditingController(text: data['nomor_ktp'] ?? '');
    _alamatController = TextEditingController(text: data['alamat'] ?? data['domisili'] ?? '');
    _teleponController = TextEditingController(text: data['no_telepon'] ?? '');
    _pekerjaanController = TextEditingController(text: data['pekerjaan'] ?? '');
    _departemenController = TextEditingController(text: data['departemen'] ?? '');
    _namaBankController = TextEditingController(text: data['nama_bank'] ?? '');
    _noRekeningController = TextEditingController(text: data['no_rekening'] ?? '');

    void setupDropdown(String? rawValue, List<String> options, Function(String?) setValue) {
      if (rawValue == null || rawValue.isEmpty) { setValue(null); return; }
      String cleanValue = rawValue.toString().trim();
      String? existingOption;
      try {
        existingOption = options.firstWhere((opt) => opt.toLowerCase() == cleanValue.toLowerCase());
      } catch (e) { existingOption = null; }
      if (existingOption != null) { setValue(existingOption); } 
      else { options.add(cleanValue); setValue(cleanValue); }
    }

    setupDropdown(data['pendidikan'], _pendidikanOptions, (val) => _pendidikanValue = val);
    setupDropdown(data['agama'], _agamaOptions, (val) => _agamaValue = val);
    setupDropdown(data['status_pernikahan'], _statusPernikahanOptions, (val) => _statusPernikahanValue = val);

    String? rawJK = data['jenis_kelamin'];
    if (rawJK != null && rawJK.isNotEmpty) {
      String cleanJK = rawJK.toString().trim();
      if (!_jenisKelaminOptions.any((opt) => opt.toLowerCase() == cleanJK.toLowerCase())) {
        _jenisKelaminOptions.add(cleanJK);
      }
      _jenisKelaminValue = cleanJK.toLowerCase();
    }

    _namaIbuKandungController = TextEditingController(text: data['nama_ibu_kandung'] ?? '');
    _emailController = TextEditingController(text: _isEditMode ? (data['user']?['email'] ?? '') : '');
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _tempatLahirController.dispose();
    _tanggalLahirController.dispose();
    _noKtpController.dispose();
    _alamatController.dispose();
    _teleponController.dispose();
    _pekerjaanController.dispose();
    _departemenController.dispose();
    _namaBankController.dispose();
    _noRekeningController.dispose();
    _namaIbuKandungController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTanggalLahir ?? DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF0D47A1))),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedTanggalLahir = picked;
        _tanggalLahirController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      Map<String, String> data = {
        'nama_lengkap': _namaController.text,
        'tempat_lahir': _tempatLahirController.text,
        'tanggal_lahir': _tanggalLahirController.text,
        'jenis_kelamin': _jenisKelaminValue!,
        'nomor_ktp': _noKtpController.text,
        'domisili': _alamatController.text,
        'no_telepon': _teleponController.text,
        'pekerjaan': _pekerjaanController.text,
        'departemen': _departemenController.text,
        'nama_bank': _namaBankController.text,
        'no_rekening': _noRekeningController.text,
        'pendidikan': _pendidikanValue!,
        'agama': _agamaValue!,
        'status_pernikahan': _statusPernikahanValue!,
        'nama_ibu_kandung': _namaIbuKandungController.text,
        'email': _emailController.text,
      };
      if (_passwordController.text.isNotEmpty) { data['password'] = _passwordController.text; }

      try {
        if (_isEditMode) { await _apiService.updateAnggota(widget.anggota!['id'], data); } 
        else {
          if (_ktpFile == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap upload foto KTP'), backgroundColor: Colors.orange));
            setState(() => _isLoading = false);
            return;
          }
          final bytes = await _ktpFile!.readAsBytes();
          await _apiService.createAnggota(data, bytes.toList(), _ktpFile!.name);
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil disimpan'), backgroundColor: Colors.green));
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e'), backgroundColor: Colors.red));
      } finally { setState(() => _isLoading = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- PREMIUM HEADER ---
            _buildHeader(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // --- IDENTITAS SECTION ---
                    _buildFormSection(
                      title: 'Data Identitas',
                      icon: Icons.badge_outlined,
                      children: [
                        _buildInputField(
                          controller: _namaController,
                          label: 'Nama Lengkap',
                          icon: Icons.person_outline_rounded,
                          validator: (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildInputField(
                              controller: _tempatLahirController,
                              label: 'Tempat Lahir',
                              icon: Icons.location_on_outlined,
                              validator: (v) => v!.isEmpty ? 'Tempat lahir wajib diisi' : null,
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: GestureDetector(
                              onTap: _pickDate,
                              child: AbsorbPointer(child: _buildInputField(
                                controller: _tanggalLahirController,
                                label: 'Tanggal Lahir',
                                icon: Icons.calendar_today_rounded,
                                readOnly: true,
                              )),
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownField(
                          value: _jenisKelaminValue,
                          label: 'Jenis Kelamin',
                          icon: Icons.wc_outlined,
                          options: _jenisKelaminOptions,
                          onChanged: (v) => setState(() => _jenisKelaminValue = v),
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _noKtpController,
                          label: 'Nomor NIK/KTP',
                          icon: Icons.credit_card_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'NIK wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _alamatController,
                          label: 'Alamat Lengkap',
                          icon: Icons.home_outlined,
                          maxLines: 2,
                          validator: (v) => v!.isEmpty ? 'Alamat wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _teleponController,
                          label: 'Nomor WhatsApp',
                          icon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v!.isEmpty ? 'Nomor telepon wajib diisi' : null,
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 16),

                    // --- UPLOAD SECTION ---
                    if (!_isEditMode) 
                    _buildFormSection(
                      title: 'Unggah Dokumen',
                      icon: Icons.cloud_upload_outlined,
                      children: [
                        _buildPhotoUploadArea(),
                      ],
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 16),

                    // --- PEKERJAAN & BANK SECTION ---
                    _buildFormSection(
                      title: 'Pekerjaan & Rekening',
                      icon: Icons.work_outline_rounded,
                      children: [
                        _buildInputField(controller: _pekerjaanController, label: 'Pekerjaan', icon: Icons.work_history_outlined),
                        const SizedBox(height: 12),
                        _buildInputField(controller: _departemenController, label: 'Departemen/Unit', icon: Icons.business_outlined),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildInputField(controller: _namaBankController, label: 'Nama Bank', icon: Icons.account_balance_outlined)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildInputField(controller: _noRekeningController, label: 'No Rekening', icon: Icons.numbers_rounded, keyboardType: TextInputType.number)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownField(
                          value: _pendidikanValue,
                          label: 'Pendidikan Terakhir',
                          icon: Icons.school_outlined,
                          options: _pendidikanOptions,
                          onChanged: (v) => setState(() => _pendidikanValue = v),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildDropdownField(
                              value: _agamaValue,
                              label: 'Agama',
                              icon: Icons.church_outlined,
                              options: _agamaOptions,
                              onChanged: (v) => setState(() => _agamaValue = v),
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: _buildDropdownField(
                              value: _statusPernikahanValue,
                              label: 'Status',
                              icon: Icons.people_outline_rounded,
                              options: _statusPernikahanOptions,
                              onChanged: (v) => setState(() => _statusPernikahanValue = v),
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(controller: _namaIbuKandungController, label: 'Nama Ibu Kandung', icon: Icons.family_restroom_outlined),
                      ],
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 16),

                    // --- AKUN SECTION ---
                    _buildFormSection(
                      title: 'Akses Akun Anggota',
                      icon: Icons.lock_outline_rounded,
                      children: [
                        _buildInputField(
                          controller: _emailController,
                          label: 'Email Anggota',
                          icon: Icons.email_outlined,
                          enabled: !_isEditMode,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v!.isEmpty ? 'Email wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.key_outlined,
                          obscureText: true,
                          hint: _isEditMode ? 'Kosongkan jika tidak diubah' : null,
                          validator: (v) => (!_isEditMode && (v == null || v.isEmpty)) ? 'Password wajib diisi' : null,
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 40),

                    // --- SUBMIT BUTTON ---
                    _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: const Color(0xFF0D47A1).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              _isEditMode ? 'SIMPAN PERUBAHAN' : 'TAMBAH ANGGOTA BARU',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ).animate().scale(delay: 400.ms),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Text(
            _isEditMode ? 'Rubah Data Anggota' : 'Anggota Baru',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF0D47A1)),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF0D47A1), size: 16),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      items: options.map((opt) => DropdownMenuItem(
        value: opt.toLowerCase(), 
        child: Text(
          opt, 
          style: GoogleFonts.poppins(fontSize: 12),
          overflow: TextOverflow.ellipsis,
        )
      )).toList(),
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0D47A1), size: 16),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      ),
      validator: (v) => v == null ? 'Wajib dipilih' : null,
    );
  }

  Widget _buildPhotoUploadArea() {
    return InkWell(
      onTap: () async {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
        if (image != null) setState(() => _ktpFile = image);
      },
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade100, style: BorderStyle.solid, width: 2),
        ),
        child: _ktpFile != null
          ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(File(_ktpFile!.path), fit: BoxFit.cover))
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.blue.shade300),
                const SizedBox(height: 12),
                Text('Ketuk untuk Unggah KTP', style: GoogleFonts.poppins(color: Colors.blue.shade400, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
      ),
    );
  }
}
