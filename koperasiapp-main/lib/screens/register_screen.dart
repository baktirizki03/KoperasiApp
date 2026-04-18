import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/register_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _isLoading = false;
  File? _ktpImage;

  // Controllers
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _tempatLahirController = TextEditingController();
  final _tanggalLahirController = TextEditingController();
  final _noKtpController = TextEditingController();
  final _alamatController = TextEditingController();
  final _teleponController = TextEditingController();
  final _pekerjaanController = TextEditingController();
  final _departemenController = TextEditingController();
  final _namaBankController = TextEditingController();
  final _noRekeningController = TextEditingController();
  final _namaIbuKandungController = TextEditingController();

  String? _jenisKelaminValue;
  String? _pendidikanValue;
  String? _agamaValue;
  String? _statusPernikahanValue;
  DateTime? _selectedTanggalLahir;

  final List<String> _jenisKelaminOptions = ['laki-laki', 'perempuan'];
  final List<String> _agamaOptions = [
    'Islam',
    'Kristen',
    'Katolik',
    'Hindu',
    'Buddha',
    'Konghucu',
    'Lainnya',
  ];
  final List<String> _pendidikanOptions = [
    'SD',
    'SMP',
    'SMA/SMK',
    'D3',
    'S1',
    'S2',
    'S3',
    'Lainnya',
  ];
  final List<String> _statusPernikahanOptions = [
    'Belum Menikah',
    'Menikah',
    'Cerai Hidup',
    'Cerai Mati',
  ];

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      bool stepValid = false;
      if (_currentStep == 0) {
        stepValid = _validateStep1();
      } else if (_currentStep == 1) {
        stepValid = _validateStep2();
      } else if (_currentStep == 2) {
        stepValid = _validateStep3();
      }

      if (stepValid) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep++);
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  bool _validateStep1() {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showError('Email tidak valid');
      return false;
    }
    final pwd = _passwordController.text;
    bool isPwdValid = pwd.length >= 8 &&
        pwd.contains(RegExp(r'[A-Z]')) &&
        pwd.contains(RegExp(r'[a-z]')) &&
        pwd.contains(RegExp(r'[0-9]')) &&
        pwd.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!isPwdValid) {
      _showError('Password tidak memenuhi kriteria keamanan');
      return false;
    }
    if (_confirmPasswordController.text != pwd) {
      _showError('Konfirmasi password tidak sama');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_namaController.text.isEmpty) {
      _showError('Nama Lengkap wajib diisi');
      return false;
    }
    if (_noKtpController.text.length < 16) {
      _showError('NIK harus 16 digit');
      return false;
    }
    if (_tempatLahirController.text.isEmpty ||
        _tanggalLahirController.text.isEmpty) {
      _showError('Tempat/Tanggal Lahir wajib diisi');
      return false;
    }
    if (_jenisKelaminValue == null) {
      _showError('Pilih Jenis Kelamin');
      return false;
    }
    if (_alamatController.text.isEmpty) {
      _showError('Alamat Domisili wajib diisi');
      return false;
    }
    if (_teleponController.text.isEmpty) {
      _showError('No. Telepon wajib diisi');
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    if (_pekerjaanController.text.isEmpty) {
      _showError('Pekerjaan wajib diisi');
      return false;
    }
    if (_pendidikanValue == null) {
      _showError('Pilih Pendidikan Terakhir');
      return false;
    }
    if (_agamaValue == null) {
      _showError('Pilih Agama');
      return false;
    }
    if (_statusPernikahanValue == null) {
      _showError('Pilih Status Pernikahan');
      return false;
    }
    if (_namaIbuKandungController.text.isEmpty) {
      _showError('Nama Ibu Kandung wajib diisi');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _ktpImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTanggalLahir ?? DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
      helpText: 'Pilih Tanggal Lahir',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D47A1),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A237E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTanggalLahir = picked;
        _tanggalLahirController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit() async {
    if (_ktpImage == null) {
      _showError('Mohon upload foto KTP Anda');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'nama_lengkap': _namaController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'password_confirmation': _confirmPasswordController.text,
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
      };

      final bytes = await _ktpImage!.readAsBytes();
      final filename = _ktpImage!.path.split('/').last;

      await _apiService.register(data, bytes, filename);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Registrasi Berhasil'),
            content: const Text(
              'Pendaftaran Anda berhasil dikirim.\n\nAkun Anda sedang dalam proses verifikasi oleh Admin (1x24 jam).',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(
            'Gagal Mendaftar: ${e.toString().replaceAll('Exception: ', '')}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF), // Harmonious light blue
      body: Stack(
        children: [
          // --- PREXIUM GRADIENT HEADER ---
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D47A1).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // --- CUSTOM APP BAR ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        onPressed: _previousStep,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getStepTitle(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: StepProgressBar(
                    currentStep: _currentStep + 1,
                    totalSteps: 4,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1().animate().fadeIn().slideX(begin: 0.1, end: 0),
                      _buildStep2().animate().fadeIn().slideX(begin: 0.1, end: 0),
                      _buildStep3().animate().fadeIn().slideX(begin: 0.1, end: 0),
                      _buildStep4().animate().fadeIn().slideX(begin: 0.1, end: 0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomButton(
              text: _currentStep == 3 ? 'Kirim Pendaftaran' : 'Lanjut',
              onPressed: _currentStep == 3 ? _submit : _nextStep,
              isLoading: _isLoading,
              icon: Icons.arrow_forward,
            ),
            const SizedBox(height: 16),
            if (_currentStep == 0)
              _buildTermsText()
            else if (_currentStep == 3)
              Text(
                'Dengan mengetuk tombol, Anda menyetujui Syarat & Ketentuan berlaku.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Pendaftaran Anggota';
      case 1:
        return 'Data Diri';
      case 2:
        return 'Data Lainnya';
      case 3:
        return 'Unggah Identitas';
      default:
        return '';
    }
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildCardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Keamanan',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Langkah awal untuk mengamankan akses akun Anda.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildLabel('Alamat Email'),
            CustomTextField(
              label: 'nama@contoh.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            _buildLabel('Kata Sandi'),
            CustomTextField(
              label: 'Minimal 8 karakter',
              controller: _passwordController,
              obscureText: true,
              icon: Icons.lock_outline,
            ),
            const SizedBox(height: 16),
            _buildLabel('Konfirmasi Kata Sandi'),
            CustomTextField(
              label: 'Ulangi kata sandi',
              controller: _confirmPasswordController,
              obscureText: true,
              icon: Icons.verified_user_outlined,
            ),
            const SizedBox(height: 24),
            SecurityChecklist(password: _passwordController.text),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildCardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identitas Diri',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pastikan data sesuai dengan KTP asli Anda.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildLabel('Nama Lengkap (Sesuai KTP)'),
            CustomTextField(
              label: 'Masukkan nama lengkap Anda',
              controller: _namaController,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildLabel('Nomor KTP (NIK)'),
            CustomTextField(
              label: '16 digit nomor induk kependudukan',
              controller: _noKtpController,
              keyboardType: TextInputType.number,
              icon: Icons.credit_card_outlined,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Tempat Lahir'),
                      CustomTextField(
                        label: 'Kota/Kab',
                        controller: _tempatLahirController,
                        icon: Icons.location_on_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Tanggal Lahir'),
                      GestureDetector(
                        onTap: _pickDate,
                        child: AbsorbPointer(
                          child: CustomTextField(
                            label: 'Pilih Tanggal',
                            controller: _tanggalLahirController,
                            icon: Icons.calendar_today_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel('Jenis Kelamin'),
            _buildDropdown('Pilih jenis kelamin', _jenisKelaminValue,
                _jenisKelaminOptions, (v) => setState(() => _jenisKelaminValue = v)),
            const SizedBox(height: 16),
            _buildLabel('Alamat Domisili Saat Ini'),
            CustomTextField(
              label: 'Contoh: Jl. Merdeka No. 123',
              controller: _alamatController,
              icon: Icons.home_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildLabel('No. Telepon / WhatsApp'),
            CustomTextField(
              label: '08123456789',
              controller: _teleponController,
              keyboardType: TextInputType.phone,
              icon: Icons.phone_outlined,
            ),
            const SizedBox(height: 24),
            const InfoBox(
              text:
                  'Data ini akan diverifikasi oleh sistem kami. Mohon isi dengan benar.',
              icon: Icons.verified_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildCardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Pendukung',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Data pekerjaan dan rekening untuk keperluan transaksi.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildLabel('Pekerjaan'),
            CustomTextField(
              label: 'Contoh: Karyawan Swasta',
              controller: _pekerjaanController,
              icon: Icons.work_outline,
            ),
            const SizedBox(height: 16),
            _buildLabel('Departemen / Unit Kerja'),
            CustomTextField(
              label: 'Contoh: Teknologi Informasi',
              controller: _departemenController,
              icon: Icons.business_outlined,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Nama Bank'),
                      CustomTextField(
                        label: 'BCA / Mandiri',
                        controller: _namaBankController,
                        icon: Icons.account_balance_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('No. Rekening'),
                      CustomTextField(
                        label: '000123456',
                        controller: _noRekeningController,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel('Pendidikan Terakhir'),
            _buildDropdown('Pilih Pendidikan', _pendidikanValue,
                _pendidikanOptions, (v) => setState(() => _pendidikanValue = v)),
            const SizedBox(height: 16),
            _buildLabel('Agama'),
            _buildDropdown('Pilih Agama', _agamaValue, _agamaOptions,
                (v) => setState(() => _agamaValue = v)),
            const SizedBox(height: 16),
            _buildLabel('Status Pernikahan'),
            _buildDropdown('Pilih Status', _statusPernikahanValue,
                _statusPernikahanOptions, (v) => setState(() => _statusPernikahanValue = v)),
            const SizedBox(height: 16),
            _buildLabel('Nama Ibu Kandung'),
            CustomTextField(
              label: 'Sesuai Akta Kelahiran',
              controller: _namaIbuKandungController,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 24),
            const InfoBox(
              text:
                  'Data aman. Kami menggunakan sistem keamanan tingkat tinggi untuk menjaga privasi Anda.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildCardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Langkah Terakhir',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mohon unggah foto KTP asli Anda.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FF),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D47A1).withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: DottedBorderPainter(),
                      child: Container(),
                    ),
                    Center(
                      child: _ktpImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(_ktpImage!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0D47A1).withOpacity(0.1),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    size: 32,
                                    color: const Color(0xFF0D47A1),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Unggah Foto KTP',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                ),
                                Text(
                                  'Format: JPG, PNG (Maks. 5MB)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const PhotoGuide(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF0D47A1).withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50], // Very light grey instead of white for contrast
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint, style: GoogleFonts.poppins(fontSize: 14)),
          isExpanded: true,
          decoration: const InputDecoration(border: InputBorder.none),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Text.rich(
      TextSpan(
        text: 'Dengan mendaftar, Anda menyetujui ',
        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
        children: [
          TextSpan(
            text: 'Syarat & Ketentuan',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
          ),
          const TextSpan(text: ' serta '),
          TextSpan(
            text: 'Kebijakan Privasi',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
          ),
          const TextSpan(text: ' kami.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class DottedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 5;
    const dashSpace = 3;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(20)));

    final dashPath = Path();
    for (final Metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < Metric.length) {
        dashPath.addPath(
          Metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
