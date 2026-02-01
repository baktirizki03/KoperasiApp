import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'anggota_form_screen.dart';

class AnggotaListScreen extends StatefulWidget {
  const AnggotaListScreen({super.key});

  @override
  _AnggotaListScreenState createState() => _AnggotaListScreenState();
}

class _AnggotaListScreenState extends State<AnggotaListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _anggotaFuture;
  List<dynamic> _allAnggota = [];
  List<dynamic> _filteredAnggota = [];
  String _searchQuery = '';
  String _filterStatus = 'Semua'; // Semua, Terverifikasi, Belum

  @override
  void initState() {
    super.initState();
    _loadAnggota();
  }

  void _loadAnggota() {
    setState(() {
      _anggotaFuture = _apiService.getAnggota().then((data) {
        _allAnggota = data;
        _applyFilter();
        return data;
      });
    });
  }

  void _applyFilter() {
    setState(() {
      _filteredAnggota = _allAnggota.where((anggota) {
        final name = (anggota['nama_lengkap'] ?? '').toString().toLowerCase();
        final matchesSearch = name.contains(_searchQuery.toLowerCase());

        bool matchesFilter = true;
        if (_filterStatus == 'Terverifikasi') {
          matchesFilter = anggota['is_ktp_verified'] == 1;
        } else if (_filterStatus == 'Belum') {
          matchesFilter = anggota['is_ktp_verified'] != 1;
        }

        return matchesSearch && matchesFilter;
      }).toList();
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
      ktpUrl = "http://10.0.2.2:8000/storage/$ktpUrl";
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
      ktpUrl = "http://10.0.2.2:8000/storage/$ktpUrl";
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

  void _resetPassword(Map<String, dynamic> anggota) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Password'),
        content: Text(
          'Apakah Anda yakin ingin mereset password anggota "${anggota['nama_lengkap']}" menjadi "koperasi123"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.resetPasswordMember(anggota['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password berhasil direset'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal reset password: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFilterChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: _filterStatus == label,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _filterStatus = label;
            _applyFilter();
          });
        }
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: _filterStatus == label
            ? Theme.of(context).colorScheme.primary
            : Colors.black,
        fontWeight: _filterStatus == label
            ? FontWeight.bold
            : FontWeight.normal,
      ),
    );
  }

  Widget _buildAnggotaCard(Map<String, dynamic> anggota) {
    final role = Provider.of<AuthProvider>(context, listen: false).role;
    final isKetua = role == 'ketua';
    final isKaryawan = role == 'karyawan';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(anggota['nama_lengkap']),
            subtitle: Text(anggota['user']?['email'] ?? 'Email tidak tersedia'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // KTP View Button (Read Only)
                if (anggota['ktp_path'] != null &&
                    anggota['ktp_path'].toString().isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.image_search, color: Colors.blueGrey),
                    tooltip: 'Lihat Foto KTP',
                    onPressed: () => _showKtpReadOnlyDialog(anggota),
                  ),

                SizedBox(width: 8),

                // Status Verifikasi Icon
                if (anggota['is_ktp_verified'] == 1)
                  Tooltip(
                    message: anggota['verified_by'] != null
                        ? 'Diverifikasi oleh: ${anggota['verified_by']['role'].toString().toUpperCase()}'
                        : 'Terverifikasi',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        if (anggota['verified_by'] != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Text(
                              '${anggota['verified_by']['role'].toString().toUpperCase()}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
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

                // Reset Password Button (Only Ketua)
                if (isKetua)
                  IconButton(
                    icon: Icon(Icons.lock_reset, color: Colors.orange),
                    onPressed: () => _resetPassword(anggota),
                    tooltip: 'Reset Password',
                  ),

                // Edit Button (Only Ketua)
                if (isKetua)
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
        ],
      ),
    );
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
            // ... error handling logic (simplified for brevity, keep existing logic if complex) ...
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Gunakan _filteredAnggota yang sudah di-update oleh logic lokal
          // Snapshot data hanya trigger awal, selanjutnya pakai variable state local

          return Column(
            children: [
              // --- SEARCH & FILTER SECTION ---
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari nama anggota...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (value) {
                        _searchQuery = value;
                        _applyFilter();
                      },
                    ),
                    SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('Semua'),
                          SizedBox(width: 8),
                          _buildFilterChip('Terverifikasi'),
                          SizedBox(width: 8),
                          _buildFilterChip('Belum'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _filteredAnggota.isEmpty
                    ? Center(child: Text('Tidak ada anggota ditemukan.'))
                    : RefreshIndicator(
                        onRefresh: () async => _loadAnggota(),
                        child: ListView.builder(
                          itemCount: _filteredAnggota.length,
                          itemBuilder: (ctx, index) {
                            final anggota = _filteredAnggota[index];
                            return _buildAnggotaCard(anggota);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton:
          (Provider.of<AuthProvider>(context).role == 'karyawan')
          ? FloatingActionButton(
              onPressed: () => _navigateToForm(),
              tooltip: 'Tambah Anggota',
              child: Icon(Icons.add),
            )
          : null,
    );
  }
}
