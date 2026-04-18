import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Pulihkan Anggota', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin memulihkan anggota "$name"? Data akan kembali aktif.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Pulihkan', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.restoreAnggota(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anggota berhasil dipulihkan!'),
            backgroundColor: Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadTrash();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulihkan: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      body: FutureBuilder<List<dynamic>>(
        future: _trashFuture,
        builder: (context, snapshot) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- PREMIUM HEADER ---
              _buildHeader(),

              // --- TRASH LIST ---
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else if (snapshot.hasError)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Gagal memuat data: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    ),
                  ),
                )
              else if (snapshot.data == null || snapshot.data!.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final anggota = snapshot.data![index];
                        return _buildTrashCard(anggota, index)
                            .animate()
                            .fadeIn(duration: 400.ms, delay: (index * 50).ms)
                            .slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
                      },
                      childCount: snapshot.data!.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadTrash,
        backgroundColor: const Color(0xFF0D47A1),
        child: const Icon(Icons.refresh, color: Colors.white),
      ).animate().scale(delay: 500.ms),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tempat Sampah',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Kelola data anggota yang dihapus',
                      style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrashCard(Map<String, dynamic> anggota, int index) {
    final bool isKetua = Provider.of<AuthProvider>(context, listen: false).role == 'ketua';
    final String deletedDate = anggota['deleted_at']?.split('T')[0] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.person_off_rounded, color: Colors.red, size: 24),
                ),
                title: Text(
                  anggota['nama_lengkap'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF2D3436)),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anggota['user']?['email'] ?? 'Tidak ada email',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          'Dihapus: $deletedDate',
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isKetua)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(top: BorderSide(color: Colors.grey[100]!)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _restoreAnggota(anggota['id'], anggota['nama_lengkap']),
                        icon: const Icon(Icons.restore_rounded, size: 18, color: Color(0xFF00C853)),
                        label: Text(
                          'PULIHKAN ANGGOTA',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF00C853)),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          backgroundColor: const Color(0xFF00C853).withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.delete_outline_rounded, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          Text(
            'Tempat Sampah Kosong',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada data anggota yang dihapus.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}
