import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AnggotaFormScreen extends StatefulWidget {
  final Map<String, dynamic>? anggota;

  AnggotaFormScreen({this.anggota});

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
  String? _pendidikanValue;
  String? _agamaValue;
  String? _statusPernikahanValue;
  late TextEditingController _namaIbuKandungController;

  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  bool _isEditMode = false;
  bool _isLoading = false;

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
    _noKtpController = TextEditingController(text: data['no_ktp'] ?? '');
    _alamatController = TextEditingController(
      text: data['alamat'] ?? data['domisili'] ?? '',
    );
    _teleponController = TextEditingController(text: data['no_telepon'] ?? '');
    _pekerjaanController = TextEditingController(text: data['pekerjaan'] ?? '');

    _pendidikanValue = data['pendidikan'];
    _agamaValue = data['agama'];
    _statusPernikahanValue = data['status_pernikahan'];

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
        'no_ktp': _noKtpController.text,
        'alamat': _alamatController.text,
        'no_telepon': _teleponController.text,
        'pekerjaan': _pekerjaanController.text,
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
          // Mode Edit
          await _apiService.updateAnggota(widget.anggota!['id'], data);
        } else {
          // Mode Tambah
          await _apiService.createAnggota(data);
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
                value: _jenisKelaminValue,
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

              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _pendidikanValue,
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
                value: _agamaValue,
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
                value: _statusPernikahanValue,
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
