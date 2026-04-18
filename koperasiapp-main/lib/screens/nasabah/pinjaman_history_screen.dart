import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'pinjaman_detail_screen.dart';

class PinjamanHistoryScreen extends StatefulWidget {
  const PinjamanHistoryScreen({super.key});

  @override
  State<PinjamanHistoryScreen> createState() => _PinjamanHistoryScreenState();
}

class _PinjamanHistoryScreenState extends State<PinjamanHistoryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _apiService.getMyPinjaman();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return const Color(0xFF2E7D32);
      case 'ditolak':
        return Colors.red;
      case 'lunas':
        return const Color(0xFF1565C0);
      case 'perlu_perbaikan':
        return Colors.orange;
      default:
        return const Color(0xFF757575);
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return 'Pinjaman sedang berjalan dengan lancar';
      case 'pending':
        return 'Dokumen sedang diverifikasi analis';
      case 'perlu_perbaikan':
        return 'Revisi dokumen diperlukan segera';
      case 'lunas':
        return 'Pinjaman telah diselesaikan sepenuhnya';
      case 'ditolak':
        return 'Pengajuan tidak dapat diproses';
      default:
        return 'Status dalam peninjauan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Riwayat Pinjaman',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat riwayat.', style: GoogleFonts.poppins()));
          }

          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 60, color: Colors.grey[200]),
                  const SizedBox(height: 16),
                  Text('Belum ada riwayat pinjaman', style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            itemBuilder: (context, index) {
              return _buildLoanCard(list[index], formatter).animate().fadeIn(delay: (index * 50).ms).slideX();
            },
          );
        },
      ),
    );
  }

  Widget _buildLoanCard(dynamic pinjaman, NumberFormat formatter) {
    final status = pinjaman['status'].toString();
    final statusColor = _getStatusColor(status);
    final createdAt = DateTime.parse(pinjaman['created_at']);
    final dateStr = DateFormat('d Okt yyyy').format(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FF), // Harmonious light blue
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NasabahPinjamanDetailScreen(
                    pinjamanId: pinjaman['id'],
                  ),
                ),
              );
            },
            contentPadding: const EdgeInsets.all(20),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(Icons.credit_card, color: Theme.of(context).colorScheme.primary),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PINJAMAN KILAT • L-${pinjaman['id'].toString().padLeft(4, '0')}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(double.parse(pinjaman['nominal'].toString())),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF212121),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Tenor: ${pinjaman['tenor_cicilan']} bulan',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    status.substring(0, 1).toUpperCase() + status.substring(1),
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.02),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border(top: BorderSide(color: Colors.grey[100]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 14, color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
                const SizedBox(width: 8),
                Text(
                  _getStatusMessage(status),
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
