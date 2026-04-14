import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

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
  final _departemenController = TextEditingController(); // New
  final _namaBankController = TextEditingController(); // New
  final _noRekeningController = TextEditingController(); // New
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
  void dispose() {
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
    _departemenController.dispose(); // New
    _namaBankController.dispose(); // New
    _noRekeningController.dispose(); // New
    _namaIbuKandungController.dispose();
    super.dispose();
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
      cancelText: 'Batal',
      confirmText: 'Pilih',
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
        // Format to YYYY-MM-DD for the backend
        _tanggalLahirController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ktpImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon upload foto KTP Anda'),
          backgroundColor: Colors.red,
        ),
      );
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
        'departemen': _departemenController.text, // New
        'nama_bank': _namaBankController.text, // New
        'no_rekening': _noRekeningController.text, // New
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
            title: const Text('Registrasi Berhasil'),
            content: const Text(
              'Pendaftaran Anda berhasil dikirim.\n\nAkun Anda sedang dalam proses verifikasi oleh Admin (1x24 jam). Anda belum dapat login hingga verifikasi selesai.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // Close dialog
                  Navigator.of(context).pop(); // Back to Login Screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal Mendaftar: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pendaftaran Anggota Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Data Akun'),
              CustomTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                icon: Icons.email,
                validator: (v) =>
                    v!.isEmpty || !v.contains('@') ? 'Email tidak valid' : null,
              ),
              CustomTextField(
                label: 'Password',
                controller: _passwordController,
                obscureText: true,
                icon: Icons.lock,
                validator: (v) => v!.length < 8 ? 'Min 8 karakter' : null,
              ),
              CustomTextField(
                label: 'Konfirmasi Password',
                controller: _confirmPasswordController,
                obscureText: true,
                icon: Icons.lock_outline,
                validator: (v) => v != _passwordController.text
                    ? 'Password tidak sama'
                    : null,
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Data Pribadi'),
              CustomTextField(
                label: 'Nama Lengkap (Sesuai KTP)',
                controller: _namaController,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Tempat Lahir',
                      controller: _tempatLahirController,
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _tanggalLahirController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: _selectedTanggalLahir == null
                                ? 'Tanggal Lahir'
                                : 'Tanggal Lahir',
                            hintText: 'Pilih tanggal',
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            suffixIcon: const Icon(
                              Icons.calendar_today_rounded,
                              color: Color(0xFF0D47A1),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Pilih tanggal' : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              _buildDropdown(
                'Jenis Kelamin',
                _jenisKelaminValue,
                _jenisKelaminOptions,
                (v) => setState(() => _jenisKelaminValue = v),
              ),
              CustomTextField(
                label: 'Nomor KTP (NIK)',
                controller: _noKtpController,
                keyboardType: TextInputType.number,
                validator: (v) => v!.length < 16 ? 'NIK harus 16 digit' : null,
              ),
              CustomTextField(
                label: 'Alamat Domisili',
                controller: _alamatController,
                maxLines: 2,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              CustomTextField(
                label: 'No. Telepon / WA',
                controller: _teleponController,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Data Lainnya'),
              CustomTextField(
                label: 'Pekerjaan',
                controller: _pekerjaanController,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              CustomTextField(
                label: 'Departemen / Unit Kerja', // New
                controller: _departemenController,
                validator: (v) => null, // Optional
              ),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Nama Bank', // New
                      controller: _namaBankController,
                      validator: (v) => null, // Optional
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
                      label: 'No. Rekening', // New
                      controller: _noRekeningController,
                      keyboardType: TextInputType.number,
                      validator: (v) => null, // Optional
                    ),
                  ),
                ],
              ),
              _buildDropdown(
                'Pendidikan Terakhir',
                _pendidikanValue,
                _pendidikanOptions,
                (v) => setState(() => _pendidikanValue = v),
              ),
              _buildDropdown(
                'Agama',
                _agamaValue,
                _agamaOptions,
                (v) => setState(() => _agamaValue = v),
              ),
              _buildDropdown(
                'Status Pernikahan',
                _statusPernikahanValue,
                _statusPernikahanOptions,
                (v) => setState(() => _statusPernikahanValue = v),
              ),
              CustomTextField(
                label: 'Nama Ibu Kandung',
                controller: _namaIbuKandungController,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Upload KTP'),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _ktpImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_ktpImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.grey,
                            ),
                            Text('Tap untuk upload foto KTP'),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 30),
              CustomButton(
                text: 'DAFTAR SEKARANG',
                onPressed: _submit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A237E), // Dark Navy
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          // Theme handles border and fill
        ),
        icon: const Icon(
          Icons.arrow_drop_down_circle,
          color: Color(0xFF1A237E),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? 'Pilih $label' : null,
      ),
    );
  }
}
