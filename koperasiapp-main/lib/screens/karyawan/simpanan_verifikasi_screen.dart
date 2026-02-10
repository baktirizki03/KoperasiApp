import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class SimpananVerifikasiScreen extends StatefulWidget {
  const SimpananVerifikasiScreen({super.key});

  @override
  State<SimpananVerifikasiScreen> createState() =>
      _SimpananVerifikasiScreenState();
}

class _SimpananVerifikasiScreenState extends State<SimpananVerifikasiScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _simpananFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _simpananFuture = _apiService.getSimpananPending();
    });
  }

  Future<void> _approveSimpanan(int id) async {
    try {
      await _apiService.approveSimpanan(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simpanan berhasil disetujui'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyetujui: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImage(String path, String title) {
    final imageUrl = '${_apiService.storageUrl}/$path';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                          Text('Gagal memuat gambar'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> simpanan) {
    final anggota = simpanan['anggota'];
    final isKetua =
        Provider.of<AuthProvider>(context, listen: false).role == 'ketua';

    // Check flow based on 'tipe' (kredit/debet)
    // NOTE: DB uses 'tipe' for flow (kredit/debet) and 'jenis_transaksi' for category
    final isKredit = simpanan['tipe']?.toString().toLowerCase() == 'kredit';
    final tipeLabel = isKredit
        ? "Uang Masuk (Setoran)"
        : "Uang Keluar (Penarikan)";
    final categoryLabel = simpanan['jenis_transaksi'] ?? '-';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isKredit ? 'Detail Setoran' : 'Detail Penarikan'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Nama: ${anggota['nama_lengkap'] ?? 'N/A'}'),
              Text('Email: ${anggota['user']['email'] ?? 'N/A'}'),
              const Divider(),
              Text('Nominal: Rp ${simpanan['nominal'] ?? 0}'),
              Text(
                'Tipe: $tipeLabel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isKredit ? Colors.green : Colors.red,
                ),
              ),
              Text('Kategori: $categoryLabel'),
              Text(
                'Tanggal: ${simpanan['tanggal'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(simpanan['tanggal'])) : 'N/A'}',
              ),
              const Divider(),
              if (!isKredit) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50], // Light red background for attention
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'REKENING TUJUAN TRANSFER',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${anggota['nama_bank'] ?? '-'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${anggota['no_rekening'] ?? '-'}',
                        style: const TextStyle(fontSize: 18, letterSpacing: 1),
                      ),
                      Text('a.n. ${anggota['nama_lengkap'] ?? '-'}'),
                      if (anggota['departemen'] != null &&
                          anggota['departemen'].toString().isNotEmpty)
                        Text(
                          'Dept: ${anggota['departemen']}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
              if (isKredit) ...[
                const SizedBox(height: 16),
                const Text(
                  'Bukti Transfer:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (simpanan['bukti_transfer_path'] != null)
                  InkWell(
                    onTap: () => _showImage(
                      simpanan['bukti_transfer_path'],
                      'Bukti Transfer',
                    ),
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(
                            '${_apiService.storageUrl}/${simpanan['bukti_transfer_path']}',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                else
                  const Text('Tidak ada bukti transfer.'),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Tutup'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          if (!isKetua)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isKredit ? Colors.green : Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Setujui'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _approveSimpanan(simpanan['id']);
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Simpanan')),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: FutureBuilder<List<dynamic>>(
          future: _simpananFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('Tidak ada setoran yang perlu diverifikasi.'),
              );
            }

            final simpananList = snapshot.data!;
            return ListView.builder(
              itemCount: simpananList.length,
              itemBuilder: (ctx, index) {
                final simpanan = simpananList[index];
                final anggota = simpanan['anggota'];

                final isKredit =
                    simpanan['tipe']?.toString().toLowerCase() == 'kredit';
                final label = isKredit ? "Setoran" : "Penarikan";

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isKredit
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      child: Icon(
                        isKredit ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isKredit ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      anggota != null
                          ? anggota['nama_lengkap']
                          : 'Nama tidak ada',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rp ${simpanan['nominal']}'),
                        Text(
                          '$label - ${simpanan['jenis_transaksi']}',
                          style: TextStyle(
                            color: isKredit
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDetailDialog(simpanan),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
