import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/currency_formatter.dart';
import 'pinjaman_form_screen.dart';
import 'pinjaman_detail_screen.dart';
import 'pinjaman_history_screen.dart';

class PinjamanScreen extends StatefulWidget {
  const PinjamanScreen({super.key});

  @override
  State<PinjamanScreen> createState() => _PinjamanScreenState();
}

class _PinjamanScreenState extends State<PinjamanScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _pinjamanFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _pinjamanFuture = _apiService.getMyPinjaman();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui': return const Color(0xFF2E7D32);
      case 'ditolak': return Colors.red;
      case 'lunas': return const Color(0xFF1976D2);
      case 'perlu_perbaikan': return Colors.orange;
      default: return const Color(0xFF757575);
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui': return 'Pinjaman berjalan lancar';
      case 'pending': return 'Verifikasi analis sedang berjalan';
      case 'perlu_perbaikan': return 'Revisi dokumen diperlukan';
      case 'lunas': return 'Telah lunas sepenuhnya';
      case 'ditolak': return 'Pengajuan ditolak';
      default: return 'Status dalam peninjauan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: FutureBuilder<List<dynamic>>(
          future: _pinjamanFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final pinjamanList = snapshot.data ?? [];
            double totalActiveLoan = 0;
            double thisMonthBill = 0;
            final now = DateTime.now();

            for (var pinjaman in pinjamanList) {
              if (pinjaman['status'] == 'disetujui') {
                double originalNominal = double.parse(pinjaman['nominal'].toString());
                double paidAmount = 0;
                final angsurans = pinjaman['angsurans'] as List? ?? [];
                
                // Track paid amount for total active loan
                for (var angs in angsurans) {
                  if (angs['status'] == 'lunas') {
                    paidAmount += double.parse(angs['jumlah_bayar'].toString());
                  }
                }
                totalActiveLoan += (originalNominal - paidAmount);

                // Logic for Tagihan Bulan Ini
                final unpaidAngsurans = angsurans.where((a) {
                  final s = a['status'];
                  return s != 'lunas' && s != 'menunggu_konfirmasi';
                }).toList();

                if (unpaidAngsurans.isNotEmpty) {
                  // Sort by installment number to get the earliest one first
                  unpaidAngsurans.sort((a, b) => 
                    int.parse(a['angsuran_ke'].toString()).compareTo(int.parse(b['angsuran_ke'].toString()))
                  );

                  double currentDue = 0;
                  for (var angs in unpaidAngsurans) {
                    DateTime? dueDate = angs['tanggal_jatuh_tempo'] != null ? DateTime.parse(angs['tanggal_jatuh_tempo']) : null;
                    if (dueDate != null) {
                      bool isDueOrPast = dueDate.year < now.year || (dueDate.year == now.year && dueDate.month <= now.month);
                      if (isDueOrPast) {
                        currentDue += double.parse(angs['jumlah_bayar'].toString());
                      }
                    }
                  }

                  if (currentDue > 0) {
                    thisMonthBill += currentDue;
                  } else {
                    // Fallback: Show the first upcoming installment amount if none are due yet
                    thisMonthBill += double.parse(unpaidAngsurans.first['jumlah_bayar'].toString());
                  }
                }
              }
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildSliverHeader(totalActiveLoan, thisMonthBill),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(),
                        const SizedBox(height: 16),
                        if (pinjamanList.isEmpty)
                          _buildEmptyState()
                        else
                          ...pinjamanList.take(3).map((pinjaman) => _buildLoanCard(pinjaman)).toList(),
                        const SizedBox(height: 24),
                        _buildLimitCard(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => PinjamanFormScreen()));
          if (result == true) _loadData();
        },
        label: Text('Ajukan Pinjaman', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF0D47A1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ).animate().scale(delay: 500.ms),
    );
  }

  Widget _buildSliverHeader(double totalActiveLoan, double thisMonthBill) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saldo Pinjaman Aktif', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(formatRupiah(totalActiveLoan), style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 16),
                  const SizedBox(width: 12),
                  Text('Tagihan bulan ini: ', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                  Text(formatRupiah(thisMonthBill), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ],
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, size: 20, color: Color(0xFF0D47A1)),
            const SizedBox(width: 8),
            Text('Pinjaman Terakhir', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
          ],
        ),
        TextButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PinjamanHistoryScreen()));
          },
          child: Text('Riwayat >', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1))),
        ),
      ],
    );
  }

  Widget _buildLoanCard(dynamic pinjaman) {
    final status = pinjaman['status'].toString();
    final statusColor = _getStatusColor(status);
    final createdAt = DateTime.parse(pinjaman['created_at']);
    final dateStr = DateFormat('d MMM yyyy').format(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF0D47A1).withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => NasabahPinjamanDetailScreen(pinjamanId: pinjaman['id'])));
            },
            contentPadding: const EdgeInsets.all(20),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF1F5FF), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.credit_card_rounded, color: Color(0xFF0D47A1)),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('L-${pinjaman['id'].toString().padLeft(4, '0')}', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
                const SizedBox(height: 2),
                Text(formatRupiah(pinjaman['nominal']), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Tenor: ${pinjaman['tenor_cicilan']} bln', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(status.toUpperCase(), style: GoogleFonts.poppins(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text(dateStr, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFF8F9FF), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 14, color: statusColor.withOpacity(0.6)),
                const SizedBox(width: 8),
                Text(_getStatusMessage(status), style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.monetization_on_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Belum ada aktivitas pinjaman', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0D47A1).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_outlined, color: Color(0xFF0D47A1)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Limit Tersedia: Rp 10.000.000', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2D3436))),
                Text('Tingkatkan skor kredit dengan membayar tepat waktu.', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }
}
