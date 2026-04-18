import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/pdf_export_dialog.dart';

class LaporanAngsuranScreen extends StatefulWidget {
  const LaporanAngsuranScreen({super.key});

  @override
  State<LaporanAngsuranScreen> createState() => _LaporanAngsuranScreenState();
}

class _LaporanAngsuranScreenState extends State<LaporanAngsuranScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allData = [];
  List<Map<String, dynamic>> _groupedData = [];
  bool _isLoading = true;
  String _filterStatusLaporan = 'Aktif';
  bool _isDownloadingPdf = false;

  double _totalMasukBulanIni = 0;
  int _totalMenunggak = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final role = authProvider.role?.toLowerCase();
      List<dynamic> rawData = [];

      if (role == 'ketua') {
        rawData = await _apiService.getPinjamanKetua();
      }

      setState(() {
        _allData = rawData;
        _groupData();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  void _groupData() {
    final Map<String, Map<String, dynamic>> groups = {};
    final query = _searchController.text.toLowerCase();

    for (var loan in _allData) {
      final pinjaman = loan;
      final anggota = loan['anggota'] ?? {};
      final pinjamanId = (loan['id'] ?? 'unknown').toString();
      final List<dynamic> angsurans = (loan['angsuran'] ?? loan['angsurans'] ?? []) as List<dynamic>;

      final nama = (anggota['nama_lengkap'] ?? '').toString().toLowerCase();
      final noAnggota = (anggota['nomor_anggota'] ?? '').toString().toLowerCase();

      if (query.isNotEmpty && !nama.contains(query) && !noAnggota.contains(query)) continue;

      final statusPinjaman = (loan['status'] ?? '').toString().toLowerCase();
      if (statusPinjaman != 'disetujui' && statusPinjaman != 'lunas') continue;

      groups[pinjamanId] = {
        'pinjaman': pinjaman,
        'anggota': anggota,
        'angsurans': angsurans,
        'status_laporan': 'Lancar',
        'progress_text': '0/0',
      };
    }

    List<Map<String, dynamic>> processedList = [];
    double tempMasukBulanIni = 0;
    int tempMenunggak = 0;
    final now = DateTime.now();

    for (var key in groups.keys) {
      final group = groups[key]!;
      final angsurans = group['angsurans'] as List<dynamic>;
      final pinjaman = group['pinjaman'];

      int total = int.tryParse((pinjaman['lama_angsuran'] ?? '0').toString()) ?? 0;
      if (total == 0) total = angsurans.length;

      int paid = 0;
      bool isMenunggak = false;

      angsurans.sort((a, b) {
        final seqA = int.tryParse(a['angsuran_ke'].toString()) ?? 0;
        final seqB = int.tryParse(b['angsuran_ke'].toString()) ?? 0;
        return seqA.compareTo(seqB);
      });

      for (var ang in angsurans) {
        final status = (ang['status'] ?? '').toString().toLowerCase();
        final dueDateStr = ang['tanggal_jatuh_tempo'];
        double getAngsNominal = double.tryParse((ang['jumlah_bayar'] ?? ang['jumlah_angsuran'] ?? '0').toString()) ?? 0;

        if (status == 'lunas' || status == 'disetujui') {
          paid++;
          final paidDateStr = ang['updated_at'] ?? ang['created_at'];
          if (paidDateStr != null) {
            final paidDate = DateTime.tryParse(paidDateStr);
            if (paidDate != null && paidDate.year == now.year && paidDate.month == now.month) {
              tempMasukBulanIni += getAngsNominal;
            }
          }
        } else {
          if (dueDateStr != null) {
            final dueDate = DateTime.tryParse(dueDateStr);
            if (dueDate != null && dueDate.isBefore(now)) isMenunggak = true;
          }
        }
      }

      group['progress_text'] = '$paid/$total';
      group['progress_value'] = total > 0 ? (paid / total) : 0.0;
      group['status_laporan'] = isMenunggak ? 'Menunggak' : 'Lancar';

      final statusPinjaman = (pinjaman['status'] ?? '').toString().toLowerCase();
      if (statusPinjaman == 'lunas' || (paid >= total && total > 0)) {
        group['status_laporan'] = 'Selesai';
        group['progress_text'] = '$total/$total';
        group['progress_value'] = 1.0;
      }

      if (group['status_laporan'] == 'Menunggak') tempMenunggak++;

      double nominalPinjaman = double.tryParse(pinjaman['nominal'].toString()) ?? 0;
      double totalBayar = 0;
      for (var ang in angsurans) {
        if ((ang['status'] ?? '').toString().toLowerCase() == 'lunas' || (ang['status'] ?? '').toString().toLowerCase() == 'disetujui') {
          totalBayar += double.tryParse((ang['jumlah_bayar'] ?? ang['jumlah_angsuran'] ?? '0').toString()) ?? 0;
        }
      }
      double sisaHutang = nominalPinjaman - totalBayar;
      group['sisa_hutang'] = sisaHutang < 0 ? 0 : sisaHutang;

      bool include = false;
      if (_filterStatusLaporan == 'Semua') include = true;
      else if (_filterStatusLaporan == 'Selesai') { if (group['status_laporan'] == 'Selesai') include = true; }
      else { if (group['status_laporan'] != 'Selesai') include = true; }

      if (include) processedList.add(group);
    }

    setState(() {
      _groupedData = processedList;
      _totalMasukBulanIni = tempMasukBulanIni;
      _totalMenunggak = tempMenunggak;
    });
  }

  void _filterData() => _groupData();

  Future<void> _exportPdf() async {
    final result = await showDialog<Map<String, int?>?>(
      context: context,
      builder: (ctx) => const PdfExportDialog(title: 'Laporan Angsuran'),
    );

    if (result != null) {
      setState(() => _isDownloadingPdf = true);
      try {
        await _apiService.downloadPdf('export/angsuran', 'Laporan_Angsuran.pdf', bulan: result['bulan'], tahun: result['tahun']);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil membuka PDF'), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isDownloadingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _fetchData(),
              child: CustomScrollView(
                slivers: [
                  _buildSliverHeader(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          _buildIntegratedSummary(),
                          const SizedBox(height: 16),
                          _buildListHeader(),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  _groupedData.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 100),
                              child: Column(
                                children: [
                                  Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text('Tidak ada data ditemukan', style: GoogleFonts.poppins(color: Colors.grey[500])),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildMemberInstallmentCard(_groupedData[index], index),
                              childCount: _groupedData.length,
                            ),
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: const Color(0xFF0D47A1),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
        ),
      ),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
      title: Text('Laporan Angsuran', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      actions: [
        if (_isDownloadingPdf)
          const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
        else
          IconButton(icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white), onPressed: _exportPdf),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _filterData(),
                    decoration: InputDecoration(
                      hintText: 'Cari Anggota...',
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0D47A1)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterStatusLaporan,
                      isExpanded: true,
                      items: ['Aktif', 'Selesai', 'Semua'].map((val) {
                        return DropdownMenuItem<String>(value: val, child: Text(val, style: GoogleFonts.poppins(fontSize: 12)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _filterStatusLaporan = val;
                            _groupData();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntegratedSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KAS MASUK BULAN INI', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(formatRupiah(_totalMasukBulanIni), style: GoogleFonts.poppins(color: Colors.green[700], fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.trending_up_rounded, color: Colors.green, size: 24)),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('$_totalMenunggak', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[700])),
                    Text('Gagal Bayar', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(height: 30, width: 1, color: Colors.grey[200]),
              Expanded(
                child: Column(
                  children: [
                    Text('${_groupedData.length}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1))),
                    Text('Total Aktif', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Ringkasan Progres Angsuran', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
        Text('${_groupedData.length} Orang', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildMemberInstallmentCard(Map<String, dynamic> group, int index) {
    final anggota = group['anggota'];
    final status = group['status_laporan'];
    final progressVal = group['progress_value'] as double;
    final progressText = group['progress_text'] as String;

    Color statusColor = status == 'Menunggak' ? Colors.red : status == 'Selesai' ? Colors.blue : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(group),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF0D47A1).withOpacity(0.05), shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, color: Color(0xFF0D47A1), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(anggota['nama_lengkap'] ?? '-', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
                        Text('Sisa: ${formatRupiah(group['sisa_hutang'])}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status, statusColor),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(value: progressVal, backgroundColor: Colors.grey[100], color: statusColor, minHeight: 8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(progressText, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(text.toUpperCase(), style: GoogleFonts.poppins(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
    );
  }

  void _showDetailDialog(Map<String, dynamic> group) {
    final anggota = group['anggota'];
    final pinjaman = group['pinjaman'];
    final angsurans = group['angsurans'] as List<dynamic>;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)])),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rincian Angsuran', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(anggota['nama_lengkap'] ?? '-', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pinjaman Awal', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 10)),
                          Text(formatRupiah(double.tryParse(pinjaman['nominal'].toString()) ?? 0), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Sisa Hutang', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 10)),
                          Text(formatRupiah(group['sisa_hutang']), style: GoogleFonts.poppins(color: Colors.orange[300], fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: angsurans.length,
                itemBuilder: (ctx, index) {
                  final item = angsurans[index];
                  final status = (item['status'] ?? '').toString().toLowerCase();
                  final isPaid = status == 'lunas' || status == 'disetujui';
                  bool isOverdue = false;
                  if (!isPaid) {
                    final dueDate = DateTime.tryParse(item['tanggal_jatuh_tempo'] ?? '');
                    if (dueDate != null && dueDate.isBefore(DateTime.now())) isOverdue = true;
                  }

                  Color itemColor = isPaid ? Colors.green : isOverdue ? Colors.red : Colors.orange;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: itemColor.withOpacity(0.1), shape: BoxShape.circle),
                          child: Text('${item['angsuran_ke']}', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: itemColor)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(formatRupiah(double.tryParse((item['jumlah_bayar'] ?? item['jumlah_angsuran'] ?? '0').toString()) ?? 0), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                              Text('Jatuh Tempo: ${item['tanggal_jatuh_tempo'] != null ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(item['tanggal_jatuh_tempo']) ?? DateTime.now()) : '-'}', style: GoogleFonts.poppins(fontSize: 10, color: isOverdue ? Colors.red : Colors.grey)),
                            ],
                          ),
                        ),
                        _buildStatusBadgeMini(isPaid ? 'LUNAS' : (isOverdue ? 'MENUNGGAK' : 'PROSES'), itemColor),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(ctx), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(vertical: 14)), child: Text('Tutup', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold))))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadgeMini(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 8, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
