import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic> anggota;

  const ProfileEditScreen({super.key, required this.anggota});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  late TextEditingController _namaController;
  late TextEditingController _tempatLahirController;
  late TextEditingController _tanggalLahirController;
  late TextEditingController _alamatController; // Replaces domisili
  late TextEditingController _teleponController;

  // New Controllers
  late TextEditingController _noKtpController;
  late TextEditingController _pekerjaanController;
  late TextEditingController _namaIbuKandungController;

  String? _jenisKelaminValue;

  // New Dropdown Values
  String? _pendidikanValue;
  String? _agamaValue;
  String? _statusPernikahanValue;

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
      text: widget.anggota['alamat'] ?? widget.anggota['domisili'],
    );
    _teleponController = TextEditingController(
      text: widget.anggota['no_telepon'],
    );

    _noKtpController = TextEditingController(text: widget.anggota['no_ktp']);
    _pekerjaanController = TextEditingController(
      text: widget.anggota['pekerjaan'],
    );
    _namaIbuKandungController = TextEditingController(
      text: widget.anggota['nama_ibu_kandung'],
    );

    _jenisKelaminValue = widget.anggota['jenis_kelamin'];
    _pendidikanValue = widget.anggota['pendidikan'];
    _agamaValue = widget.anggota['agama'];
    _statusPernikahanValue = widget.anggota['status_pernikahan'];
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _apiService.updateMyProfile({
          'nama_lengkap': _namaController.text,
          'tempat_lahir': _tempatLahirController.text,
          'tanggal_lahir': _tanggalLahirController.text,
          'jenis_kelamin': _jenisKelaminValue!,
          'alamat': _alamatController.text,
          'no_telepon': _teleponController.text,

          'no_ktp': _noKtpController.text,
          'pekerjaan': _pekerjaanController.text,
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
                value: _jenisKelaminValue,
                items: ['laki-laki', 'perempuan'].map((String value) {
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
              DropdownButtonFormField<String>(
                value: _pendidikanValue,
                items: ['SD', 'SMP', 'SMA', 'D3', 'S1', 'S2', 'S3']
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
                value: _agamaValue,
                items:
                    [
                          'Islam',
                          'Kristen',
                          'Katolik',
                          'Hindu',
                          'Buddha',
                          'Konghucu',
                        ]
                        .map(
                          (val) =>
                              DropdownMenuItem(value: val, child: Text(val)),
                        )
                        .toList(),
                onChanged: (val) => setState(() => _agamaValue = val),
                decoration: const InputDecoration(labelText: 'Agama'),
                validator: (v) => v == null ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _statusPernikahanValue,
                items: ['Belum Menikah', 'Menikah', 'Cerai Hidup', 'Cerai Mati']
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
