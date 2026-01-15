import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class NasabahPinjamanDetailScreen extends StatefulWidget {
  final int pinjamanId;

  const NasabahPinjamanDetailScreen({super.key, required this.pinjamanId});

  @override
  State<NasabahPinjamanDetailScreen> createState() =>
      _NasabahPinjamanDetailScreenState();
}

class _NasabahPinjamanDetailScreenState
    extends State<NasabahPinjamanDetailScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  late Future<Map<String, dynamic>> _pinjamanDetailFuture;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() {
    setState(() {
      _pinjamanDetailFuture = _apiService.getMyPinjamanDetail(
        widget.pinjamanId,
      );
    });
  }

  Future<void> _konfirmasiBayar(int angsuranId) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mengirim bukti bayar...')));

      final bytes = await image.readAsBytes();
      await _apiService.confirmAngsuran(angsuranId, bytes, image.name);

      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi terkirim!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadDetail();
    } catch (e) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pinjaman')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _pinjamanDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Data tidak ditemukan.'));
          }

          final pinjaman = snapshot.data!;
          final angsurans = pinjaman['angsurans'] as List;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: ListTile(
                    title: Text('Rp ${pinjaman['nominal']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${pinjaman['status'].toUpperCase()}'),
                        const Divider(),
                        Text(
                          'Keperluan: ${pinjaman['untuk_keperluan'] ?? '-'}',
                        ),
                        Text('Tenor: ${pinjaman['tenor_cicilan']} bulan'),
                        if (pinjaman['departemen_pekerjaan'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Departemen: ${pinjaman['departemen_pekerjaan']}',
                          ),
                          Text(
                            'Pendapatan: Rp ${pinjaman['pendapatan_per_bulan']}',
                          ),
                          Text(
                            'Bank: ${pinjaman['nama_bank']} (${pinjaman['no_rekening']})',
                          ),
                          Text('Alamat: ${pinjaman['alamat_tempat_tinggal']}'),
                        ],
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Jadwal Angsuran',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: angsurans.length,
                  itemBuilder: (ctx, index) {
                    final angsuran = angsurans[index];
                    final status = angsuran['status'];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${angsuran['angsuran_ke']}'),
                        ),
                        title: Text('Rp ${angsuran['jumlah_bayar']}'),
                        subtitle: Text(
                          'Jatuh Tempo: ${angsuran['tanggal_jatuh_tempo']}',
                        ),
                        trailing: (status == 'belum_lunas')
                            ? ElevatedButton(
                                onPressed: () =>
                                    _konfirmasiBayar(angsuran['id']),
                                child: const Text('Bayar'),
                              )
                            : Chip(
                                label: Text(status.toUpperCase()),
                                backgroundColor: status == 'lunas'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
