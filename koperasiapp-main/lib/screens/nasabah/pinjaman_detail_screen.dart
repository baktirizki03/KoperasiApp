import 'package:flutter/material.dart';
import '../../utils/currency_formatter.dart';
import '../../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'pinjaman_form_screen.dart';

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

      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konfirmasi terkirim!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
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
          // final angsurans = pinjaman['angsurans'] as List;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: ListTile(
                    title: Text(formatRupiah(pinjaman['nominal'])),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${pinjaman['status'].toUpperCase()}'),
                        if (pinjaman['status'] == 'ditolak' &&
                            pinjaman['alasan_penolakan'] != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Alasan Penolakan:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pinjaman['alasan_penolakan'],
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (pinjaman['status'] == 'perlu_perbaikan') ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Permintaan Perbaikan:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pinjaman['alasan_penolakan'] ?? '-',
                                  style: const TextStyle(color: Colors.orange),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (ctx) => PinjamanFormScreen(
                                            pinjaman: pinjaman,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadDetail();
                                      }
                                    },
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Perbaiki Pengajuan'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Divider(),
                        Text(
                          'Keperluan: ${pinjaman['untuk_keperluan'] ?? '-'}',
                        ),
                        Text('Tenor: ${pinjaman['tenor_cicilan']} bulan'),
                        const SizedBox(height: 8),
                        Text(
                          'Departemen: ${pinjaman['departemen_pekerjaan'] ?? '-'}',
                        ),
                        Text(
                          'Pendapatan: ${formatRupiah(pinjaman['pendapatan_per_bulan'])}',
                        ),
                        Text(
                          'Bank: ${pinjaman['nama_bank'] ?? '-'} (${pinjaman['no_rekening'] ?? '-'})',
                        ),
                        Text(
                          'Alamat: ${pinjaman['alamat_tempat_tinggal'] ?? '-'}',
                        ),
                      ],
                    ),
                  ),
                ),
                if (pinjaman['angsurans'] != null) ...[
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      'Jadwal Angsuran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildAngsuranList(pinjaman['angsurans'] as List),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAngsuranList(List<dynamic> angsurans) {
    if (angsurans.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Belum ada data angsuran.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: angsurans.length,
      itemBuilder: (context, index) {
        final angsuran = angsurans[index];
        final isPaid = angsuran['status'] == 'lunas';
        final isPending = angsuran['status'] == 'menunggu_konfirmasi';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPaid
                  ? Colors.green
                  : isPending
                  ? Colors.orange
                  : Colors.red,
              child: Icon(
                isPaid
                    ? Icons.check
                    : isPending
                    ? Icons.hourglass_top
                    : Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text('Angsuran ke-${angsuran['angsuran_ke']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jatuh Tempo: ${DateFormat('dd MMM yyyy').format(DateTime.parse(angsuran['tanggal_jatuh_tempo']))}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Nominal: ${formatRupiah(angsuran['jumlah_bayar'])}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (angsuran['status'] == 'ditolak' && angsuran['alasan_penolakan'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Revisi: ${angsuran['alasan_penolakan']}',
                      style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            trailing: isPaid
                ? const Text(
                    'LUNAS',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : isPending
                ? const Text(
                    'DIPROSES',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : ElevatedButton(
                    onPressed: () => _konfirmasiBayar(angsuran['id']),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(60, 30),
                      backgroundColor: angsuran['status'] == 'ditolak' ? Colors.red : null,
                    ),
                    child: Text(angsuran['status'] == 'ditolak' ? 'Perbaiki' : 'Bayar', style: const TextStyle(fontSize: 12)),
                  ),
          ),
        );
      },
    );
  }
}
