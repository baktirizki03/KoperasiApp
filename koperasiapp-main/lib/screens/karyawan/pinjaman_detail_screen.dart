import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/secure_image_widget.dart';

class PinjamanDetailScreen extends StatefulWidget {
  final int pinjamanId;

  const PinjamanDetailScreen({super.key, required this.pinjamanId});

  @override
  State<PinjamanDetailScreen> createState() => _PinjamanDetailScreenState();
}

class _PinjamanDetailScreenState extends State<PinjamanDetailScreen> {
  final ApiService _apiService = ApiService();
  final _alasanController = TextEditingController();
  late Future<Map<String, dynamic>> _pinjamanDetailFuture;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() {
    setState(() {
      _pinjamanDetailFuture = _apiService.getPinjamanDetail(widget.pinjamanId);
    });
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _approvePinjaman() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Konfirmasi Persetujuan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menyetujui pengajuan pinjaman ini?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Ya, Setujui', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _showLoadingDialog();
    try {
      await _apiService.approvePinjaman(widget.pinjamanId);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pinjaman berhasil disetujui'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
      Navigator.of(context).pop(true);
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    }
  }

  void _rejectPinjaman() async {
    final alasan = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Alasan Penolakan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _alasanController,
          decoration: InputDecoration(hintText: 'Masukkan alasan penolakan', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
          autofocus: true,
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey))),
          ElevatedButton(
            onPressed: () { if (_alasanController.text.isNotEmpty) Navigator.of(ctx).pop(_alasanController.text); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Tolak Pinjaman', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (alasan != null && alasan.isNotEmpty) {
      _showLoadingDialog();
      try {
        await _apiService.rejectPinjaman(widget.pinjamanId, alasan);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pinjaman berhasil ditolak'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating));
        Navigator.of(context).pop(true);
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _requestRevision() async {
    final alasan = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Minta Perbaikan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _alasanController,
          decoration: InputDecoration(hintText: 'Jelaskan apa yang perlu diperbaiki...', labelText: 'Catatan Perbaikan', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey))),
          ElevatedButton(
            onPressed: () { if (_alasanController.text.isNotEmpty) Navigator.of(ctx).pop(_alasanController.text); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Kirim Permintaan', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (alasan != null && alasan.isNotEmpty) {
      _showLoadingDialog();
      try {
        await _apiService.requestRevision(widget.pinjamanId, alasan);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permintaan perbaikan berhasil dikirim'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating));
        Navigator.of(context).pop(true);
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _confirmPayAngsuran(int angsuranId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Konfirmasi Pembayaran', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin mengonfirmasi pembayaran untuk angsuran ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Ya, Konfirmasi', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _showLoadingDialog();
      try {
        await _apiService.payAngsuran(angsuranId);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran berhasil dicatat'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
        _loadDetail();
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _rejectAngsuran(int angsuranId) async {
    final alasan = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Tolak Bukti Pembayaran', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _alasanController,
          decoration: InputDecoration(hintText: 'Pastikan alasan jelas agar nasabah paham', labelText: 'Alasan Penolakan', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
          maxLines: 2,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey))),
          ElevatedButton(
            onPressed: () { if (_alasanController.text.isNotEmpty) Navigator.of(ctx).pop(_alasanController.text); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Kirim Revisi', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (alasan != null && alasan.isNotEmpty) {
      _showLoadingDialog();
      try {
        await _apiService.rejectAngsuran(angsuranId, alasan);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penolakan dikirim ke nasabah'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating));
        _alasanController.clear();
        _loadDetail();
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
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
                child: InteractiveViewer(child: SecureImageWidget(imageUrl: path)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKetua = Provider.of<AuthProvider>(context, listen: false).role == 'ketua';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _pinjamanDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins()));
          if (!snapshot.hasData) return Center(child: Text('Data tidak ditemukan.', style: GoogleFonts.poppins()));

          final pinjaman = snapshot.data!;
          final anggota = pinjaman['anggota'];
          final angsurans = pinjaman['angsurans'] as List;
          final bool isPending = pinjaman['status'] == 'pending';
          final bool isApproved = pinjaman['status'] == 'disetujui' || pinjaman['status'] == 'lunas';

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(pinjaman, anggota),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // --- PROFILE CARD ---
                    _buildSectionCard(
                      title: 'Profil Anggota',
                      icon: Icons.person_outline_rounded,
                      children: [
                        _buildDetailRow('No. KTP', anggota['nomor_ktp'] ?? '-'),
                        _buildDetailRow('Telepon', anggota['no_telepon'] ?? '-'),
                        _buildDetailRow('TTL', '${anggota['tempat_lahir'] ?? '-'}, ${anggota['tanggal_lahir'] ?? '-'}'),
                        _buildDetailRow('Alamat', anggota['domisili'] ?? '-'),
                        _buildDetailRow('Pekerjaan', pinjaman['departemen_pekerjaan'] ?? anggota['pekerjaan'] ?? '-'),
                      ],
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 16),

                    // --- LOAN DETAILS CARD ---
                    _buildSectionCard(
                      title: 'Rincian Pengajuan',
                      icon: Icons.account_balance_wallet_outlined,
                      children: [
                        _buildDetailRow('Nominal', formatRupiah(pinjaman['nominal'])),
                        _buildDetailRow('Tenor', '${pinjaman['tenor_cicilan']} Bulan'),
                        _buildDetailRow('Bunga', '${pinjaman['bunga'] ?? '0'} %'),
                        _buildDetailRow('Keperluan', pinjaman['untuk_keperluan'] ?? '-'),
                        _buildDetailRow('Metode', pinjaman['metode_pembayaran']?.toUpperCase() ?? 'TRANSFER'),
                      ],
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 16),

                    // --- DOCUMENTS CARD ---
                    _buildSectionCard(
                      title: 'Berkas Dokumentasi',
                      icon: Icons.folder_open_rounded,
                      children: [
                        if (pinjaman['foto_kk'] != null) _buildDocTile('Foto Kartu Keluarga', pinjaman['foto_kk'], Colors.purple),
                        if (pinjaman['foto_id_karyawan'] != null) _buildDocTile('ID Karyawan', pinjaman['foto_id_karyawan'], Colors.blue),
                        if (pinjaman['slip_gaji_path'] != null) _buildDocTile('Slip Gaji Terakhir', pinjaman['slip_gaji_path'], Colors.orange),
                        if (anggota['ktp_path'] != null) _buildDocTile('Foto KTP Anggota', anggota['ktp_path'], Colors.teal),
                      ],
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

                    // --- STATUS / REJECTION REASON ---
                    if (pinjaman['status'] == 'ditolak') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red[100]!)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Alasan Penolakan:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red[700])),
                            const SizedBox(height: 4),
                            Text(pinjaman['alasan_penolakan'] ?? 'Tidak disebutkan', style: GoogleFonts.poppins(color: Colors.red[900])),
                          ],
                        ),
                      ),
                    ],

                    // --- ACTION BUTTONS (PENDING) ---
                    if (isPending && !isKetua) ...[
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              label: 'TOLAK',
                              icon: Icons.close_rounded,
                              color: Colors.red,
                              onPressed: _rejectPinjaman,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              label: 'SETUJUI',
                              icon: Icons.check_rounded,
                              color: Colors.green,
                              onPressed: _approvePinjaman,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _requestRevision,
                          icon: const Icon(Icons.edit_note_rounded),
                          label: Text('MINTA PERBAIKAN DATA', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange[800],
                            side: BorderSide(color: Colors.orange[800]!),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],

                    // --- INSTALLMENT SCHEDULE ---
                    if (isApproved && angsurans.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Icon(Icons.event_note_rounded, color: const Color(0xFF0D47A1), size: 20),
                          const SizedBox(width: 12),
                          Text('Jadwal Angsuran', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(angsurans.length, (i) => _buildInstallmentCard(angsurans[i], isKetua)),
                    ],
                    
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> pinjaman, Map<String, dynamic> anggota) {
    final String initial = (anggota['nama_lengkap'] != null && anggota['nama_lengkap'].toString().isNotEmpty)
        ? anggota['nama_lengkap'].toString()[0].toUpperCase()
        : '?';
    final String userEmail = (anggota['user'] != null && anggota['user']['email'] != null)
        ? anggota['user']['email'].toString()
        : 'Email tidak tersedia';

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
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(pinjaman['status']?.toUpperCase() ?? 'PENDING', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 40, 
              backgroundColor: Colors.white.withOpacity(0.2), 
              child: Text(initial, style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))
            ),
            const SizedBox(height: 16),
            Text(anggota['nama_lengkap'] ?? 'Nama Anggota', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(userEmail, style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 13)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Text('TOTAL PENGAJUAN', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(formatRupiah(pinjaman['nominal']), style: GoogleFonts.poppins(color: const Color(0xFF0D47A1), fontSize: 20, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: const Color(0xFF0D47A1), size: 20), const SizedBox(width: 12), Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF2D3436)))]),
          const Divider(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12))),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF2D3436)))),
        ],
      ),
    );
  }

  Widget _buildDocTile(String title, String path, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.1))),
      child: ListTile(
        onTap: () => _showImage(path, title),
        leading: Icon(Icons.description_outlined, color: color),
        title: Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.visibility_outlined, size: 20),
      ),
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    );
  }

  Widget _buildInstallmentCard(Map<String, dynamic> angsuran, bool isKetua) {
    final bool lunas = angsuran['status'] == 'lunas';
    final bool waiting = angsuran['status'] == 'menunggu_konfirmasi';
    final color = lunas ? Colors.green : (waiting ? Colors.orange : Colors.grey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        children: [
          ListTile(
            leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Center(child: Text('${angsuran['angsuran_ke']}', style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold)))),
            title: Text(formatRupiah(angsuran['jumlah_angsuran'] ?? angsuran['jumlah_bayar']), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text('Jatuh Tempo: ${DateFormat('dd MMM yyyy').format(DateTime.parse(angsuran['tanggal_jatuh_tempo']))}', style: GoogleFonts.poppins(fontSize: 12)),
            trailing: lunas ? const Icon(Icons.check_circle_rounded, color: Colors.green) : (waiting ? Icon(Icons.hourglass_empty_rounded, color: Colors.orange[700]) : null),
          ),
          if (!lunas && !isKetua)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (angsuran['bukti_bayar_path'] != null)
                    TextButton.icon(
                      onPressed: () => _showImage(angsuran['bukti_bayar_path'], 'Bukti Pembayaran'),
                      icon: const Icon(Icons.image_search_rounded, size: 18),
                      label: Text('LIHAT BUKTI', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(width: 8),
                  if (waiting)
                    OutlinedButton(
                      onPressed: () => _rejectAngsuran(angsuran['id']),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: Text('TOLAK', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _confirmPayAngsuran(angsuran['id']),
                    style: ElevatedButton.styleFrom(backgroundColor: waiting ? Colors.orange : const Color(0xFF0D47A1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: Text(waiting ? 'VERIFIKASI' : 'MANUAL BAYAR', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'lunas': return Colors.green;
      case 'disetujui': return Colors.blue;
      case 'ditolak': return Colors.red;
      default: return Colors.orange;
    }
  }
}
