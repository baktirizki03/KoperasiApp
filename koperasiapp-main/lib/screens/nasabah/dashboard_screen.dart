import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/currency_formatter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dashboardFuture;
  String _userName = 'Nasabah';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dashboardFuture = _apiService.getDashboardData();
    });
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    try {
      final profile = await _apiService.getMyProfile();
      if (mounted) {
        setState(() {
          _userName = profile['anggota']?['nama_lengkap'] ?? profile['name'] ?? 'Nasabah';
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _buildErrorState();
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('Tidak ada data.'));
            }

            final data = snapshot.data!;
            final totalSimpanan = data['total_simpanan'];
            final riwayatAngsuran = data['riwayat_angsuran'] as List;
            final riwayatSimpanan = data['riwayat_simpanan'] as List;

            // Filter data to only show last 1 month of mutations on dashboard
            final now = DateTime.now();
            final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);

            final recentAngsuran = riwayatAngsuran.where((item) {
              final dateStr = item['created_at']?.toString() ?? '';
              if (dateStr.isEmpty) return false;
              try {
                final date = DateTime.parse(dateStr);
                return date.isAfter(oneMonthAgo);
              } catch (_) {
                return false;
              }
            }).toList();

            final recentSimpanan = riwayatSimpanan.where((item) {
              final dateStr = (item['tanggal'] ?? item['created_at'])?.toString() ?? '';
              if (dateStr.isEmpty) return false;
              try {
                final date = DateTime.parse(dateStr);
                return date.isAfter(oneMonthAgo);
              } catch (_) {
                return false;
              }
            }).toList();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildSaldoCard(totalSimpanan),
                      _buildRiwayatSection(recentAngsuran, recentSimpanan),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Gagal memuat data', style: GoogleFonts.poppins(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${_userName.split(' ')[0]}!',
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Selamat datang di dashboard nasabah',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
            IconButton(
              onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
            ),
          ],
        ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),
      ),
    );
  }

  Widget _buildSaldoCard(dynamic totalSimpanan) {
    final saldo = (totalSimpanan is String) ? double.parse(totalSimpanan) : totalSimpanan.toDouble();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: const Color(0xFF0D47A1).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SALDO SIMPANAN', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(formatRupiah(saldo), style: GoogleFonts.poppins(color: const Color(0xFF0D47A1), fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF1F5FF), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF0D47A1), size: 28),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildSimpleInfo('Total Transaksi', 'Aktif', Icons.sync_rounded),
              const Spacer(),
              _buildSimpleInfo('Status Akun', 'Terverifikasi', Icons.verified_user_rounded),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildSimpleInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue[300]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10)),
            Text(value, style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildRiwayatSection(List riwayatAngsuran, List riwayatSimpanan) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Row(
              children: [
                const Icon(Icons.history_edu_rounded, color: Color(0xFF0D47A1), size: 22),
                const SizedBox(width: 12),
                Text('Mutasi Terakhir', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 50,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
            child: TabBar(
              indicator: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFF0D47A1)),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [Tab(text: 'Pinjaman'), Tab(text: 'Simpanan')],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 500,
            child: TabBarView(
              children: [
                _buildRiwayatList(riwayatAngsuran, isAngsuran: true),
                _buildRiwayatList(riwayatSimpanan, isAngsuran: false),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildRiwayatList(List items, {required bool isAngsuran}) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_rounded, size: 52, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'Tidak ada mutasi 1 bulan terakhir',
                style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                isAngsuran 
                  ? 'Silakan cek menu pinjaman untuk melihat riwayat lengkap.'
                  : 'Silakan cek menu simpanan untuk melihat riwayat lengkap.',
                style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        final item = items[index];
        String status = item['status'] ?? '-';
        Color statusColor = Colors.orange;
        if (status == 'disetujui' || status == 'lunas') statusColor = Colors.green;
        if (status == 'ditolak') statusColor = Colors.red;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: (isAngsuran ? Colors.orange : Colors.green).withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(isAngsuran ? Icons.receipt_long_rounded : Icons.account_balance_wallet_rounded, color: isAngsuran ? Colors.orange : Colors.green, size: 22),
            ),
            title: Text(isAngsuran ? 'Pengajuan Pinjaman' : (item['jenis_transaksi'] ?? 'Simpanan'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2D3436))),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  isAngsuran ? 'Tenor: ${item['tenor_cicilan']} Bulan' : (item['tanggal'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(item['tanggal'])) : '-'),
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(status.toUpperCase(), style: GoogleFonts.poppins(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 0.5)),
                ),
              ],
            ),
            trailing: Text(formatRupiah(item['nominal']), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: isAngsuran ? Colors.orange[800] : Colors.green[800])),
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
      },
    );
  }
}
