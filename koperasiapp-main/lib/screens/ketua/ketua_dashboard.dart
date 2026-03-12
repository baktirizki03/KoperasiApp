import 'package:flutter/material.dart';
import '../../utils/currency_formatter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

import '../../widgets/header_widget.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _reportsFuture = _fetchDashboardData();
    });
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    try {
      final reports = await _apiService.getKetuaReports();

      final pinjamanList = await _apiService.getPinjamanKetua();
      final simpananList = await _apiService.getSimpananKetua();
      final anggotaList = await _apiService.getAnggota(); // Needed for count

      // Hitung angsuran aktif (status != 'lunas')
      // Calculate Pending Counts
      final pendingPinjaman = pinjamanList.where((i) {
        final status = (i['status'] ?? '').toString().toLowerCase();
        return status == 'menunggu_konfirmasi' || status == 'pending';
      }).length;

      final pendingSimpanan = simpananList.where((i) {
        final status = (i['status'] ?? '').toString().toLowerCase();
        return status == 'menunggu_konfirmasi' || status == 'pending';
      }).length;

      // --- CORRECT ASSET CALCULATION (SIMPANAN WAJIB + SHU) ---
      // User Request: Total Aset = Simpanan Wajib + Keuntungan Bunga (SHU).

      // Part 1: Simpanan Wajib
      double totalSimpananWajib = 0;
      for (var s in simpananList) {
        if ((s['status'] ?? '').toString().toLowerCase() == 'disetujui') {
          // Check for 'Wajib' in jenis_transaksi
          final jenis = (s['jenis_transaksi'] ?? '').toString().toLowerCase();
          if (jenis.contains('wajib')) {
            double amount =
                double.tryParse((s['nominal'] ?? '0').toString()) ?? 0;
            if ((s['tipe'] ?? '').toString().toLowerCase() == 'kredit') {
              totalSimpananWajib += amount;
            } else {
              totalSimpananWajib -= amount;
            }
          }
        }
      }

      // Part 2: SHU (Interest Revenue)
      // Formula: Sum of ((MonthlyPayment * Duration) - Principal) for all approved/paid loans.
      double totalInterestAssets = 0;
      for (var p in pinjamanList) {
        final status = (p['status'] ?? '').toString().toLowerCase();
        if (status == 'disetujui' ||
            status == 'verified' ||
            status == 'lunas') {
          double nominal =
              double.tryParse(
                (p['jumlah_pinjaman'] ?? p['jumlah'] ?? p['nominal'] ?? '0')
                    .toString(),
              ) ??
              0;
          double angsuranPerBulan =
              double.tryParse(
                (p['jumlah_bayar'] ??
                        p['jumlah_angsuran'] ??
                        p['nominal_angsuran'] ??
                        '0')
                    .toString(),
              ) ??
              0;
          int lamaAngsuran =
              int.tryParse((p['lama_angsuran'] ?? '0').toString()) ?? 0;

          if (lamaAngsuran > 0 && angsuranPerBulan > 0) {
            double totalBayar = angsuranPerBulan * lamaAngsuran;
            double bunga = totalBayar - nominal;
            if (bunga > 0) {
              totalInterestAssets += bunga;
            }
          }
        }
      }

      // Total Asset
      double totalAssets = totalSimpananWajib + totalInterestAssets;
      if (totalAssets < 0) totalAssets = 0;

      // --- KAS MASUK (SIMPANAN SUKARELA) ---
      // User Request: Kas Masuk diambil dari Simpanan Sukarela.
      double totalKasMasuk = 0;
      for (var s in simpananList) {
        if ((s['status'] ?? '').toString().toLowerCase() == 'disetujui') {
          // Check for 'Sukarela'
          final jenis = (s['jenis_transaksi'] ?? '').toString().toLowerCase();
          if (jenis.contains('sukarela')) {
            double amount =
                double.tryParse((s['nominal'] ?? '0').toString()) ?? 0;
            if ((s['tipe'] ?? '').toString().toLowerCase() == 'kredit') {
              totalKasMasuk += amount;
            }
            // NOTE: 'Kas Masuk' usually implies Inflow only. If we want Net Flow, subtract debit.
            // User said "Kas Masuk... diambil dari simpanan sukarela".
            // Typically "Kas Masuk" = Income/Debit(in accounting terms for Cash).
            // Simpanan 'Kredit' in our DB context usually means User Deposit (Money In to Coop).
            // Simpanan 'Debet' means User Withdraw (Money Out from Coop).
            // So Kas Masuk = Sum of 'Kredit' transactions of Sukarela.
          }
        }
      }

      // --- PINJAMAN BERJALAN (TOTAL NOMINAL RP) ---
      // User Request: Total pinjaman aktif tapi dalam bentuk rupiah.
      double totalNominalPinjamanAktif = 0;
      int activeLoanCount = 0;

      for (var p in pinjamanList) {
        final status = (p['status'] ?? '').toString().toLowerCase();
        if (status == 'disetujui' ||
            status == 'verified' ||
            status == 'aktif' ||
            status == 'berjalan') {
          // Only active
          double nominal =
              double.tryParse(
                (p['jumlah_pinjaman'] ?? p['jumlah'] ?? p['nominal'] ?? '0')
                    .toString(),
              ) ??
              0;
          totalNominalPinjamanAktif += nominal;
          activeLoanCount++;
        }
      }

      // Additional requested logic mostly done.

      // Gabungkan data
      final Map<String, dynamic> mergedData = Map.from(reports);
      mergedData['total_angsuran_aktif_val'] = totalNominalPinjamanAktif;
      mergedData['total_angsuran_aktif_count'] = activeLoanCount;
      mergedData['pending_pinjaman'] = pendingPinjaman;
      mergedData['pending_simpanan'] = pendingSimpanan;
      mergedData['estimated_assets'] = totalAssets;
      mergedData['kas_masuk_sukarela'] = totalKasMasuk;
      mergedData['total_anggota'] = anggotaList
          .where((a) => a['is_ktp_verified'] == 1)
          .length;

      // Pass lists for charts
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
    // ... [No changes to app bar or drawer] ...
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Dashboard Ketua',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Gagal: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('Tidak ada data.'));
            }

            final data = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HeaderWidget(),
                  const SizedBox(height: 24),

                  // Top Stats Cards
                  _buildGradientStatsGrid(data),

                  const SizedBox(height: 24),

                  // "Butuh Persetujuan" Section
                  _buildPendingSection(data),

                  const SizedBox(height: 24),

                  // Financial Chart
                  // Carousel Chart Widget
                  CarouselChartWidget(
                    data: data,
                    simpananList: (data['simpanan_list'] as List?) ?? [],
                    pinjamanList: (data['pinjaman_list'] as List?) ?? [],
                    anggotaList: (data['anggota_list'] as List?) ?? [],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 10),
                Text(
                  'Menu Ketua',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Daftar Anggota'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => AnggotaListScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on_outlined),
            title: const Text('Laporan Pinjaman'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => const LaporanPinjamanScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Laporan Simpanan'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => const LaporanSimpananScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Laporan Angsuran'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => const LaporanAngsuranScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.percent, color: Colors.green),
            title: const Text('Pengaturan Bunga'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => const BungaSettingListScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGradientStatsGrid(Map<String, dynamic> data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildGradientCard(
                'Total Aset',
                data['estimated_assets'] ?? 0,
                Icons.account_balance_wallet,
                [const Color(0xFF0D47A1), const Color(0xFF1976D2)],
                isCurrency: true,
                onTap: () {
                  // Total Kas/Aset is closely related to Simpanan
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const LaporanSimpananScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGradientCard(
                'Anggota Aktif',
                data['total_anggota'] ?? 0,
                Icons.people_alt,
                [const Color(0xFF4A148C), const Color(0xFF7B1FA2)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const AnggotaListScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildGradientCard(
                'Pinjaman Berjalan', // Label remains, value changes to Rp
                data['total_angsuran_aktif_val'] ?? 0,
                Icons.trending_up,
                [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
                isCurrency: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const LaporanPinjamanScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGradientCard(
                'Kas Masuk (Sukarela)',
                data['kas_masuk_sukarela'] ?? 0,
                Icons.savings,
                [const Color(0xFFE65100), const Color(0xFFF57C00)],
                isCurrency: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const LaporanSimpananScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGradientCard(
    String title,
    dynamic value,
    IconData icon,
    List<Color> colors, {
    bool isCurrency = false,
    VoidCallback? onTap,
  }) {
    String displayValue = value.toString();
    if (isCurrency && value is num) {
      displayValue = formatRupiah(value);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white.withOpacity(0.8), size: 28),
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                displayValue,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingSection(Map<String, dynamic> data) {
    int pendingPinjaman = data['pending_pinjaman'] ?? 0;
    int pendingSimpanan = data['pending_simpanan'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Butuh Persetujuan',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Pinjaman',
                pendingPinjaman,
                Colors.orange,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const LaporanPinjamanScreen(
                        initialFilterStatus: 'pending',
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Simpanan',
                pendingSimpanan,
                Colors.blue,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const LaporanSimpananScreen(
                        initialFilterStatus: 'pending',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String label,
    int count,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
