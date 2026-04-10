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

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    setState(() {
      _dashboardFuture = _apiService.getKaryawanDashboard();
    });
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Dashboard Karyawan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          int countAnggota = 0;
          int countPinjamanAngsuran = 0;
          int countSimpanan = 0;
          List<dynamic> recentTasks = [];

          if (snapshot.hasData) {
            final data = snapshot.data!;
            final counts = data['counts'] ?? {};
            countAnggota = counts['anggota'] ?? 0;
            countPinjamanAngsuran = (counts['pinjaman'] ?? 0) + (counts['angsuran'] ?? 0);
            countSimpanan = counts['simpanan'] ?? 0;
            recentTasks = data['recent_tasks'] ?? [];
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadDashboard();
              await _dashboardFuture;
            },
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                _buildMenuCard(
                  context,
                  title: 'Kelola Data Anggota',
                  subtitle: 'Verifikasi KTP Anggota',
                  icon: Icons.people_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  badgeCount: countAnggota,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const AnggotaListScreen())).then((_) => _loadDashboard());
                  },
                  delay: 100,
                ),
                _buildMenuCard(
                  context,
                  title: 'Manajemen Pinjaman',
                  subtitle: 'Verifikasi pengajuan & angsuran',
                  icon: Icons.monetization_on_rounded,
                  color: const Color(0xFFE67E22), // Orange for Loans
                  badgeCount: countPinjamanAngsuran,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const PinjamanListScreen())).then((_) => _loadDashboard());
                  },
                  delay: 200,
                ),
                _buildMenuCard(
                  context,
                  title: 'Verifikasi Simpanan',
                  subtitle: 'Setujui setoran dari anggota',
                  icon: Icons.account_balance_wallet_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                  badgeCount: countSimpanan,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const SimpananVerifikasiScreen())).then((_) => _loadDashboard());
                  },
                  delay: 300,
                ),
                
                const SizedBox(height: 20),
                Text(
                  'Daftar Tugas (Harus Diverifikasi)',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 10),
                
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) ...[
                  const Center(child: CircularProgressIndicator()).animate().fadeIn(delay: 500.ms),
                ] else if (snapshot.hasError) ...[
                  Center(
                    child: Text(
                      'Gagal memuat tugas:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ] else if (recentTasks.isEmpty) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 80, color: Colors.green[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Kerja bagus! Tidak ada tugas yang menunggu verifikasi saat ini.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ] else ...[
                  ...recentTasks.map((task) {
                    IconData tIcon;
                    Color tColor;
                    if (task['type'] == 'anggota') {
                      tIcon = Icons.badge;
                      tColor = Theme.of(context).colorScheme.primary;
                    } else if (task['type'] == 'simpanan') {
                      tIcon = Icons.savings;
                      tColor = Theme.of(context).colorScheme.secondary;
                    } else if (task['type'] == 'angsuran') {
                      tIcon = Icons.receipt_long;
                      tColor = Colors.purple;
                    } else {
                      tIcon = Icons.monetization_on;
                      tColor = const Color(0xFFE67E22);
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                        leading: CircleAvatar(
                          backgroundColor: tColor.withOpacity(0.1),
                          child: Icon(tIcon, color: tColor, size: 20),
                        ),
                        title: Text(
                          task['title'],
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task['subtitle'] ?? '-', style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(_formatDate(task['date']), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
                  }),
                ],
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
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
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D3436),
                            ),
                          ),
                          if (badgeCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                badgeCount > 99 ? '99+' : badgeCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX();
  }
}
