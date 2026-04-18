import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/pdf_export_dialog.dart';

class LaporanSimpananScreen extends StatefulWidget {
  final String? initialFilterStatus;

  const LaporanSimpananScreen({super.key, this.initialFilterStatus});

  @override
  State<LaporanSimpananScreen> createState() => _LaporanSimpananScreenState();
}

class _LaporanSimpananScreenState extends State<LaporanSimpananScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allData = [];
  List<Map<String, dynamic>> _groupedData = [];
  bool _isLoading = true;
  String _filterStatus = 'Semua';
  bool _isDownloadingPdf = false;

  double _totalKasKoperasi = 0;
  double _simpananBulanIni = 0;
  double _penarikanBulanIni = 0;
  int _anggotaAktifBulanIni = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilterStatus != null) {
      _filterStatus = widget.initialFilterStatus!;
    }
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
        rawData = await _apiService.getSimpananKetua();
      } else {
        rawData = await _apiService.getAllSimpanan();
      }

      setState(() {
        _allData = rawData;
        _groupData();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _groupData() {
    final Map<String, Map<String, dynamic>> groups = {};
    final query = _searchController.text.toLowerCase();
    final filterStatus = _filterStatus.toLowerCase();
    double tempKasTotal = 0;
    double tempSimpananBulan = 0;
    double tempPenarikanBulan = 0;
    final Set<String> tempAnggotaAktif = {};

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    for (var item in _allData) {
      final anggota = item['anggota'] ?? {};
      final userId = (item['user_id'] ?? 'unknown').toString();

      final nama = (anggota['nama_lengkap'] ?? '').toString().toLowerCase();
      final noAnggota = (anggota['nomor_anggota'] ?? '').toString().toLowerCase();

      if (query.isNotEmpty && !nama.contains(query) && !noAnggota.contains(query)) continue;

      final itemStatus = (item['status'] ?? '').toString().toLowerCase();
      bool itemMatches = false;

      if (filterStatus == 'semua') {
        itemMatches = true;
      } else if (filterStatus == 'pending') {
        itemMatches = (itemStatus == 'menunggu_konfirmasi' || itemStatus == 'pending');
      } else {
        itemMatches = (itemStatus == filterStatus);
        if (filterStatus == 'verified' && itemStatus == 'disetujui') itemMatches = true;
      }

      if (itemMatches) {
        if (!groups.containsKey(userId)) {
          groups[userId] = {
            'anggota': anggota,
            'simpanan': <dynamic>[],
            'summary': {'pending': 0, 'verified': 0, 'ditolak': 0},
          };
        }

        groups[userId]!['simpanan'].add(item);
        String statusKey = itemStatus;
        if (statusKey == 'disetujui') statusKey = 'verified';
        if (statusKey == 'menunggu_konfirmasi') statusKey = 'pending';
        if (groups[userId]!['summary'].containsKey(statusKey)) groups[userId]!['summary'][statusKey]++;

        if (itemStatus == 'disetujui' || itemStatus == 'verified') {
          double nominal = double.tryParse((item['jumlah'] ?? item['nominal'] ?? '0').toString()) ?? 0;
          String jenis = (item['jenis_transaksi'] ?? '').toString().toLowerCase();
          String tipe = (item['tipe'] ?? '').toString().toLowerCase();

          if (jenis == 'kredit' || jenis == 'simpanan' || tipe == 'kredit') {
            tempKasTotal += nominal;
          } else if (jenis == 'debet' || jenis == 'penarikan' || tipe == 'debet') {
            tempKasTotal -= nominal;
          }
        }
      }

      // Calculate monthly stats regardless of status/search filter (as requested: "Realtime performance")
      // Only count verified items to ensure financial accuracy
      if (itemStatus == 'disetujui' || itemStatus == 'verified') {
        final itemDateStr = item['tanggal'] ?? item['created_at'];
        if (itemDateStr != null) {
          final itemDate = DateTime.tryParse(itemDateStr.toString());
          if (itemDate != null && itemDate.month == currentMonth && itemDate.year == currentYear) {
            double nominal = double.tryParse((item['jumlah'] ?? item['nominal'] ?? '0').toString()) ?? 0;
            String jenis = (item['jenis_transaksi'] ?? '').toString().toLowerCase();
            String tipe = (item['tipe'] ?? '').toString().toLowerCase();

            if (jenis == 'kredit' || jenis == 'simpanan' || tipe == 'kredit') {
              tempSimpananBulan += nominal;
              tempAnggotaAktif.add(userId);
            } else if (jenis == 'debet' || jenis == 'penarikan' || tipe == 'debet') {
              tempPenarikanBulan += nominal;
            }
          }
        }
      }
    }

    setState(() {
      _groupedData = groups.values.toList();
      _totalKasKoperasi = tempKasTotal;
      _simpananBulanIni = tempSimpananBulan;
      _penarikanBulanIni = tempPenarikanBulan;
      _anggotaAktifBulanIni = tempAnggotaAktif.length;
    });
  }

  void _filterData() => _groupData();

  Future<void> _exportPdf() async {
    final result = await showDialog<Map<String, int?>?>(
      context: context,
      builder: (ctx) => const PdfExportDialog(title: 'Laporan Simpanan'),
    );

    if (result != null) {
      setState(() => _isDownloadingPdf = true);
      try {
        await _apiService.downloadPdf('export/simpanan', 'Laporan_Simpanan.pdf', bulan: result['bulan'], tahun: result['tahun']);
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
                          _buildQuickStats(),
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
      title: Text('Laporan Simpanan', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
                        {'label': 'Verified', 'val': 'verified'},
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
                  Text('TOTAL KAS KOPERASI', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(formatRupiah(_totalKasKoperasi), style: GoogleFonts.poppins(color: const Color(0xFFE65100), fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.account_balance_rounded, color: Color(0xFFE65100), size: 24)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Akumulasi dari seluruh simpanan masuk dikurangi penarikan anggota.', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildStatCard(
          'Simpanan',
          formatRupiah(_simpananBulanIni),
          Icons.add_chart_rounded,
          const Color(0xFF2E7D32),
          'Bulan ini',
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Penarikan',
          formatRupiah(_penarikanBulanIni),
          Icons.outbox_rounded,
          const Color(0xFFE65100),
          'Bulan ini',
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Aktif',
          '$_anggotaAktifBulanIni Orang',
          Icons.people_alt_rounded,
          const Color(0xFF3949AB),
          'Anggota',
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3436),
                ),
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.poppins(
                fontSize: 8,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Ringkasan Simpanan Anggota', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
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
    if (summary['verified']! > 0) badges.add(_miniBadge('${summary['verified']}', Colors.green));
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
    final simpananList = group['simpanan'] as List<dynamic>;

    double totalSaldo = 0;
    for (var item in simpananList) {
      if ((item['status'] ?? '').toString().toLowerCase() == 'disetujui' || (item['status'] ?? '').toString().toLowerCase() == 'verified') {
        double nominal = double.tryParse((item['jumlah'] ?? item['nominal'] ?? '0').toString()) ?? 0;
        String jenis = (item['jenis_transaksi'] ?? '').toString().toLowerCase();
        String tipe = (item['tipe'] ?? '').toString().toLowerCase();

        if (jenis == 'kredit' || jenis == 'simpanan' || tipe == 'kredit') {
          totalSaldo += nominal;
        } else if (jenis == 'debet' || jenis == 'penarikan' || tipe == 'debet') {
          totalSaldo -= nominal;
        }
      }
    }

    simpananList.sort((a, b) {
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
                  Text('Riwayat Transaksi', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(anggota['nama_lengkap'] ?? '-', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Saldo:', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                        Text(formatRupiah(totalSaldo), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: simpananList.length,
                itemBuilder: (ctx, index) {
                  final item = simpananList[index];
                  final type = (item['jenis_transaksi'] ?? '').toLowerCase();
                  final isKredit = type == 'kredit';
                  final isDebet = type == 'debet';

                  IconData icon = isKredit ? Icons.arrow_circle_down_rounded : isDebet ? Icons.arrow_circle_up_rounded : Icons.info_outline;
                  Color color = isKredit ? Colors.green : isDebet ? Colors.red : Colors.blue;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['jenis_simpanan'] ?? item['tipe'] ?? 'Simpanan', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)), Text(DateFormat('dd MMM yyyy').format(DateTime.tryParse(item['tanggal'] ?? item['created_at']) ?? DateTime.now()), style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey))])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(formatRupiah(double.tryParse((item['jumlah'] ?? item['nominal'] ?? '0').toString()) ?? 0), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: color)), _buildStatusBadgeMini(item['status'])]),
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

  Widget _buildStatusBadgeMini(String? status) {
    Color color;
    String text = (status ?? '-').toUpperCase();
    if (text == 'DISETUJUI') text = 'VERIFIED';
    switch (text) {
      case 'PENDING': color = Colors.orange; break;
      case 'VERIFIED': color = Colors.green; break;
      case 'DITOLAK': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(text, style: GoogleFonts.poppins(fontSize: 8, color: color, fontWeight: FontWeight.bold)));
  }
}
