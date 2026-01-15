import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  void _showDetailDialog(Map<String, dynamic> simpanan) {
    final anggota = simpanan['anggota'];
    final isKetua =
        Provider.of<AuthProvider>(context, listen: false).role == 'ketua';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detail Setoran'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Nama: ${anggota['nama_lengkap'] ?? 'N/A'}'),
              Text('Email: ${anggota['user']['email'] ?? 'N/A'}'),
              const Divider(),
              Text('Nominal: Rp ${simpanan['nominal'] ?? 0}'),
              Text('Jenis Transaksi: ${simpanan['jenis_transaksi'] ?? 'N/A'}'),
              Text('Tanggal: ${simpanan['tanggal'] ?? 'N/A'}'),
              const SizedBox(height: 16),
              const Text('Bukti transfer akan ditampilkan di sini.'),
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
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.receipt)),
                    title: Text(
                      anggota != null
                          ? anggota['nama_lengkap']
                          : 'Nama tidak ada',
                    ),
                    subtitle: Text(
                      'Rp ${simpanan['nominal']} - ${simpanan['jenis_transaksi']}',
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
