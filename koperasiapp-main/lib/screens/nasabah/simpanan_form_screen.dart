import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class SimpananFormScreen extends StatefulWidget {
  const SimpananFormScreen({super.key});

  @override
  State<SimpananFormScreen> createState() => _SimpananFormScreenState();
}

class _SimpananFormScreenState extends State<SimpananFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  final _nominalController = TextEditingController();
  final _tanggalController = TextEditingController();
  String? _jenisTransaksiValue;
  XFile? _buktiFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nominalController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        _tanggalController.text = formattedDate;
      });
    }
  }

  Future<void> _pickFile() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Compress to 50%
    );
    if (image != null) {
      setState(() {
        _buktiFile = image;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _buktiFile != null) {
      setState(() => _isLoading = true);
      try {
        final bytes = await _buktiFile!.readAsBytes();
        final filename = _buktiFile!.name;

        await _apiService.ajukanSimpanan(
          {
            'nominal': _nominalController.text,
            'jenis_transaksi': _jenisTransaksiValue!,
            'tanggal': _tanggalController.text,
          },
          bytes,
          filename,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Setoran berhasil diajukan!'),
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
    } else if (_buktiFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap unggah bukti transfer'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Setoran Simpanan')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nominalController,
                decoration: const InputDecoration(
                  labelText: 'Nominal Setoran (Rp)',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _jenisTransaksiValue,
                items: ['Simpanan Wajib', 'Simpanan Sukarela']
                    .map(
                      (String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (newValue) =>
                    setState(() => _jenisTransaksiValue = newValue),
                decoration: const InputDecoration(labelText: 'Jenis Setoran'),
                validator: (v) => v == null ? 'Pilih jenis setoran' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tanggalController,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Transfer',
                  hintText: 'Pilih Tanggal',
                ),
                readOnly: true,
                onTap: _pickDate,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Unggah Bukti Transfer'),
              ),
              if (_buktiFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'File: ${_buktiFile!.name}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Kirim Pengajuan'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
