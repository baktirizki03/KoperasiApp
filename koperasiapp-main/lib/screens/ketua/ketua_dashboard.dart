import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/carousel_chart_widget.dart';
import '../karyawan/anggota_list_screen.dart';
import 'laporan_pinjaman_screen.dart';
import 'laporan_simpanan_screen.dart';
import 'laporan_angsuran_screen.dart';
import 'bunga_setting_list_screen.dart';

class KetuaDashboard extends StatefulWidget {
  const KetuaDashboard({super.key});

  @override
  State<KetuaDashboard> createState() => _KetuaDashboardState();
}

class _KetuaDashboardState extends State<KetuaDashboard> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _reportsFuture;
  String _userName = 'Ketua';

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchUserName();
  }

  void _loadData() {
    setState(() {
      _reportsFuture = _fetchDashboardData();
    });
  }

  Future<void> _fetchUserName() async {
    try {
      final profile = await _apiService.getMyProfile();
      if (mounted) {
        setState(() {
          _userName = profile['nama_lengkap'] ?? 'Ketua';
        });
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    try {
      final reports = await _apiService.getKetuaReports();
      final pinjamanList = await _apiService.getPinjamanKetua();
      final simpananList = await _apiService.getSimpananKetua();
      final anggotaList = await _apiService.getAnggota();

      final pendingPinjaman = pinjamanList.where((i) {
        final status = (i['status'] ?? '').toString().toLowerCase();
        return status == 'menunggu_konfirmasi' || status == 'pending';
      }).length;

      final pendingSimpanan = simpananList.where((i) {
        final status = (i['status'] ?? '').toString().toLowerCase();
        return status == 'menunggu_konfirmasi' || status == 'pending';
      }).length;

      double totalSimpananWajib = 0;
      for (var s in simpananList) {
        if ((s['status'] ?? '').toString().toLowerCase() == 'disetujui') {
          final jenis = (s['jenis_transaksi'] ?? '').toString().toLowerCase();
          if (jenis.contains('wajib')) {
            double amount = double.tryParse((s['nominal'] ?? '0').toString()) ?? 0;
            if ((s['tipe'] ?? '').toString().toLowerCase() == 'kredit') {
              totalSimpananWajib += amount;
            } else {
              totalSimpananWajib -= amount;
            }
          }
        }
      }

      double totalInterestAssets = 0;
      for (var p in pinjamanList) {
        final status = (p['status'] ?? '').toString().toLowerCase();
        if (status == 'disetujui' || status == 'verified' || status == 'lunas') {
          double nominal = double.tryParse((p['jumlah_pinjaman'] ?? p['jumlah'] ?? p['nominal'] ?? '0').toString()) ?? 0;
          double angsuranPerBulan = double.tryParse((p['jumlah_bayar'] ?? p['jumlah_angsuran'] ?? p['nominal_angsuran'] ?? '0').toString()) ?? 0;
          int lamaAngsuran = int.tryParse((p['lama_angsuran'] ?? '0').toString()) ?? 0;
          if (lamaAngsuran > 0 && angsuranPerBulan > 0) {
            double totalBayar = angsuranPerBulan * lamaAngsuran;
            double bunga = totalBayar - nominal;
            if (bunga > 0) totalInterestAssets += bunga;
          }
        }
      }

      double totalAssets = totalSimpananWajib + totalInterestAssets;
      if (totalAssets < 0) totalAssets = 0;

      double totalKasMasuk = 0;
      for (var s in simpananList) {
        if ((s['status'] ?? '').toString().toLowerCase() == 'disetujui') {
          final jenis = (s['jenis_transaksi'] ?? '').toString().toLowerCase();
          if (jenis.contains('sukarela')) {
            double amount = double.tryParse((s['nominal'] ?? '0').toString()) ?? 0;
            if ((s['tipe'] ?? '').toString().toLowerCase() == 'kredit') totalKasMasuk += amount;
          }
        }
      }

      double totalNominalPinjamanAktif = 0;
      int activeLoanCount = 0;
      for (var p in pinjamanList) {
        final status = (p['status'] ?? '').toString().toLowerCase();
        if (status == 'disetujui' || status == 'verified' || status == 'aktif' || status == 'berjalan') {
          double nominal = double.tryParse((p['jumlah_pinjaman'] ?? p['jumlah'] ?? p['nominal'] ?? '0').toString()) ?? 0;
          totalNominalPinjamanAktif += nominal;
          activeLoanCount++;
        }
      }

      final Map<String, dynamic> mergedData = Map.from(reports);
      mergedData['total_angsuran_aktif_val'] = totalNominalPinjamanAktif;
      mergedData['total_angsuran_aktif_count'] = activeLoanCount;
      mergedData['pending_pinjaman'] = pendingPinjaman;
      mergedData['pending_simpanan'] = pendingSimpanan;
      mergedData['estimated_assets'] = totalAssets;
      mergedData['kas_masuk_sukarela'] = totalKasMasuk;
      mergedData['total_anggota'] = anggotaList.where((a) {
        final val = a['is_ktp_verified'];
        final isVerified = val == 1 || val == true || val.toString() == '1' || val.toString() == 'true';
        final userRole = (a['user']?['role'] ?? '').toString().toLowerCase();
        return isVerified && userRole == 'nasabah';
      }).length;
      mergedData['simpanan_list'] = simpananList;
      mergedData['pinjaman_list'] = pinjamanList;
      mergedData['anggota_list'] = anggotaList;

      return mergedData;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      drawer: _buildDrawer(),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Gagal: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: Text('Tidak ada data.'));

          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: CustomScrollView(
              slivers: [
                _buildDynamicHeader(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 60), // Reduced spacing for integrated card overlap
                        _buildSectionHeader('Butuh Persetujuan'),
                        const SizedBox(height: 12),
                        _buildPendingTiles(data),
                        const SizedBox(height: 16),
                        _buildSectionHeader('Tren Keuangan'),
                        const SizedBox(height: 12),
                        CarouselChartWidget(
                          data: data,
                          simpananList: (data['simpanan_list'] as List?) ?? [],
                          pinjamanList: (data['pinjaman_list'] as List?) ?? [],
                          anggotaList: (data['anggota_list'] as List?) ?? [],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDynamicHeader() {
    return SliverToBoxAdapter(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 320,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu_rounded, color: Colors.white),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
                        icon: const Icon(Icons.logout_rounded, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Halo, Ketua!', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                  Text(_userName, style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: 20,
            right: 20,
            child: FutureBuilder<Map<String, dynamic>>(
              future: _reportsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return _buildIntegratedOverviewCard(snapshot.data!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegratedOverviewCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL ESTIMASI ASET', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(formatRupiah(data['estimated_assets'] ?? 0), style: GoogleFonts.poppins(color: const Color(0xFF0D47A1), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    ],
                  ),
                ],
              ),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF1F5FF), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.account_balance_rounded, color: Color(0xFF0D47A1), size: 28)),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSimpleStatItem('Anggota', data['total_anggota']?.toString() ?? '0', Icons.people_outline, Colors.purple),
              _buildDivider(),
              _buildSimpleStatItem('Pinjaman', formatRupiah(data['total_angsuran_aktif_val'] ?? 0).replaceFirst('Rp ', ''), Icons.trending_up, Colors.green),
              _buildDivider(),
              _buildSimpleStatItem('Kas Masuk', formatRupiah(data['kas_masuk_sukarela'] ?? 0).replaceFirst('Rp ', ''), Icons.savings_outlined, Colors.orange),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2);
  }

  Widget _buildSimpleStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color.withOpacity(0.7), size: 18),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
        Text(label, style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[200]);
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))).animate().fadeIn();
  }

  Widget _buildPendingTiles(Map<String, dynamic> data) {
    return Row(
      children: [
        Expanded(child: _buildActionTile('Pinjaman', data['pending_pinjaman'] ?? 0, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LaporanPinjamanScreen(initialFilterStatus: 'pending'))))),
        const SizedBox(width: 12),
        Expanded(child: _buildActionTile('Simpanan', data['pending_simpanan'] ?? 0, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LaporanSimpananScreen(initialFilterStatus: 'pending'))))),
      ],
    ).animate().fadeIn(delay: 400.ms).slideX();
  }

  Widget _buildActionTile(String label, int count, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)), child: Text('$count', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2D3436)))),
            Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(24))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
            width: double.infinity,
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(radius: 35, backgroundColor: Colors.white24, child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 35)),
                const SizedBox(height: 16),
                Text('Menu Ketua', style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Sistem Manajemen Koperasi', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(Icons.dashboard_rounded, 'Dashboard', () => Navigator.pop(context), isActive: true),
                _buildDrawerItem(Icons.people_alt_rounded, 'Daftar Anggota', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => AnggotaListScreen()));
                }),
                _buildDrawerItem(Icons.monetization_on_rounded, 'Laporan Pinjaman', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const LaporanPinjamanScreen()));
                }),
                _buildDrawerItem(Icons.account_balance_wallet_rounded, 'Laporan Simpanan', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const LaporanSimpananScreen()));
                }),
                _buildDrawerItem(Icons.calendar_today_rounded, 'Laporan Angsuran', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const LaporanAngsuranScreen()));
                }),
                const Divider(indent: 24, endIndent: 24, height: 32),
                _buildDrawerItem(Icons.percent_rounded, 'Pengaturan Bunga', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const BungaSettingListScreen()));
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListTile(
              onTap: () => Provider.of<AuthProvider>(context, listen: false).logout(),
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: Text('Logout', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: Colors.red.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String label, VoidCallback onTap, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isActive ? const Color(0xFF0D47A1) : Colors.grey[600], size: 22),
        title: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? const Color(0xFF0D47A1) : const Color(0xFF2D3436))),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        selected: isActive,
        selectedTileColor: const Color(0xFF0D47A1).withOpacity(0.08),
      ),
    );
  }
}
