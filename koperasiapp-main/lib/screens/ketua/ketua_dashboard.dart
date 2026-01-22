import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

import '../../widgets/header_widget.dart';
import '../../widgets/kpi_grid_widget.dart';
import '../../widgets/financial_chart_widget.dart';
import '../../widgets/recent_activity_widget.dart';
import '../karyawan/anggota_list_screen.dart';
import 'laporan_pinjaman_screen.dart';
import 'laporan_simpanan_screen.dart';
import 'laporan_angsuran_screen.dart';

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
      final angsuranList = await _apiService.getAngsuranKetua();

      // Hitung angsuran aktif (status != 'lunas')
      final activeAngsuranCount = angsuranList
          .where(
            (item) =>
                (item['status'] ?? '').toString().toLowerCase() != 'lunas',
          )
          .length;

      // Gabungkan data
      final Map<String, dynamic> mergedData = Map.from(reports);
      mergedData['total_angsuran_aktif'] = activeAngsuranCount;

      return mergedData;
    } catch (e) {
      // Jika error, kembalikan map kosong atau rethrow
      // Di sini kita rethrow agar FutureBuilder menangkap errornya
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Dashboard Ketua',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      drawer: Drawer(
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
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 60,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat laporan',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: _loadData,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Tidak ada data laporan.'));
            }

            final data = snapshot.data!;

            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return _buildWideLayout(data);
                }
                return _buildNarrowLayout(data);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNarrowLayout(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Column(
        children: [
          const HeaderWidget(),
          const SizedBox(height: 24),
          KpiGridWidget(data: data, crossAxisCount: 2),
          const SizedBox(height: 24),
          FinancialChartWidget(data: data),
          const SizedBox(height: 24),
          RecentActivityWidget(
            activities: (data['recent_activity'] as List?) ?? [],
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        children: [
          const HeaderWidget(),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    KpiGridWidget(data: data, crossAxisCount: 2),
                    const SizedBox(height: 30),
                    FinancialChartWidget(data: data),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                flex: 1,
                child: RecentActivityWidget(
                  activities: (data['recent_activity'] as List?) ?? [],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
