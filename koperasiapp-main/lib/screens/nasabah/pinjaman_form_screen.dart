import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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

  final _pendapatanController = TextEditingController();
  final _saudaraController = TextEditingController();
  final _teleponSaudaraController = TextEditingController();
  final _alamatController = TextEditingController();
  final _keperluanController = TextEditingController();
  final _nominalController = TextEditingController();

  String? _tenorValue;
  final List<String> _tenorOptions = ['3', '6', '12', '24'];

  XFile? _slipGajiFile;
  XFile? _kkFile;
  XFile? _idKaryawanFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.pinjaman != null) {
      _populateForm();
    }
  }

  void _populateForm() {
    final p = widget.pinjaman!;
    _pendapatanController.text = p['pendapatan_per_bulan']?.toString() ?? '';
    _saudaraController.text = p['nama_saudara_terdekat'] ?? '';
    _teleponSaudaraController.text = p['no_telepon_saudara'] ?? '';
    _alamatController.text = p['alamat_tempat_tinggal'] ?? '';
    _keperluanController.text = p['untuk_keperluan'] ?? '';
    _nominalController.text = p['nominal']?.toString() ?? '';
    _tenorValue = p['tenor_cicilan']?.toString();
  }

  @override
  void dispose() {
    _pendapatanController.dispose();
    _saudaraController.dispose();
    _teleponSaudaraController.dispose();
    _alamatController.dispose();
    _keperluanController.dispose();
    _nominalController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String type) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image != null) {
      setState(() {
        if (type == 'slip_gaji') {
          _slipGajiFile = image;
        } else if (type == 'kk') {
          _kkFile = image;
        } else if (type == 'id_karyawan') {
          _idKaryawanFile = image;
        }
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Validate files only if NEW submission
      if (widget.pinjaman == null) {
        if (_slipGajiFile == null ||
            _kkFile == null ||
            _idKaryawanFile == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Harap unggah semua dokumen yang diperlukan'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      setState(() => _isLoading = true);
      try {
        final data = {
          'pendapatan_per_bulan': _pendapatanController.text,
          'nama_saudara_terdekat': _saudaraController.text,
          'no_telepon_saudara': _teleponSaudaraController.text,
          'alamat_tempat_tinggal': _alamatController.text,
          'untuk_keperluan': _keperluanController.text,
          'nominal': _nominalController.text,
          'tenor_cicilan': _tenorValue!,
        };

        final Map<String, List<int>> fileBytes = {};
        final Map<String, String> fileNames = {};

        if (_slipGajiFile != null) {
          fileBytes['slip_gaji'] = await _slipGajiFile!.readAsBytes();
          fileNames['slip_gaji'] = _slipGajiFile!.name;
        }
        if (_kkFile != null) {
          fileBytes['foto_kk'] = await _kkFile!.readAsBytes();
          fileNames['foto_kk'] = _kkFile!.name;
        }
        if (_idKaryawanFile != null) {
          fileBytes['foto_id_karyawan'] = await _idKaryawanFile!.readAsBytes();
          fileNames['foto_id_karyawan'] = _idKaryawanFile!.name;
        }

        dynamic response;
        if (widget.pinjaman != null) {
          // Update / Revision
          response = await _apiService.updatePinjaman(
            widget.pinjaman!['id'],
            data,
            fileBytes,
            fileNames,
          );
        } else {
          // New Submission
          response = await _apiService.ajukanPinjaman(
            data,
            fileBytes,
            fileNames,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Berhasil dikirim'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: type,
        inputFormatters: formatters,
        maxLines: maxLines,
        validator:
            validator ??
            (value) => (value == null || value.isEmpty)
                ? '$label tidak boleh kosong'
                : null,
      ),
    );
  }

  Widget _buildFilePicker(String label, XFile? file, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => _pickFile(type),
          icon: const Icon(Icons.upload_file),
          label: Text(file == null ? label : 'Ganti $label'),
        ),
        if (file != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: Text(
              'File terpilih: ${file.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.green),
            ),
          )
        else
          const SizedBox(height: 16.0),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pinjaman != null
              ? 'Perbaiki Pengajuan'
              : 'Form Pengajuan Pinjaman',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _pendapatanController,
                label: 'Pendapatan Per Bulan',
                type: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              _buildTextField(
                controller: _saudaraController,
                label: 'Nama Saudara Terdekat',
              ),
              _buildTextField(
                controller: _teleponSaudaraController,
                label: 'No. Telepon Saudara',
                type: TextInputType.phone,
                formatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              _buildTextField(
                controller: _alamatController,
                label: 'Alamat Saudara Terdekat',
                maxLines: 2,
              ),
              _buildTextField(
                controller: _keperluanController,
                label: 'Untuk Keperluan',
              ),
              _buildTextField(
                controller: _nominalController,
                label: 'Jumlah Pinjaman (Rp)',
                type: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              DropdownButtonFormField<String>(
                initialValue: _tenorValue,
                decoration: const InputDecoration(
                  labelText: 'Tenor (Bulan)',
                  border: OutlineInputBorder(),
                ),
                items: _tenorOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _tenorValue = newValue;
                  });
                },
                validator: (value) => (value == null) ? 'Pilih tenor' : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Dokumen Pendukung',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (widget.pinjaman != null)
                const Text(
                  "Biarkan kosong jika tidak ingin mengubah dokumen",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              const SizedBox(height: 8),

              _buildFilePicker(
                'Unggah Slip Gaji Terbaru',
                _slipGajiFile,
                'slip_gaji',
              ),
              _buildFilePicker('Upload Foto KK', _kkFile, 'kk'),
              _buildFilePicker(
                'Upload Foto ID Karyawan',
                _idKaryawanFile,
                'id_karyawan',
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: widget.pinjaman != null
                        ? Colors.orange
                        : null,
                  ),
                  child: Text(
                    widget.pinjaman != null
                        ? 'Kirim Perbaikan'
                        : 'Ajukan Sekarang',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
