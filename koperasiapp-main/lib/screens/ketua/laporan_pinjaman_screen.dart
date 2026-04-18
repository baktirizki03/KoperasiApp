import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/pdf_export_dialog.dart';

class LaporanPinjamanScreen extends StatefulWidget {
  final String? initialFilterStatus;

  const LaporanPinjamanScreen({super.key, this.initialFilterStatus});

  @override
  State<LaporanPinjamanScreen> createState() => _LaporanPinjamanScreenState();
}

class _LaporanPinjamanScreenState extends State<LaporanPinjamanScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allData = [];
  List<Map<String, dynamic>> _groupedData = [];
  bool _isLoading = true;
  String _filterStatus = 'Semua';
  bool _isDownloadingPdf = false;

  double _totalPlafonAktif = 0;
  double _totalAngsuranMasuk = 0;
  double _totalSisaHutang = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilterStatus != null) {
      _filterStatus = widget.initialFilterStatus!;
    }
    _fetchAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final role = authProvider.role?.toLowerCase();
      List<dynamic> rawData = [];

      if (role == 'ketua') {
        rawData = await _apiService.getPinjamanKetua();
      } else {
        final pending = await _apiService.getPinjamanList('pending');
        final approved = await _apiService.getPinjamanList('disetujui');
        final rejected = await _apiService.getPinjamanList('ditolak');
        final lunas = await _apiService.getPinjamanList('lunas');
        rawData = [...pending, ...approved, ...rejected, ...lunas];
      }

      setState(() {
        _allData = rawData;
        _groupData();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  void _groupData() {
    final Map<String, Map<String, dynamic>> groups = {};
    final query = _searchController.text.toLowerCase();
    final filterStatus = _filterStatus.toLowerCase();

    double tempPlafon = 0;
    double tempMasuk = 0;

    for (var item in _allData) {
      final anggota = item['anggota'] ?? {};
      final userId = (item['user_id'] ?? 'unknown').toString();

      final nama = (anggota['nama_lengkap'] ?? '').toString().toLowerCase();
      final noAnggota = (anggota['nomor_anggota'] ?? '').toString().toLowerCase();
      if (query.isNotEmpty && !nama.contains(query) && !noAnggota.contains(query)) continue;

      final itemStatus = (item['status'] ?? '').toString().toLowerCase();
      bool matchesStatus = false;
      if (filterStatus == 'semua') {
        matchesStatus = true;
      } else if (filterStatus == 'pending') {
        matchesStatus = (itemStatus == 'menunggu_konfirmasi' || itemStatus == 'pending');
      } else {
        if (itemStatus.contains(filterStatus)) matchesStatus = true;
      }

      if (matchesStatus) {
        if (!groups.containsKey(userId)) {
          groups[userId] = {
            'anggota': anggota,
            'pinjaman': <dynamic>[],
            'summary': {'pending': 0, 'disetujui': 0, 'ditolak': 0, 'lunas': 0},
          };
        }

        groups[userId]!['pinjaman'].add(item);
        String summaryKey = itemStatus;
        if (itemStatus == 'menunggu_konfirmasi') summaryKey = 'pending';
        if (groups[userId]!['summary'].containsKey(summaryKey)) {
          groups[userId]!['summary'][summaryKey]++;
        }

        if (itemStatus == 'disetujui' || itemStatus == 'lunas') {
          double nominal = double.tryParse((item['nominal'] ?? '0').toString()) ?? 0;
          tempPlafon += nominal;
          if (item['angsurans'] != null && item['angsurans'] is List) {
            for (var angs in item['angsurans']) {
              if (angs['status'] == 'lunas' || angs['status'] == 'disetujui') {
                tempMasuk += double.tryParse((angs['jumlah_bayar'] ?? angs['jumlah_angsuran'] ?? '0').toString()) ?? 0;
              }
            }
          }
        }
      }
    }

    groups.removeWhere((key, value) => (value['pinjaman'] as List).isEmpty);

    setState(() {
      _groupedData = groups.values.toList();
      _totalPlafonAktif = tempPlafon;
      _totalAngsuranMasuk = tempMasuk;
      _totalSisaHutang = _totalPlafonAktif - _totalAngsuranMasuk;
      if (_totalSisaHutang < 0) _totalSisaHutang = 0;
    });
  }

  void _filterData() => _groupData();

  Future<void> _exportPdf() async {
    final result = await showDialog<Map<String, int?>?>(
      context: context,
      builder: (ctx) => const PdfExportDialog(title: 'Laporan Pinjaman'),
    );

    if (result != null) {
      setState(() => _isDownloadingPdf = true);
      try {
        await _apiService.downloadPdf('export/pinjaman', 'Laporan_Pinjaman.pdf', bulan: result['bulan'], tahun: result['tahun']);
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
              onRefresh: () async => _fetchAllData(),
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
                              (context, index) => _buildMemberCard(_groupedData[index], index),
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
      title: Text('Laporan Pinjaman', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
                      value: _filterStatus,
                      isExpanded: true,
                      items: [
                        {'label': 'Semua', 'val': 'Semua'},
                        {'label': 'Pending', 'val': 'pending'},
                        {'label': 'Aktif', 'val': 'disetujui'},
                        {'label': 'Lunas', 'val': 'lunas'},
                        {'label': 'Ditolak', 'val': 'ditolak'},
                      ].map((map) {
                        return DropdownMenuItem<String>(value: map['val'], child: Text(map['label']!, style: GoogleFonts.poppins(fontSize: 12)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _filterStatus = val;
                            _filterData();
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
                  Text('TOTAL PINJAMAN AKTIF', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(formatRupiah(_totalPlafonAktif), style: GoogleFonts.poppins(color: const Color(0xFF0D47A1), fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF0D47A1), size: 24)),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildSimpleStat('Angsuran Masuk', _totalAngsuranMasuk, Colors.green)),
              Container(height: 30, width: 1, color: Colors.grey[200]),
              Expanded(child: _buildSimpleStat('Sisa Hutang', _totalSisaHutang, Colors.orange)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildSimpleStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(formatRupiah(value), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
        Text(label, style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Daftar Pinjaman Anggota', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
        Text('${_groupedData.length} Orang', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildMemberCard(Map<String, dynamic> group, int index) {
    final anggota = group['anggota'];
    final summary = group['summary'] as Map<String, int>;

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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF0D47A1).withOpacity(0.05), shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded, color: Color(0xFF0D47A1), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(anggota['nama_lengkap'] ?? '-', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
                    Text('NIK: ${anggota['nomor_ktp'] ?? anggota['nomor_anggota'] ?? '-'}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              _buildSummaryBadges(summary),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildSummaryBadges(Map<String, int> summary) {
    List<Widget> badges = [];
    if (summary['pending']! > 0) badges.add(_miniBadge('${summary['pending']}', Colors.orange));
    if (summary['disetujui']! > 0) badges.add(_miniBadge('${summary['disetujui']}', Colors.green));
    if (summary['lunas']! > 0) badges.add(_miniBadge('${summary['lunas']}', Colors.blue));
    return Row(children: badges);
  }

  Widget _miniBadge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  void _showDetailDialog(Map<String, dynamic> group) {
    final anggota = group['anggota'];
    final pinjamanList = group['pinjaman'] as List<dynamic>;

    pinjamanList.sort((a, b) {
      final dateA = DateTime.tryParse(a['created_at']) ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['created_at']) ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

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
                  Text('Riwayat Pinjaman', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(anggota['nama_lengkap'] ?? '-', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: pinjamanList.length,
                itemBuilder: (ctx, index) {
                  final item = pinjamanList[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('dd MMM yyyy').format(DateTime.tryParse(item['created_at']) ?? DateTime.now()), style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                            _buildStatusBadge(item['status']),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(formatRupiah(double.tryParse(item['nominal'].toString()) ?? 0), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0D47A1))),
                            Text('${item['tenor_cicilan']} Bulan', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        if (item['angsurans'] != null && (item['angsurans'] as List).isNotEmpty) ...[
                          const Divider(height: 24),
                          Text('Angsuran Terbayar:', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                          const SizedBox(height: 8),
                          ...((item['angsurans'] as List)..sort((a, b) => (int.tryParse(a['angsuran_ke'].toString()) ?? 0).compareTo(int.tryParse(b['angsuran_ke'].toString()) ?? 0))).where((a) => a['status'] == 'lunas' || a['status'] == 'disetujui').map((angs) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, size: 14, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Text('Bulan ${angs['angsuran_ke']}', style: GoogleFonts.poppins(fontSize: 11)),
                                    const Spacer(),
                                    Text(formatRupiah(double.tryParse((angs['jumlah_bayar'] ?? angs['jumlah_angsuran'] ?? '0').toString()) ?? 0), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              )),
                        ],
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

  Widget _buildStatusBadge(String? status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'disetujui':
      case 'lunas':
        color = Colors.green;
        break;
      case 'ditolak':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
      child: Text((status ?? '-').toUpperCase(), style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
