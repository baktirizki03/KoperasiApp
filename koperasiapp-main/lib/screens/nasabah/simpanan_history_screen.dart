import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/currency_formatter.dart';

class SimpananHistoryScreen extends StatefulWidget {
  const SimpananHistoryScreen({super.key});

  @override
  State<SimpananHistoryScreen> createState() => _SimpananHistoryScreenState();
}

class _SimpananHistoryScreenState extends State<SimpananHistoryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = _apiService.getMySimpanan();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return const Color(0xFF2E7D32);
      case 'ditolak':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return const Color(0xFF757575);
    }
  }

  String _getStatusMessage(String status, bool isKredit) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return isKredit ? 'Setoran telah berhasil diverifikasi' : 'Penarikan telah berhasil dicairkan';
      case 'pending':
        return 'Menunggu verifikasi bukti transfer oleh admin';
      case 'ditolak':
        return 'Transaksi ditolak oleh admin';
      default:
        return 'Status dalam peninjauan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Riwayat Simpanan',
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
      body: RefreshIndicator(
        onRefresh: () async => _loadHistory(),
        child: FutureBuilder<List<dynamic>>(
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
                    Text('Belum ada riwayat simpanan', style: GoogleFonts.poppins(color: Colors.grey)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: list.length,
              itemBuilder: (context, index) {
                return _buildTransactionCard(list[index], index).animate().fadeIn(delay: (index * 50).ms).slideX();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransactionCard(dynamic trans, int index) {
    final bool isKredit = trans['tipe']?.toString().toLowerCase() == 'kredit';
    final double nominal = double.tryParse(trans['nominal'].toString()) ?? 0;
    final status = trans['status']?.toString().toLowerCase() ?? 'pending';
    final statusColor = _getStatusColor(status);
    
    final dateStr = trans['tanggal'] != null 
        ? DateFormat('d Okt yyyy').format(DateTime.parse(trans['tanggal']))
        : '-';

    IconData icon = isKredit ? Icons.account_balance_wallet_rounded : Icons.upload_rounded;
    Color typeColor = isKredit ? Colors.green : Colors.red;

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
              child: Icon(
                icon, 
                color: typeColor
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isKredit ? 'SETORAN TABUNGAN' : 'PENARIKAN TABUNGAN',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: typeColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupiah(nominal),
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
                trans['jenis_transaksi'] ?? 'Simpanan Sukarela',
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
                    status.toUpperCase(),
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
                Icon(Icons.check_circle_outline, size: 14, color: typeColor.withOpacity(0.5)),
                const SizedBox(width: 8),
                Text(
                  _getStatusMessage(status, isKredit),
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
