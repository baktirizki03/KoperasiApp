import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AnggotaTrashScreen extends StatefulWidget {
  const AnggotaTrashScreen({super.key});

  @override
  _AnggotaTrashScreenState createState() => _AnggotaTrashScreenState();
}

class _AnggotaTrashScreenState extends State<AnggotaTrashScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _trashFuture;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  void _loadTrash() {
    setState(() {
      _trashFuture = _apiService.getAnggotaSampah();
    });
  }

  void _restoreAnggota(int id, String name) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pulihkan Anggota'),
        content: Text(
          'Apakah Anda yakin ingin memulihkan anggota "$name"? Data akan kembali aktif dan masuk ke daftar utama.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Pulihkan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.restoreAnggota(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anggota berhasil dipulihkan!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadTrash();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memulihkan: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tempat Sampah (Anggota)'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _trashFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat data: ${snapshot.error.toString().replaceAll('Exception: ', '')}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final _trashList = snapshot.data ?? [];

          if (_trashList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Tempat sampah kosong.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadTrash(),
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _trashList.length,
              itemBuilder: (ctx, index) {
                final anggota = _trashList[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200, width: 1),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade100,
                      child: Icon(Icons.person_off, color: Colors.red.shade700),
                    ),
                    title: Text(
                      anggota['nama_lengkap'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anggota['user']?['email'] ?? 'Email tidak tersedia',
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Dihapus pada: ${anggota['deleted_at']?.split('T')[0] ?? '-'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing:
                        Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            ).role ==
                            'ketua'
                        ? OutlinedButton.icon(
                            icon: Icon(Icons.restore, size: 18),
                            label: Text('Pulihkan'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green.shade700,
                              side: BorderSide(color: Colors.green.shade700),
                            ),
                            onPressed: () => _restoreAnggota(
                              anggota['id'],
                              anggota['nama_lengkap'],
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
