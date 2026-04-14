import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Keep image_picker as it's used for _picker
import '../../services/api_service.dart';
import '../../widgets/secure_image_widget.dart'; // New import

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic> anggota;

  const ProfileEditScreen({super.key, required this.anggota});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker(); // New
  bool _isLoading = false;

  XFile? _imageFile; // New

  late TextEditingController _namaController;
  late TextEditingController _tempatLahirController;
  late TextEditingController _tanggalLahirController;
  late TextEditingController _alamatController; // Replaces domisili
  late TextEditingController _teleponController;

  // New Controllers
  late TextEditingController _noKtpController;
  late TextEditingController _pekerjaanController;
  late TextEditingController _departemenController; // New
  late TextEditingController _namaBankController; // New
  late TextEditingController _noRekeningController; // New
  late TextEditingController _namaIbuKandungController;

  String? _jenisKelaminValue;

  // New Dropdown Values
  String? _pendidikanValue;
  String? _agamaValue;
  String? _statusPernikahanValue;

  // Mutable Options Lists
  final List<String> _pendidikanOptions = [
    'SD',
    'SMP',
    'SMA',
    'D3',
    'S1',
    'S2',
    'S3',
  ];
  final List<String> _agamaOptions = [
    'Islam',
    'Kristen',
    'Katolik',
    'Hindu',
    'Buddha',
    'Konghucu',
  ];
  final List<String> _statusPernikahanOptions = [
    'Belum Menikah',
    'Menikah',
    'Cerai Hidup',
    'Cerai Mati',
  ];
  final List<String> _jenisKelaminOptions = ['laki-laki', 'perempuan'];

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(
      text: widget.anggota['nama_lengkap'],
    );
    _tempatLahirController = TextEditingController(
      text: widget.anggota['tempat_lahir'],
    );
    _tanggalLahirController = TextEditingController(
      text: widget.anggota['tanggal_lahir'],
    );
    // Use 'alamat' if available, fallback to 'domisili' to maintain backward compat during transition
    _alamatController = TextEditingController(
      text: widget.anggota['domisili'] ?? widget.anggota['alamat'],
    );
    _teleponController = TextEditingController(
      text: widget.anggota['no_telepon'],
    );

    _noKtpController = TextEditingController(text: widget.anggota['nomor_ktp']);
    _pekerjaanController = TextEditingController(
      text: widget.anggota['pekerjaan'],
    );
    _departemenController = TextEditingController(
      text: widget.anggota['departemen'] ?? '',
    );
    _namaBankController = TextEditingController(
      text: widget.anggota['nama_bank'] ?? '',
    );
    _noRekeningController = TextEditingController(
      text: widget.anggota['no_rekening'] ?? '',
    );
    _namaIbuKandungController = TextEditingController(
      text: widget.anggota['nama_ibu_kandung'],
    );

    // --- Robust Dropdown Initialization ---
    void setupDropdown(
      String? rawValue,
      List<String> options,
      Function(String?) setValue,
    ) {
      if (rawValue == null || rawValue.isEmpty) {
        setValue(null);
        return;
      }
      String cleanValue = rawValue.toString().trim();

      // Case-insensitive match
      String? existingOption;
      try {
        existingOption = options.firstWhere(
          (opt) => opt.toLowerCase() == cleanValue.toLowerCase(),
        );
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

    setupDropdown(
      widget.anggota['pendidikan'],
      _pendidikanOptions,
      (val) => _pendidikanValue = val,
    );
    setupDropdown(
      widget.anggota['agama'],
      _agamaOptions,
      (val) => _agamaValue = val,
    );
    setupDropdown(
      widget.anggota['status_pernikahan'],
      _statusPernikahanOptions,
      (val) => _statusPernikahanValue = val,
    );

    // JK Logic
    String? rawJK = widget.anggota['jenis_kelamin'];
    if (rawJK != null && rawJK.isNotEmpty) {
      String cleanJK = rawJK.toString().trim();
      bool exists = _jenisKelaminOptions.any(
        (opt) => opt.toLowerCase() == cleanJK.toLowerCase(),
      );
      if (!exists) {
        // If "Pria" comes in, add "Pria" to options so it shows up,
        // but typically we want to map it. For safety, just add it.
        _jenisKelaminOptions.add(cleanJK);
      }
      // Since the build() uses value directly as option value, we should use the exact string from options if matched, or the raw one if added.
      String? match = _jenisKelaminOptions.firstWhere(
        (opt) => opt.toLowerCase() == cleanJK.toLowerCase(),
        orElse: () => cleanJK,
      );
      _jenisKelaminValue = match;
    } else {
      _jenisKelaminValue = null;
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Upload photo logic
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
          'departemen': _departemenController.text, // New
          'nama_bank': _namaBankController.text, // New
          'no_rekening': _noRekeningController.text, // New
          'pendidikan': _pendidikanValue ?? '',
          'agama': _agamaValue ?? '',
          'status_pernikahan': _statusPernikahanValue ?? '',
          'nama_ibu_kandung': _namaIbuKandungController.text,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Profile Photo ---
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        child: _imageFile != null
                            ? ClipOval(
                                child: Image.file(
                                  File(_imageFile!.path),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : widget.anggota['foto_profile_path'] != null
                            ? ClipOval(
                                child: SecureImageWidget(
                                  imageUrl: widget.anggota['foto_profile_path'],
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.person_rounded,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Data Pribadi Utama ---
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noKtpController,
                decoration: const InputDecoration(labelText: 'No. KTP / SIM'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tempatLahirController,
                decoration: const InputDecoration(labelText: 'Tempat Lahir'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tanggalLahirController,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Lahir (YYYY-MM-DD)',
                  helperText: 'Contoh: 1990-12-31',
                ),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _jenisKelaminValue,
                items: _jenisKelaminOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.toUpperCase()),
                  );
                }).toList(),
                onChanged: (newValue) =>
                    setState(() => _jenisKelaminValue = newValue),
                decoration: const InputDecoration(labelText: 'Jenis Kelamin'),
                validator: (v) => v == null ? 'Wajib diisi' : null,
              ),

              // --- Kontak & Alamat ---
              const SizedBox(height: 16),
              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(labelText: 'Alamat Lengkap'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _teleponController,
                decoration: const InputDecoration(labelText: 'No. Telepon'),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),

              // --- Data Tambahan ---
              const SizedBox(height: 16),
              TextFormField(
                controller: _pekerjaanController,
                decoration: const InputDecoration(labelText: 'Pekerjaan'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departemenController,
                decoration: const InputDecoration(
                  labelText: 'Departemen / Unit Kerja',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _namaBankController,
                decoration: const InputDecoration(labelText: 'Nama Bank'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noRekeningController,
                decoration: const InputDecoration(labelText: 'No. Rekening'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _pendidikanValue,
                items: _pendidikanOptions
                    .map(
                      (val) => DropdownMenuItem(value: val, child: Text(val)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _pendidikanValue = val),
                decoration: const InputDecoration(
                  labelText: 'Pendidikan Terakhir',
                ),
                validator: (v) => v == null ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _agamaValue,
                items: _agamaOptions
                    .map(
                      (val) => DropdownMenuItem(value: val, child: Text(val)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _agamaValue = val),
                decoration: const InputDecoration(labelText: 'Agama'),
                validator: (v) => v == null ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _statusPernikahanValue,
                items: _statusPernikahanOptions
                    .map(
                      (val) => DropdownMenuItem(value: val, child: Text(val)),
                    )
                    .toList(),
                onChanged: (val) =>
                    setState(() => _statusPernikahanValue = val),
                decoration: const InputDecoration(
                  labelText: 'Status Pernikahan',
                ),
                validator: (v) => v == null ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _namaIbuKandungController,
                decoration: const InputDecoration(
                  labelText: 'Nama Ibu Kandung',
                ),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),

              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Simpan Perubahan'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
