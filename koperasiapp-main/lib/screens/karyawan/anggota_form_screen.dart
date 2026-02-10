import 'package:flutter/material.dart';
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
  final List<String> _jenisKelaminOptions = ['Laki-laki', 'Perempuan'];
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

  // Controllers & Values
  late TextEditingController _namaController;
  late TextEditingController _tempatLahirController;
  late TextEditingController _tanggalLahirController;
  String? _jenisKelaminValue;
  late TextEditingController _noKtpController;
  late TextEditingController _alamatController;
  late TextEditingController _teleponController;
  late TextEditingController _pekerjaanController;
  late TextEditingController _departemenController; // New
  late TextEditingController _namaBankController; // New
  late TextEditingController _noRekeningController; // New
  String? _pendidikanValue;
  String? _agamaValue;
  String? _statusPernikahanValue;
  late TextEditingController _namaIbuKandungController;

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
    _tempatLahirController = TextEditingController(
      text: data['tempat_lahir'] ?? '',
    );
    _tanggalLahirController = TextEditingController(
      text: data['tanggal_lahir'] ?? '',
    );
    _jenisKelaminValue = data['jenis_kelamin'];

    // Check if keys exist in incoming data, otherwise empty
    _noKtpController = TextEditingController(text: data['nomor_ktp'] ?? '');
    _alamatController = TextEditingController(
      text: data['alamat'] ?? data['domisili'] ?? '',
    );
    _teleponController = TextEditingController(text: data['no_telepon'] ?? '');
    _pekerjaanController = TextEditingController(text: data['pekerjaan'] ?? '');
    _departemenController = TextEditingController(
      text: data['departemen'] ?? '',
    ); // New
    _namaBankController = TextEditingController(
      text: data['nama_bank'] ?? '',
    ); // New
    _noRekeningController = TextEditingController(
      text: data['no_rekening'] ?? '',
    ); // New

    // --- Robust Dropdown Initialization ---
    // Helper to safely set dropdown value (Trim -> Match Case-Insensitive -> Add if Missing)
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

      // Cari match yang case-insensitive
      String? existingOption;
      try {
        existingOption = options.firstWhere(
          (opt) => opt.toLowerCase() == cleanValue.toLowerCase(),
        );
      } catch (e) {
        existingOption = null;
      }

      if (existingOption != null) {
        setValue(existingOption); // Pakai opsi yang sudah ada (casing sesuai)
      } else {
        options.add(cleanValue); // Tambahkan opsi baru jika tidak ada
        setValue(cleanValue);
      }
    }

    setupDropdown(
      data['pendidikan'],
      _pendidikanOptions,
      (val) => _pendidikanValue = val,
    );
    setupDropdown(data['agama'], _agamaOptions, (val) => _agamaValue = val);
    setupDropdown(
      data['status_pernikahan'],
      _statusPernikahanOptions,
      (val) => _statusPernikahanValue = val,
    );

    // Special Handling for Jenis Kelamin (karena value di build() di-lowercase)
    String? rawJK = data['jenis_kelamin'];
    if (rawJK != null && rawJK.isNotEmpty) {
      String cleanJK = rawJK.toString().trim();
      String lowerJK = cleanJK.toLowerCase();

      // Cek apakah opsi source-nya ada (untuk label)
      bool sourceExists = _jenisKelaminOptions.any(
        (opt) => opt.toLowerCase() == cleanJK.toLowerCase(),
      );

      if (!sourceExists) {
        // Jika tidak ada di source options (misal "Pria"), tambahkan ke source agar ter-render widgetnya
        // Kita tambahkan versi aslinya (Title Case) agar labelnya bagus
        _jenisKelaminOptions.add(cleanJK);
      }

      // Value harus lower karena di build() item.value = value.toLowerCase()
      _jenisKelaminValue = lowerJK;
    } else {
      _jenisKelaminValue = null;
    }

    _namaIbuKandungController = TextEditingController(
      text: data['nama_ibu_kandung'] ?? '',
    );

    _emailController = TextEditingController(
      text: _isEditMode ? (data['user']?['email'] ?? '') : '',
    );
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
    _departemenController.dispose(); // New
    _namaBankController.dispose(); // New
    _noRekeningController.dispose(); // New
    _namaIbuKandungController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      Map<String, String> data = {
        'nama_lengkap': _namaController.text,
        'tempat_lahir': _tempatLahirController.text,
        'tanggal_lahir':
            _tanggalLahirController.text, // Pastikan format YYYY-MM-DD
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
        'email': _emailController.text,
      };

      // Hanya tambahkan password jika diisi (untuk tambah atau ganti password)
      if (_passwordController.text.isNotEmpty) {
        data['password'] = _passwordController.text;
      }

      try {
        if (_isEditMode) {
          // Mode Edit (Update currently doesn't support file upload in this snippet, keeping existing logic for now or updating if needed.
          // User asked for "Add Member" fix. Update might need separate request if we want to support updating KTP too.)
          await _apiService.updateAnggota(widget.anggota!['id'], data);
        } else {
          // Mode Tambah
          if (_ktpFile == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Harap upload foto KTP'),
                backgroundColor: Colors.orange,
              ),
            );
            setState(() => _isLoading = false);
            return;
          }

          final bytes = await _ktpFile!.readAsBytes();
          await _apiService.createAnggota(data, bytes.toList(), _ktpFile!.name);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Kirim 'true' untuk menandakan sukses
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Anggota' : 'Tambah Anggota'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Data Diri'),
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(labelText: 'Nama Lengkap'),
                validator: (value) =>
                    value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tempatLahirController,
                      decoration: InputDecoration(labelText: 'Tempat Lahir'),
                      validator: (value) => value!.isEmpty
                          ? 'Tempat lahir tidak boleh kosong'
                          : null,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _tanggalLahirController,
                      decoration: InputDecoration(
                        labelText: 'Tanggal Lahir',
                        hintText: 'YYYY-MM-DD',
                      ),
                      keyboardType: TextInputType.datetime,
                      validator: (value) => value!.isEmpty
                          ? 'Tanggal lahir tidak boleh kosong'
                          : null,
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                initialValue: _jenisKelaminValue,
                decoration: InputDecoration(labelText: 'Jenis Kelamin'),
                items: _jenisKelaminOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value.toLowerCase(), // Store lowercase value
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) =>
                    setState(() => _jenisKelaminValue = newValue),
                validator: (value) =>
                    (value == null) ? 'Pilih jenis kelamin' : null,
              ),
              TextFormField(
                controller: _noKtpController,
                decoration: InputDecoration(labelText: 'No KTP/SIM'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'No KTP/SIM tidak boleh kosong' : null,
              ),
              const SizedBox(height: 10),
              if (!_isEditMode) ...[
                const Text(
                  'Foto KTP',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final XFile? image = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 50,
                    );
                    if (image != null) {
                      setState(() {
                        _ktpFile = image;
                      });
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: _ktpFile != null
                        ? Image.file(File(_ktpFile!.path), fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey,
                              ),
                              Text('Tap untuk upload KTP'),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TextFormField(
                controller: _alamatController,
                decoration: InputDecoration(labelText: 'Alamat'),
                maxLines: 2,
                validator: (value) =>
                    value!.isEmpty ? 'Alamat tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _teleponController,
                decoration: InputDecoration(labelText: 'No Telp/HP'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? 'No telepon tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _pekerjaanController,
                decoration: InputDecoration(labelText: 'Pekerjaan/Usaha'),
                validator: (value) =>
                    value!.isEmpty ? 'Pekerjaan tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _departemenController, // New
                decoration: InputDecoration(labelText: 'Departemen/Unit Kerja'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _namaBankController, // New
                      decoration: InputDecoration(labelText: 'Nama Bank'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _noRekeningController, // New
                      decoration: InputDecoration(labelText: 'No Rekening'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _pendidikanValue,
                decoration: InputDecoration(labelText: 'Pendidikan'),
                items: _pendidikanOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) =>
                    setState(() => _pendidikanValue = newValue),
                validator: (value) =>
                    (value == null) ? 'Pilih pendidikan' : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _agamaValue,
                decoration: InputDecoration(labelText: 'Agama'),
                items: _agamaOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => _agamaValue = newValue),
                validator: (value) => (value == null) ? 'Pilih agama' : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _statusPernikahanValue,
                decoration: InputDecoration(labelText: 'Status Pernikahan'),
                items: _statusPernikahanOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) =>
                    setState(() => _statusPernikahanValue = newValue),
                validator: (value) =>
                    (value == null) ? 'Pilih status pernikahan' : null,
              ),
              TextFormField(
                controller: _namaIbuKandungController,
                decoration: InputDecoration(labelText: 'Nama Ibu/Bapa Kandung'),
                validator: (value) => value!.isEmpty
                    ? 'Nama Ibu/Bapa Kandung tidak boleh kosong'
                    : null,
              ),

              SizedBox(height: 20),
              _buildSectionTitle('Akun Pengguna'),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isEditMode,
                validator: (value) =>
                    value!.isEmpty ? 'Email tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: _isEditMode
                      ? 'Kosongkan jika tidak ingin diubah'
                      : null,
                ),
                obscureText: true,
                validator: (value) {
                  if (!_isEditMode && (value == null || value.isEmpty)) {
                    return 'Password tidak boleh kosong';
                  }
                  return null;
                },
              ),

              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('Simpan Data Anggota'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
