import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';

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
          _userName = profile['nama_lengkap'] ?? 'Nasabah';
        });
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal memuat data',
                      style: TextStyle(color: Colors.grey),
                    ),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('Tidak ada data.'));
            }

            final data = snapshot.data!;
            final totalSimpanan = data['total_simpanan'];
            final riwayatAngsuran = data['riwayat_angsuran'] as List;
            final riwayatSimpanan = data['riwayat_simpanan'] as List;

            return ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                _buildHeader(),
                _buildSaldoCard(totalSimpanan),
                _buildRiwayatSection(riwayatAngsuran, riwayatSimpanan),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Halo, $_userName!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3436),
            ),
          ),
          Text(
            'Selamat datang kembali',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ).animate().fadeIn().slideX(),
    );
  }

  Widget _buildSaldoCard(dynamic totalSimpanan) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final saldo = (totalSimpanan is String)
        ? double.parse(totalSimpanan)
        : totalSimpanan.toDouble();

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withBlue(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Saldo Simpanan',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            formatter.format(saldo),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 200.ms);
  }

  Widget _buildRiwayatSection(List riwayatAngsuran, List riwayatSimpanan) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Text(
              'Riwayat Transaksi',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                ),
              ],
            ),
            child: TabBar(
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Theme.of(context).colorScheme.secondary,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Pinjaman'),
                Tab(text: 'Simpanan'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 400,
            child: TabBarView(
              children: [
                _buildRiwayatList(riwayatAngsuran, isAngsuran: true),
                _buildRiwayatList(riwayatSimpanan, isAngsuran: false),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildRiwayatList(List items, {required bool isAngsuran}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 50, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(
              'Belum ada riwayat',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAngsuran
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAngsuran ? Icons.receipt_long_rounded : Icons.savings_rounded,
                color: isAngsuran ? Colors.orange : Colors.green,
              ),
            ),
            title: Text(
              isAngsuran
                  ? 'Angsuran ke-${item['angsuran_ke']}'
                  : item['jenis_transaksi'],
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              isAngsuran ? '${item['tanggal_bayar']}' : '${item['tanggal']}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            trailing: Text(
              formatter.format(
                double.parse(
                  isAngsuran
                      ? item['jumlah_bayar'].toString()
                      : item['nominal'].toString(),
                ),
              ),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: isAngsuran ? Colors.orange[700] : Colors.green[700],
              ),
            ),
          ),
        ).animate().fadeIn(delay: (50 * index).ms).slideX();
      },
    );
  }
}
