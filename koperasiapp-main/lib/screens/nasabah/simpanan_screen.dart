import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:koperasiapp/screens/nasabah/simpanan_form_screen.dart';
import 'simpanan_tarik_screen.dart';
import '../../services/api_service.dart';
import '../../utils/currency_formatter.dart';

class SimpananScreen extends StatefulWidget {
  const SimpananScreen({super.key});

  @override
  State<SimpananScreen> createState() => _SimpananScreenState();
}

class _SimpananScreenState extends State<SimpananScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dataFuture = _fetchCombinedData();
    });
  }

  Future<Map<String, dynamic>> _fetchCombinedData() async {
    final dashboard = await _apiService.getDashboardData();
    final transactions = await _apiService.getMySimpanan();
    return {
      'total_simpanan': dashboard['total_simpanan'],
      'transactions': transactions,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return _buildErrorState();
            if (!snapshot.hasData) return _buildEmptyState();

            final data = snapshot.data!;
            final transactions = data['transactions'] as List;
            final double balance = double.tryParse(data['total_simpanan'].toString()) ?? 0;

            return Stack(
              children: [
                CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _buildHeader(),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildBalanceCard(balance),
                          const SizedBox(height: 32),
                          _buildActivityHeader(),
                          const SizedBox(height: 16),
                          if (transactions.isEmpty) _buildNoTransactionsState() else ...transactions.asMap().entries.map((e) => _buildTransactionItem(e.value, e.key)).toList(),
                          const SizedBox(height: 100),
                        ]),
                      ),
                    ),
                  ],
                ),
                _buildActionButtons(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(top: 60, bottom: 20, left: 24, right: 24),
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.vertical(bottom: Radius.circular(32))),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tabungan Kamu', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Kelola simpanan masa depanmu', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.8))),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF0D47A1).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL SALDO SIMPANAN', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.7), letterSpacing: 1.2)),
              Icon(Icons.auto_graph_rounded, color: Colors.white.withOpacity(0.6), size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(formatRupiah(balance), style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Container(height: 1, width: double.infinity, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 14),
              const SizedBox(width: 8),
              Text('Simpanan Aman & Terverifikasi', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withOpacity(0.8))),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildActivityHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, size: 20, color: Color(0xFF0D47A1)),
            const SizedBox(width: 8),
            Text('Aktivitas Terkini', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
          ],
        ),
        Text('Lihat Semua', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1))),
      ],
    );
  }

  Widget _buildTransactionItem(dynamic trans, int index) {
    final bool isKredit = trans['tipe']?.toString().toLowerCase() == 'kredit';
    final double nominal = double.tryParse(trans['nominal'].toString()) ?? 0;
    final status = trans['status']?.toString().toLowerCase() ?? 'pending';

    IconData icon = isKredit ? Icons.add_circle_rounded : Icons.remove_circle_rounded;
    Color iconColor = isKredit ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatRupiah(nominal), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2D3436))),
                Text(trans['jenis_transaksi'] ?? '-', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                Text(DateFormat('dd MMM yyyy').format(DateTime.parse(trans['tanggal'])), style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400])),
              ],
            ),
          ),
          _buildStatusBadge(status),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'disetujui') color = Colors.green;
    if (status == 'pending') color = Colors.orange;
    if (status == 'ditolak') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildFab(icon: Icons.upload_rounded, label: 'Tarik Saldo', onTap: () async {
            final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const SimpananTarikScreen()));
            if (res == true) _loadData();
          }),
          const SizedBox(height: 12),
          _buildFab(icon: Icons.add_rounded, label: 'Setor Simpanan', isPrimary: true, onTap: () async {
            final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const SimpananFormScreen()));
            if (res == true) _loadData();
          }),
        ],
      ),
    );
  }

  Widget _buildFab({required IconData icon, required String label, required VoidCallback onTap, bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(color: isPrimary ? const Color(0xFF0D47A1) : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: const Color(0xFF0D47A1).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isPrimary ? Colors.white : const Color(0xFF0D47A1)),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: isPrimary ? Colors.white : const Color(0xFF0D47A1))),
          ],
        ),
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
  }

  Widget _buildErrorState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey), const SizedBox(height: 16), Text('Gagal Memuat Data', style: GoogleFonts.poppins(color: Colors.grey)), TextButton(onPressed: _loadData, child: const Text('Coba Lagi'))]));
  Widget _buildEmptyState() => Center(child: Text('Data tidak ditemukan', style: GoogleFonts.poppins(color: Colors.grey)));
  Widget _buildNoTransactionsState() => Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Text('Belum ada transaksi.', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey))));
}
