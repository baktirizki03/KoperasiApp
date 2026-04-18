import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/currency_formatter.dart';
import '../../services/api_service.dart';
import 'pinjaman_form_screen.dart';

class NasabahPinjamanDetailScreen extends StatefulWidget {
  final int pinjamanId;

  const NasabahPinjamanDetailScreen({super.key, required this.pinjamanId});

  @override
  State<NasabahPinjamanDetailScreen> createState() =>
      _NasabahPinjamanDetailScreenState();
}

class _NasabahPinjamanDetailScreenState
    extends State<NasabahPinjamanDetailScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  late Future<Map<String, dynamic>> _pinjamanDetailFuture;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() {
    setState(() {
      _pinjamanDetailFuture = _apiService.getMyPinjamanDetail(widget.pinjamanId);
    });
  }

  Future<void> _konfirmasiBayar(int angsuranId) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mengirim bukti bayar...')));
      final bytes = await image.readAsBytes();
      await _apiService.confirmAngsuran(angsuranId, bytes, image.name);

      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi terkirim!'), backgroundColor: Colors.green));
        _loadDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _pinjamanDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData) return const Center(child: Text('Data tidak ditemukan.'));

          final pinjaman = snapshot.data!;
          final angsurans = (pinjaman['angsurans'] as List? ?? []);

          return CustomScrollView(
            slivers: [
              _buildHeader(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(pinjaman),
                      const SizedBox(height: 32),
                      _buildInstallmentHeader(),
                      const SizedBox(height: 16),
                      if (angsurans.isEmpty) _buildEmptyState() else ...angsurans.map((ang) => _buildAngsuranItem(ang)).toList(),
                      const SizedBox(height: 24),
                      _buildTipsBox(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2))),
            const SizedBox(width: 16),
            Text('Detail Pinjaman', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> pinjaman) {
    final status = pinjaman['status'].toString();
    return Container(
      padding: const EdgeInsets.all(24),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL PINJAMAN', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.7), letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(formatRupiah(pinjaman['nominal']), style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              _buildStatusBadge(status),
            ],
          ),
          if (status == 'ditolak' || status == 'perlu_perbaikan') _buildAlertBox(pinjaman),
          const SizedBox(height: 24),
          _buildDivider(),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.receipt_long_rounded, 'Keperluan', pinjaman['untuk_keperluan'] ?? '-'),
          _buildInfoRow(Icons.calendar_month_rounded, 'Tenor Pinjaman', '${pinjaman['tenor_cicilan']} Bulan'),
          _buildInfoRow(Icons.account_balance_rounded, 'Bank Penerima', pinjaman['nama_bank'] ?? '-'),
          _buildInfoRow(Icons.numbers_rounded, 'Nomor Rekening', pinjaman['no_rekening'] ?? '-'),
          _buildInfoRow(Icons.wallet_rounded, 'Pendapatan', formatRupiah(pinjaman['pendapatan_per_bulan'])),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.white;
    if (status == 'disetujui' || status == 'lunas') color = Colors.greenAccent;
    if (status == 'pending' || status == 'proses') color = Colors.orangeAccent;
    if (status == 'ditolak') color = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(status.toUpperCase(), style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withOpacity(0.6)),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.7))),
          const Spacer(),
          Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(height: 1, width: double.infinity, color: Colors.white.withOpacity(0.1));

  Widget _buildInstallmentHeader() {
    return Row(
      children: [
        const Icon(Icons.list_alt_rounded, size: 20, color: Color(0xFF0D47A1)),
        const SizedBox(width: 8),
        Text('Jadwal Angsuran', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
      ],
    );
  }

  Widget _buildAngsuranItem(dynamic angsuran) {
    bool isLunas = angsuran['status'] == 'lunas';
    bool isPending = angsuran['status'] == 'menunggu_konfirmasi';
    bool isDitolak = angsuran['status'] == 'ditolak';

    IconData icon = isLunas ? Icons.check_circle_rounded : (isPending ? Icons.pending_rounded : Icons.payment_rounded);
    Color color = isLunas ? Colors.green : (isPending ? Colors.orange : const Color(0xFF0D47A1));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Angsuran ke-${angsuran['angsuran_ke']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF2D3436))),
                Text(formatRupiah(angsuran['jumlah_bayar']), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
          if (!isLunas && !isPending)
            ElevatedButton(
              onPressed: () => _konfirmasiBayar(angsuran['id']),
              style: ElevatedButton.styleFrom(backgroundColor: isDitolak ? Colors.orange : const Color(0xFF0D47A1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: Text(isDitolak ? 'Revisi' : 'Bayar', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
            )
          else
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(isLunas ? 'LUNAS' : 'PROSES', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: color))),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildAlertBox(Map<String, dynamic> pinjaman) {
    bool isRevision = pinjaman['status'] == 'perlu_perbaikan';
    Color color = isRevision ? Colors.orangeAccent : Colors.redAccent;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.warning_amber_rounded, size: 16, color: color), const SizedBox(width: 8), Text(isRevision ? 'Catatan Perbaikan:' : 'Alasan Penolakan:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: color))]),
          const SizedBox(height: 4),
          Text(pinjaman['alasan_penolakan'] ?? '-', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withOpacity(0.9))),
          if (isRevision) ...[
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 40, child: ElevatedButton(onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (ctx) => PinjamanFormScreen(pinjaman: pinjaman)));
              if (result == true) _loadDetail();
            }, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0), child: Text('Perbaiki Pengajuan', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)))),
          ],
        ],
      ),
    );
  }

  Widget _buildTipsBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.1))),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_rounded, color: Color(0xFF1976D2)),
          const SizedBox(width: 16),
          Expanded(child: Text('Bayar angsuran tepat waktu untuk meningkatkan limit pinjaman Anda selanjutnya.', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF1565C0), height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text('Belum ada jadwal angsuran.', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey))));
}
