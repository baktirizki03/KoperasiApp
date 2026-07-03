import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'anggota_form_screen.dart';
import 'anggota_detail_screen.dart';
import 'anggota_trash_screen.dart';
import '../../widgets/secure_image_widget.dart';

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
  String _filterStatus = 'Semua';
  bool _isExportingPdf = false;

  int _statTotal = 0;
  int _statVerified = 0;
  int _statBelum = 0;
  int _statLaki = 0;
  int _statPerempuan = 0;

  void _exportPdf() async {
    setState(() => _isExportingPdf = true);
    try {
      String status = 'Semua';
      if (_filterStatus == 'Terverifikasi') {
        status = 'Terverifikasi';
      } else if (_filterStatus == 'Belum') {
        status = 'Belum';
      }

      final apiPath = 'export/anggota';
      final fileName = 'Laporan_Anggota_${status}.pdf';
      
      await _apiService.downloadPdf(apiPath, fileName, status: status);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil mengunduh & membuka PDF'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

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

  void _calculateStats() {
    int total = 0;
    int verified = 0;
    int belum = 0;
    int laki = 0;
    int perempuan = 0;

    for (var item in _filteredAnggota) {
      total++;
      
      final val = item['is_ktp_verified'];
      final bool isVerified = val == 1 || val == true || val.toString() == '1' || val.toString() == 'true';
      if (isVerified) {
        verified++;
      } else {
        belum++;
      }

      final jk = (item['jenis_kelamin'] ?? '').toString().toLowerCase();
      if (jk == 'l' || jk == 'laki-laki' || jk == 'laki') {
        laki++;
      } else {
        perempuan++;
      }
    }

    _statTotal = total;
    _statVerified = verified;
    _statBelum = belum;
    _statLaki = laki;
    _statPerempuan = perempuan;
  }

  void _applyFilter() {
    setState(() {
      _filteredAnggota = _allAnggota.where((anggota) {
        final name = (anggota['nama_lengkap'] ?? '').toString().toLowerCase();
        final matchesSearch = name.contains(_searchQuery.toLowerCase());

        final userRole = (anggota['user']?['role'] ?? '').toString().toLowerCase();
        if (userRole != 'nasabah') return false;

        bool matchesFilter = true;
        final val = anggota['is_ktp_verified'];
        bool isVerified = val == 1 || val == true || val.toString() == '1' || val.toString() == 'true';
        if (_filterStatus == 'Terverifikasi') {
          matchesFilter = isVerified;
        } else if (_filterStatus == 'Belum') {
          matchesFilter = !isVerified;
        }

        return matchesSearch && matchesFilter;
      }).toList();
      _calculateStats();
    });
  }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Konfirmasi', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus anggota ini?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
            child: Text('Hapus', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteAnggota(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anggota berhasil dihapus'), backgroundColor: Colors.green),
        );
        _loadAnggota();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showKtpReadOnlyDialog(Map<String, dynamic> anggota) {
    String ktpUrl = anggota['ktp_path'] ?? '';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('Foto KTP', style: GoogleFonts.poppins(fontSize: 16)),
              centerTitle: true,
              backgroundColor: const Color(0xFF0D47A1),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              automaticallyImplyLeading: false,
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 500, maxWidth: 500),
              child: SecureImageWidget(imageUrl: ktpUrl, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }

  void _showVerificationDialog(Map<String, dynamic> anggota) {
    String ktpUrl = anggota['ktp_path'] ?? '';
    final dataList = [
      {'label': 'Nama Lengkap', 'value': anggota['nama_lengkap']},
      {'label': 'NIK (KTP)', 'value': anggota['nomor_ktp']},
      {'label': 'TTL', 'value': '${anggota['tempat_lahir']}, ${anggota['tanggal_lahir']}'},
      {'label': 'Alamat', 'value': anggota['domisili']},
      {'label': 'Pekerjaan', 'value': anggota['pekerjaan']},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Verifikasi Anggota', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Data Pendaftaran:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              ...dataList.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text('${item['label']}:', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                    ),
                    Expanded(
                      child: Text('${item['value'] ?? '-'}', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              )),
              const Divider(height: 24),
              Text('Foto KTP:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SecureImageWidget(imageUrl: ktpUrl, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pastikan data di formulir SAMA dengan data di Foto KTP sebelum menyetujui.',
                style: GoogleFonts.poppins(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.orange[800]),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _showRejectDialog(anggota['id']);
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('Tolak', style: GoogleFonts.poppins()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _verifyAnggota(anggota['id']);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('Setujui', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(int id) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tolak Verifikasi', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Masukkan alasan penolakan (Wajib):', style: GoogleFonts.poppins(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Misal: Foto KTP buram',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alasan harus diisi!'), backgroundColor: Colors.red));
                return;
              }
              Navigator.of(ctx).pop();
              await _rejectAnggota(id, reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
            child: Text('Kirim Penolakan', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyAnggota(int id) async {
    try {
      await _apiService.verifyKtp(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anggota berhasil diverifikasi'), backgroundColor: Colors.green));
      _loadAnggota();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal verifikasi: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red));
    }
  }

  Future<void> _rejectAnggota(int id, String reason) async {
    try {
      await _apiService.rejectKtp(id, reason);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verifikasi ditolak. Member perlu daftar ulang/hubungi admin.'), backgroundColor: Colors.orange));
      _loadAnggota();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menolak: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red));
    }
  }

  void _resetPassword(Map<String, dynamic> anggota) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset Password', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin mereset password anggota "${anggota['nama_lengkap']}"?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, elevation: 0),
            child: Text('Reset', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await _apiService.resetPasswordMember(anggota['id']);
        final message = response['message'] ?? 'Password berhasil direset';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green, duration: const Duration(seconds: 10), action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {})));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal reset password: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AuthProvider>(context, listen: false).role;
    final isKetuaOrKaryawan = role == 'ketua' || role == 'karyawan';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      body: Column(
        children: [
          // --- CUSTOM GRADIENT HEADER ---
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                          Text('Daftar Anggota', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          if (isKetuaOrKaryawan)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (role == 'ketua')
                                  _isExportingPdf
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                                          onPressed: _exportPdf,
                                          tooltip: 'Cetak PDF',
                                        ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnggotaTrashScreen())).then((_) => _loadAnggota()),
                                  tooltip: 'Tempat Sampah',
                                ),
                              ],
                            )
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Search Bar Card
                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: TextField(
                          onChanged: (value) { _searchQuery = value; _applyFilter(); },
                          decoration: InputDecoration(
                            hintText: 'Cari nama anggota...',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0D47A1)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // --- FILTER SECTION ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Semua'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Terverifikasi'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Belum'),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),
          ),

          // --- OVERVIEW CARD ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL ANGGOTA TERDAFTAR',
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_statTotal Orang',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF673AB7),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.people_rounded,
                          color: Colors.purple,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSimpleSummaryCol('Terverifikasi', '$_statVerified Orang', Colors.green),
                      _buildSimpleSummaryCol('Belum Verif', '$_statBelum Orang', Colors.orange),
                      _buildSimpleSummaryCol('Laki-laki', '$_statLaki L', const Color(0xFF0D47A1)),
                      _buildSimpleSummaryCol('Perempuan', '$_statPerempuan P', Colors.pink),
                    ],
                  )
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _anggotaFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins()));
                }
                if (_filteredAnggota.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]), const SizedBox(height: 16), Text('Tidak ada anggota ditemukan', style: GoogleFonts.poppins(color: Colors.grey[500]))]));
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadAnggota(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: _filteredAnggota.length,
                    itemBuilder: (ctx, index) => _buildAnggotaCard(_filteredAnggota[index], index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: (role == 'karyawan')
          ? Container(
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: const Color(0xFF083271).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
              child: FloatingActionButton(
                onPressed: () => _navigateToForm(),
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ).animate().fadeIn(delay: 500.ms).scale()
          : null,
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _filterStatus == label;
    return GestureDetector(
      onTap: () { setState(() { _filterStatus = label; _applyFilter(); }); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF0D47A1) : Colors.grey[200]!),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF0D47A1).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: Text(label, style: GoogleFonts.poppins(color: isSelected ? Colors.white : Colors.grey[600], fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildAnggotaCard(Map<String, dynamic> anggota, int index) {
    final role = Provider.of<AuthProvider>(context, listen: false).role;
    final isKetua = role == 'ketua';
    final val = anggota['is_ktp_verified'];
    final bool isVerified = val == 1 || val == true || val.toString() == '1' || val.toString() == 'true';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isVerified ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: (isVerified ? Colors.green : Colors.orange).withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(isVerified ? Icons.person_rounded : Icons.person_search_rounded, color: isVerified ? Colors.green : Colors.orange, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(anggota['nama_lengkap'], style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
                      Text(anggota['user']?['email'] ?? 'No Email', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: (isVerified ? Colors.green : Colors.orange).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(isVerified ? 'VERIFIKASI' : 'PENDING', style: GoogleFonts.poppins(color: isVerified ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                // Info/Detail
                IconButton(icon: const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AnggotaDetailScreen(anggota: anggota))), tooltip: 'Detail'),
                // KTP Action
                if (anggota['ktp_path'] != null && anggota['ktp_path'].toString().isNotEmpty)
                  IconButton(
                    icon: Icon(isVerified ? Icons.image_outlined : Icons.verified_user_outlined, color: isVerified ? Colors.blueGrey : Colors.orange, size: 20),
                    onPressed: () => isVerified ? _showKtpReadOnlyDialog(anggota) : _showVerificationDialog(anggota),
                    tooltip: isVerified ? 'Lihat KTP' : 'Verifikasi KTP',
                  ),
                const Spacer(),
                // Reset Password (Ketua)
                if (isKetua) IconButton(icon: const Icon(Icons.lock_reset_rounded, color: Colors.orange, size: 20), onPressed: () => _resetPassword(anggota), tooltip: 'Reset Password'),
                // Delete (Ketua)
                if (isKetua) IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), onPressed: () => _deleteAnggota(anggota['id']), tooltip: 'Hapus'),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSimpleSummaryCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
