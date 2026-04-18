import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'anggota_list_screen.dart';
import 'pinjaman_list_screen.dart';
import 'simpanan_verifikasi_screen.dart';
import 'pinjaman_detail_screen.dart';

class KaryawanDashboard extends StatefulWidget {
  const KaryawanDashboard({super.key});

  @override
  State<KaryawanDashboard> createState() => _KaryawanDashboardState();
}

class _KaryawanDashboardState extends State<KaryawanDashboard> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dashboardFuture;
  String _userName = 'Karyawan';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    setState(() {
      _dashboardFuture = _apiService.getKaryawanDashboard();
    });
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final profile = await _apiService.getMyProfile();
      if (mounted) {
        setState(() {
          _userName = profile['nama_lengkap'] ?? 'Karyawan';
        });
      }
    } catch (_) {}
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          int countAnggota = 0;
          int countPinjamanAngsuran = 0;
          int countSimpanan = 0;

          int totalAnggota = 0;
          int totalPinjaman = 0;
          int totalSimpanan = 0;

          List<dynamic> recentTasks = [];

          if (snapshot.hasData) {
            final data = snapshot.data!;
            final counts = data['counts'] ?? {};
            countAnggota = counts['anggota'] ?? 0;
            countPinjamanAngsuran = (counts['pinjaman'] ?? 0) + (counts['angsuran'] ?? 0);
            countSimpanan = counts['simpanan'] ?? 0;

            final totals = data['totals'] ?? {};
            totalAnggota = totals['anggota'] ?? 0;
            totalPinjaman = totals['pinjaman'] ?? 0;
            totalSimpanan = totals['simpanan'] ?? 0;

            recentTasks = data['recent_tasks'] ?? [];
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadDashboard();
              await _dashboardFuture;
            },
            child: CustomScrollView(
              slivers: [
                // --- CUSTOM PREMIUM APP BAR / HEADER ---
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      // Gradient Background
                      Container(
                        height: 240,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(36),
                          ),
                        ),
                      ),
                      
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Selamat Datang,',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        _userName,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Logout Button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                                      onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
                              
                              const SizedBox(height: 32),
                              
                              // Stats Summary
                              _buildStatsSummary(totalAnggota, totalPinjaman, totalSimpanan)
                                  .animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- MENU ACTIONS ---
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Menu Manajemen',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3436),
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildMenuCard(
                        context,
                        title: 'Kelola Data Anggota',
                        subtitle: 'Pendaftaran & Verifikasi KTP',
                        icon: Icons.people_alt_rounded,
                        color: const Color(0xFF0D47A1),
                        badgeCount: countAnggota,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const AnggotaListScreen())).then((_) => _loadDashboard()),
                        delay: 500,
                      ),
                      _buildMenuCard(
                        context,
                        title: 'Manajemen Pinjaman',
                        subtitle: 'Verifikasi Pengajuan & Angsuran',
                        icon: Icons.monetization_on_rounded,
                        color: const Color(0xFFE67E22),
                        badgeCount: countPinjamanAngsuran,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const PinjamanListScreen())).then((_) => _loadDashboard()),
                        delay: 600,
                      ),
                      _buildMenuCard(
                        context,
                        title: 'Verifikasi Simpanan',
                        subtitle: 'Proses data setoran anggota',
                        icon: Icons.account_balance_wallet_rounded,
                        color: const Color(0xFF2E7D32),
                        badgeCount: countSimpanan,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const SimpananVerifikasiScreen())).then((_) => _loadDashboard()),
                        delay: 700,
                      ),
                    ]),
                  ),
                ),

                // --- RECENT TASKS ---
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tugas Menunggu Verifikasi',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3436),
                          ),
                        ),
                        if (recentTasks.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${recentTasks.length} Tugas',
                              style: GoogleFonts.poppins(
                                color: Colors.red[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ).animate().fadeIn(delay: 800.ms),
                  ),
                ),

                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (recentTasks.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.verified_rounded, size: 64, color: Colors.green[300]),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Semua tugas telah diverifikasi!',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 900.ms),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = recentTasks[index];
                          return _buildTaskTile(context, task);
                        },
                        childCount: recentTasks.length,
                      ),
                    ),
                  ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSummary(int anggota, int pinjaman, int simpanan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Anggota', anggota.toString(), Icons.people_outline, const Color(0xFF0D47A1)),
          _buildDivider(),
          _buildStatItem('Pinjaman', pinjaman.toString(), Icons.monetization_on_outlined, const Color(0xFFE67E22)),
          _buildDivider(),
          _buildStatItem('Simpanan', simpanan.toString(), Icons.account_balance_wallet_outlined, const Color(0xFF2E7D32)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey[200],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3436),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required int delay,
    required int badgeCount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3436),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 14),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTaskTile(BuildContext context, dynamic task) {
    IconData tIcon;
    Color tColor;
    if (task['type'] == 'anggota') {
      tIcon = Icons.badge;
      tColor = const Color(0xFF0D47A1);
    } else if (task['type'] == 'simpanan') {
      tIcon = Icons.savings;
      tColor = const Color(0xFF2E7D32);
    } else if (task['type'] == 'angsuran') {
      tIcon = Icons.receipt_long;
      tColor = Colors.purple;
    } else {
      tIcon = Icons.monetization_on;
      tColor = const Color(0xFFE67E22);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[100]!),
      ),
      child: ListTile(
        onTap: () {
          int idToPass = task['type'] == 'angsuran' ? (task['pinjaman_id'] ?? task['id']) : task['id'];
          if (task['type'] == 'anggota') {
            Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const AnggotaListScreen())).then((_) => _loadDashboard());
          } else if (task['type'] == 'simpanan') {
            Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const SimpananVerifikasiScreen())).then((_) => _loadDashboard());
          } else {
            Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => PinjamanDetailScreen(pinjamanId: idToPass))).then((_) => _loadDashboard());
          }
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(tIcon, color: tColor, size: 20),
        ),
        title: Text(
          task['title'],
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          '${task['subtitle'] ?? '-'} • ${_formatDate(task['date'])}',
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
        ),
        trailing: Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
      ),
    ).animate().fadeIn(delay: 900.ms).slideX(begin: 0.05, end: 0);
  }
}
