import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'anggota_form_screen.dart';

class AnggotaListScreen extends StatefulWidget {
  @override
  _AnggotaListScreenState createState() => _AnggotaListScreenState();
}

class _AnggotaListScreenState extends State<AnggotaListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _anggotaFuture;

  @override
  void initState() {
    super.initState();
    _loadAnggota();
  }

  void _loadAnggota() {
    setState(() {
      _anggotaFuture = _apiService.getAnggota();
    });
  }

  // --- Fungsi navigasi ke form ---
  void _navigateToForm({Map<String, dynamic>? anggota}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => AnggotaFormScreen(anggota: anggota)),
    );

    if (result == true) {
      _loadAnggota();
    }
  }

  void _deleteAnggota(int id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Konfirmasi'),
        content: Text('Apakah Anda yakin ingin menghapus anggota ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteAnggota(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anggota berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAnggota();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showKtpReadOnlyDialog(Map<String, dynamic> anggota) {
    String ktpUrl = anggota['ktp_path'] ?? '';
    if (!ktpUrl.startsWith('http')) {
      ktpUrl = "http://localhost:8000/storage/" + ktpUrl;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Foto KTP'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              automaticallyImplyLeading: false,
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 500, maxWidth: 500),
              child: Image.network(
                ktpUrl,
                fit: BoxFit.contain,
                errorBuilder: (ctx, error, stackTrace) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('Gagal memuat gambar KTP'),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVerificationDialog(Map<String, dynamic> anggota) {
    String ktpUrl = anggota['ktp_path'] ?? '';
    if (!ktpUrl.startsWith('http')) {
      // Sesuaikan base URL dengan environment Anda.
      // Jika menggunakan emulator android: http://10.0.2.2:8000/storage/
      ktpUrl = "http://localhost:8000/storage/" + ktpUrl;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Verifikasi Anggota'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama: ${anggota['nama_lengkap']}'),
            SizedBox(height: 10),
            Text('Foto KTP:'),
            SizedBox(height: 5),
            Container(
              height: 200,
              width: double.maxFinite,
              color: Colors.grey[200],
              child: Image.network(
                ktpUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, error, stackTrace) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Gagal memuat gambar.\nURL: $ktpUrl',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 15),
            Text('Apakah data ini valid dan sesuai?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _verifyAnggota(anggota['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Setujui (Verify)'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyAnggota(int id) async {
    try {
      await _apiService.verifyKtp(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Anggota berhasil diverifikasi'),
          backgroundColor: Colors.green,
        ),
      );
      _loadAnggota();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal verifikasi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Daftar Anggota')),
      body: FutureBuilder<List<dynamic>>(
        future: _anggotaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final errorMsg = snapshot.error.toString();
            if (errorMsg.contains('akses') ||
                errorMsg.contains('Forbidden') ||
                errorMsg.contains('Unauthorized')) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 60, color: Colors.orange),
                    SizedBox(height: 16),
                    Text(
                      'Akses Ditolak',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Anda tidak memiliki izin untuk melihat halaman ini.',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Role Anda saat ini: ${Provider.of<AuthProvider>(context, listen: false).role ?? "Tidak diketahui"}',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        ).logout();
                      },
                      icon: Icon(Icons.logout),
                      label: Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Tidak ada data anggota.'));
          }

          final anggotas = snapshot.data!;
          final role = Provider.of<AuthProvider>(context, listen: false).role;
          final isKetua = role == 'ketua';
          final isKaryawan = role == 'karyawan';

          return ListView.builder(
            itemCount: anggotas.length,
            itemBuilder: (ctx, index) {
              final anggota = anggotas[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(anggota['nama_lengkap']),
                  subtitle: Text(
                    anggota['user']?['email'] ?? 'Email tidak tersedia',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // KTP View Button (Read Only)
                      if (anggota['ktp_path'] != null &&
                          anggota['ktp_path'].toString().isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.image_search,
                            color: Colors.blueGrey,
                          ),
                          tooltip: 'Lihat Foto KTP',
                          onPressed: () => _showKtpReadOnlyDialog(anggota),
                        ),

                      SizedBox(width: 8),

                      // Status Verifikasi Icon
                      if (anggota['is_ktp_verified'] == 1)
                        Tooltip(
                          message: 'Terverifikasi',
                          child: Icon(Icons.check_circle, color: Colors.green),
                        )
                      else if (anggota['ktp_path'] != null &&
                          anggota['ktp_path'].toString().isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.hourglass_top, color: Colors.orange),
                          tooltip: 'Menunggu Verifikasi (Lihat KTP)',
                          onPressed: () => _showVerificationDialog(anggota),
                        )
                      else
                        Tooltip(
                          message: 'Belum Upload KTP',
                          child: Icon(Icons.cancel, color: Colors.grey),
                        ),
                      SizedBox(width: 8),

                      // Edit Button (Karyawan & Ketua)
                      if (isKaryawan || isKetua)
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _navigateToForm(anggota: anggota),
                          tooltip: 'Edit Anggota',
                        ),

                      // Delete Button (Only Ketua)
                      if (isKetua)
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteAnggota(anggota['id']),
                          tooltip: 'Hapus Anggota',
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton:
          (Provider.of<AuthProvider>(context).role == 'karyawan')
          ? FloatingActionButton(
              onPressed: () => _navigateToForm(),
              child: Icon(Icons.add),
              tooltip: 'Tambah Anggota',
            )
          : null,
    );
  }
}
