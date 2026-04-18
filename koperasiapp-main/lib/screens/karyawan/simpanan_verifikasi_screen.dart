import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/secure_image_widget.dart';

class SimpananVerifikasiScreen extends StatefulWidget {
  const SimpananVerifikasiScreen({super.key});

  @override
  State<SimpananVerifikasiScreen> createState() => _SimpananVerifikasiScreenState();
}

class _SimpananVerifikasiScreenState extends State<SimpananVerifikasiScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _simpananFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _simpananFuture = _apiService.getSimpananPending();
    });
  }

  Future<void> _approveSimpanan(int id) async {
    try {
      await _apiService.approveSimpanan(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simpanan berhasil disetujui'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyetujui: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showImage(String path, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            Flexible(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                child: InteractiveViewer(
                  child: SecureImageWidget(imageUrl: path, fit: BoxFit.contain),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> simpanan) {
    final anggota = simpanan['anggota'];
    final isKetua = Provider.of<AuthProvider>(context, listen: false).role == 'ketua';
    final isKredit = simpanan['tipe']?.toString().toLowerCase() == 'kredit';
    final accentColor = isKredit ? const Color(0xFF00C853) : const Color(0xFFD32F2F);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: accentColor,
                      child: Icon(isKredit ? Icons.add_rounded : Icons.remove_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isKredit ? 'Verifikasi Setoran' : 'Verifikasi Penarikan',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: accentColor),
                          ),
                          Text(
                            anggota['nama_lengkap'] ?? 'N/A',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Email', anggota['user']?['email'] ?? '-'),
                    _buildDetailRow('Nominal', formatRupiah(simpanan['nominal'] ?? 0), isBold: true),
                    _buildDetailRow('Kategori', simpanan['jenis_transaksi'] ?? '-'),
                    _buildDetailRow('Tanggal', simpanan['tanggal'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(simpanan['tanggal'])) : '-'),
                    
                    if (!isKredit) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0D47A1).withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REKENING TUJUAN',
                              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1), letterSpacing: 1),
                            ),
                            const SizedBox(height: 12),
                            Text(anggota['nama_bank'] ?? '-', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(
                              anggota['no_rekening'] ?? '-',
                              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF0D47A1), letterSpacing: 1.5),
                            ),
                            Text('a.n. ${anggota['nama_lengkap'] ?? '-'}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],

                    if (isKredit && simpanan['bukti_transfer_path'] != null) ...[
                      const SizedBox(height: 16),
                      Text('BUKTI TRANSFER', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _showImage(simpanan['bukti_transfer_path'], 'Bukti Transfer'),
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SecureImageWidget(imageUrl: simpanan['bukti_transfer_path'], fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('TUTUP', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!isKetua)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _approveSimpanan(simpanan['id']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('SETUJUI', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
              color: isBold ? const Color(0xFF0D47A1) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: FutureBuilder<List<dynamic>>(
                future: _simpananFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins()));
                  
                  final simpananList = snapshot.data ?? [];
                  if (simpananList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_user_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada simpanan pending',
                            style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    itemCount: simpananList.length,
                    itemBuilder: (ctx, index) {
                      final simpanan = simpananList[index];
                      return _buildSimpananCard(simpanan, index);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 16, right: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verifikasi Simpanan',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                'Kelola setoran dan penarikan anggota',
                style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpananCard(Map<String, dynamic> simpanan, int index) {
    final anggota = simpanan['anggota'];
    final isKredit = simpanan['tipe']?.toString().toLowerCase() == 'kredit';
    final Color accentColor = isKredit ? const Color(0xFF00C853) : const Color(0xFFD32F2F);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showDetailDialog(simpanan),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Icon(isKredit ? Icons.south_west_rounded : Icons.north_east_rounded, color: accentColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anggota != null ? anggota['nama_lengkap'] : 'Nama tidak ada',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF2D3436)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isKredit ? "Setoran" : "Penarikan"} - ${simpanan['jenis_transaksi']}',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatRupiah(simpanan['nominal']),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: accentColor),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
  }
}
