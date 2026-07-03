import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/pdf_export_dialog.dart';

class KaryawanLaporanScreen extends StatefulWidget {
  const KaryawanLaporanScreen({super.key});

  @override
  State<KaryawanLaporanScreen> createState() => _KaryawanLaporanScreenState();
}

class _KaryawanLaporanScreenState extends State<KaryawanLaporanScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedReportType = 'Pilih Laporan'; // 'Simpanan', 'Pinjaman', 'Angsuran'
  bool _isLoading = false;
  bool _isDownloadingPdf = false;
  List<dynamic> _allRawData = [];
  List<Map<String, dynamic>> _groupedData = [];

  // Filter local state
  String _filterStatus = 'Semua';

  // Simpanan stats
  double _simpananTotalKas = 0;
  double _simpananBulanIni = 0;
  double _simpananPenarikanBulanIni = 0;
  int _simpananAnggotaAktif = 0;

  // Pinjaman stats
  double _pinjamanTotalPlafon = 0;
  double _pinjamanAngsuranMasuk = 0;
  double _pinjamanSisaHutang = 0;

  // Angsuran stats
  double _angsuranMasukBulanIni = 0;
  int _angsuranTotalMenunggak = 0;

  // Anggota stats
  int _anggotaTotal = 0;
  int _anggotaTerverifikasi = 0;
  int _anggotaBelumTerverifikasi = 0;
  int _anggotaLaki = 0;
  int _anggotaPerempuan = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchReportData() async {
    if (_selectedReportType == 'Pilih Laporan') return;
    setState(() => _isLoading = true);

    try {
      List<dynamic> data = [];
      if (_selectedReportType == 'Simpanan') {
        data = await _apiService.getAllSimpanan();
      } else if (_selectedReportType == 'Pinjaman') {
        final pending = await _apiService.getPinjamanList('pending');
        final approved = await _apiService.getPinjamanList('disetujui');
        final rejected = await _apiService.getPinjamanList('ditolak');
        final lunas = await _apiService.getPinjamanList('lunas');
        data = [...pending, ...approved, ...rejected, ...lunas];
      } else if (_selectedReportType == 'Angsuran') {
        final pending = await _apiService.getPinjamanList('pending');
        final approved = await _apiService.getPinjamanList('disetujui');
        final rejected = await _apiService.getPinjamanList('ditolak');
        final lunas = await _apiService.getPinjamanList('lunas');
        data = [...pending, ...approved, ...rejected, ...lunas];
      } else if (_selectedReportType == 'Anggota') {
        data = await _apiService.getAnggota();
      }

      setState(() {
        _allRawData = data;
        _isLoading = false;
        _processAndGroupData();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _processAndGroupData() {
    final query = _searchController.text.toLowerCase();
    final Map<String, Map<String, dynamic>> groups = {};

    if (_selectedReportType == 'Simpanan') {
      double tempKasTotal = 0;
      double tempSimpananBulan = 0;
      double tempPenarikanBulan = 0;
      final Set<String> tempAnggotaAktif = {};
      final now = DateTime.now();

      for (var item in _allRawData) {
        final anggota = item['anggota'] ?? {};
        final userId = (item['user_id'] ?? 'unknown').toString();

        final nama = (anggota['nama_lengkap'] ?? '').toString().toLowerCase();
        final noAnggota = (anggota['nomor_anggota'] ?? '').toString().toLowerCase();
        if (query.isNotEmpty && !nama.contains(query) && !noAnggota.contains(query)) continue;

        final itemStatus = (item['status'] ?? '').toString().toLowerCase();
        bool matches = false;

        if (_filterStatus == 'Semua') {
          matches = true;
        } else if (_filterStatus == 'pending') {
          matches = (itemStatus == 'menunggu_konfirmasi' || itemStatus == 'pending');
        } else {
          matches = (itemStatus == _filterStatus);
          if (_filterStatus == 'verified' && itemStatus == 'disetujui') matches = true;
        }

        if (matches) {
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
          if (groups[userId]!['summary'].containsKey(statusKey)) {
            groups[userId]!['summary'][statusKey]++;
          }

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

        if (itemStatus == 'disetujui' || itemStatus == 'verified') {
          final itemDateStr = item['tanggal'] ?? item['created_at'];
          if (itemDateStr != null) {
            final itemDate = DateTime.tryParse(itemDateStr.toString());
            if (itemDate != null && itemDate.month == now.month && itemDate.year == now.year) {
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
        _simpananTotalKas = tempKasTotal;
        _simpananBulanIni = tempSimpananBulan;
        _simpananPenarikanBulanIni = tempPenarikanBulan;
        _simpananAnggotaAktif = tempAnggotaAktif.length;
      });

    } else if (_selectedReportType == 'Pinjaman') {
      double tempPlafon = 0;
      double tempMasuk = 0;

      for (var item in _allRawData) {
        final anggota = item['anggota'] ?? {};
        final userId = (item['user_id'] ?? 'unknown').toString();

        final nama = (anggota['nama_lengkap'] ?? '').toString().toLowerCase();
        final noAnggota = (anggota['nomor_anggota'] ?? '').toString().toLowerCase();
        if (query.isNotEmpty && !nama.contains(query) && !noAnggota.contains(query)) continue;

        final itemStatus = (item['status'] ?? '').toString().toLowerCase();
        bool matches = false;
        if (_filterStatus == 'Semua') {
          matches = true;
        } else if (_filterStatus == 'pending') {
          matches = (itemStatus == 'menunggu_konfirmasi' || itemStatus == 'pending');
        } else {
          if (itemStatus.contains(_filterStatus)) matches = true;
        }

        if (matches) {
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
        _pinjamanTotalPlafon = tempPlafon;
        _pinjamanAngsuranMasuk = tempMasuk;
        _pinjamanSisaHutang = _pinjamanTotalPlafon - _pinjamanAngsuranMasuk;
        if (_pinjamanSisaHutang < 0) _pinjamanSisaHutang = 0;
      });

    } else if (_selectedReportType == 'Angsuran') {
      for (var loan in _allRawData) {
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
        if (_filterStatus == 'Semua') {
          include = true;
        } else if (_filterStatus == 'Selesai') {
          if (group['status_laporan'] == 'Selesai') include = true;
        } else {
          if (group['status_laporan'] != 'Selesai') include = true;
        }

        if (include) processedList.add(group);
      }

      setState(() {
        _groupedData = processedList;
        _angsuranMasukBulanIni = tempMasukBulanIni;
        _angsuranTotalMenunggak = tempMenunggak;
      });
    } else if (_selectedReportType == 'Anggota') {
      int tempTotal = 0;
      int tempVerified = 0;
      int tempBelum = 0;
      int tempLaki = 0;
      int tempPerempuan = 0;

      final List<Map<String, dynamic>> processedList = [];

      for (var item in _allRawData) {
        final userRole = (item['user']?['role'] ?? '').toString().toLowerCase();
        if (userRole != 'nasabah') continue;

        final nama = (item['nama_lengkap'] ?? '').toString().toLowerCase();
        final noAnggota = (item['nomor_anggota'] ?? '').toString().toLowerCase();
        if (query.isNotEmpty && !nama.contains(query) && !noAnggota.contains(query)) continue;

        final val = item['is_ktp_verified'];
        final bool isVerified = val == 1 || val == true || val.toString() == '1' || val.toString() == 'true';

        bool matchesFilter = true;
        if (_filterStatus == 'Terverifikasi') {
          matchesFilter = isVerified;
        } else if (_filterStatus == 'Belum') {
          matchesFilter = !isVerified;
        }

        if (matchesFilter) {
          processedList.add(Map<String, dynamic>.from(item));

          tempTotal++;
          if (isVerified) {
            tempVerified++;
          } else {
            tempBelum++;
          }

          final jk = (item['jenis_kelamin'] ?? '').toString().toLowerCase();
          if (jk == 'l' || jk == 'laki-laki' || jk == 'laki') {
            tempLaki++;
          } else {
            tempPerempuan++;
          }
        }
      }

      setState(() {
        _groupedData = processedList;
        _anggotaTotal = tempTotal;
        _anggotaTerverifikasi = tempVerified;
        _anggotaBelumTerverifikasi = tempBelum;
        _anggotaLaki = tempLaki;
        _anggotaPerempuan = tempPerempuan;
      });
    }
  }

  Future<void> _exportPdf() async {
    if (_selectedReportType == 'Pilih Laporan') return;

    if (_selectedReportType == 'Anggota') {
      setState(() => _isDownloadingPdf = true);
      try {
        final apiPath = 'export/anggota';
        final fileName = 'Laporan_Anggota_${_filterStatus}.pdf';
        await _apiService.downloadPdf(apiPath, fileName, status: _filterStatus);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Berhasil mengunduh & membuka PDF'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengekspor PDF: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isDownloadingPdf = false);
      }
      return;
    }

    final result = await showDialog<Map<String, int?>?>(
      context: context,
      builder: (ctx) => PdfExportDialog(title: 'Laporan $_selectedReportType'),
    );

    if (result != null) {
      setState(() => _isDownloadingPdf = true);
      try {
        final apiPath = 'export/${_selectedReportType.toLowerCase()}';
        final fileName = 'Laporan_${_selectedReportType}.pdf';
        await _apiService.downloadPdf(apiPath, fileName, bulan: result['bulan'], tahun: result['tahun']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Berhasil mengunduh & membuka PDF'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengekspor PDF: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isDownloadingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      body: RefreshIndicator(
        onRefresh: () async => _fetchReportData(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildSliverHeader(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildReportSelectorCard(),
                    const SizedBox(height: 16),
                    if (_selectedReportType != 'Pilih Laporan') ...[
                      _buildSearchAndFilters(),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
                        _buildIntegratedSummary(),
                        const SizedBox(height: 16),
                        _buildListHeader(),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            if (!_isLoading && _selectedReportType != 'Pilih Laporan')
              _groupedData.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
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
                          (context, index) => _buildReportItemRow(_groupedData[index], index),
                          childCount: _groupedData.length,
                        ),
                      ),
                    ),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 100,
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Laporan Koperasi',
        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        if (_selectedReportType != 'Pilih Laporan')
          _isDownloadingPdf
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                  onPressed: _exportPdf,
                  tooltip: 'Ekspor PDF',
                ),
      ],
    );
  }

  Widget _buildReportSelectorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PILIH JENIS LAPORAN',
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1), letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedReportType,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0D47A1)),
                items: ['Pilih Laporan', 'Simpanan', 'Pinjaman', 'Angsuran', 'Anggota'].map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(
                      type == 'Pilih Laporan'
                          ? 'Silakan pilih jenis laporan...'
                          : (type == 'Anggota' ? 'Laporan Daftar Anggota' : 'Laporan $type'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: type == 'Pilih Laporan' ? FontWeight.normal : FontWeight.w600,
                        color: type == 'Pilih Laporan' ? Colors.grey : const Color(0xFF2D3436),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null && value != _selectedReportType) {
                    setState(() {
                      _selectedReportType = value;
                      _filterStatus = _selectedReportType == 'Angsuran' ? 'Aktif' : 'Semua';
                      _searchController.clear();
                      _groupedData.clear();
                      _allRawData.clear();
                    });
                    _fetchReportData();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    List<DropdownMenuItem<String>> filterItems = [];
    if (_selectedReportType == 'Simpanan') {
      filterItems = [
        {'label': 'Semua', 'val': 'Semua'},
        {'label': 'Pending', 'val': 'pending'},
        {'label': 'Verified', 'val': 'verified'},
        {'label': 'Ditolak', 'val': 'ditolak'},
      ].map((map) {
        return DropdownMenuItem<String>(value: map['val'], child: Text(map['label']!, style: GoogleFonts.poppins(fontSize: 12)));
      }).toList();
    } else if (_selectedReportType == 'Pinjaman') {
      filterItems = [
        {'label': 'Semua', 'val': 'Semua'},
        {'label': 'Pending', 'val': 'pending'},
        {'label': 'Aktif', 'val': 'disetujui'},
        {'label': 'Lunas', 'val': 'lunas'},
        {'label': 'Ditolak', 'val': 'ditolak'},
      ].map((map) {
        return DropdownMenuItem<String>(value: map['val'], child: Text(map['label']!, style: GoogleFonts.poppins(fontSize: 12)));
      }).toList();
    } else if (_selectedReportType == 'Angsuran') {
      filterItems = [
        {'label': 'Aktif', 'val': 'Aktif'},
        {'label': 'Selesai', 'val': 'Selesai'},
        {'label': 'Semua', 'val': 'Semua'},
      ].map((map) {
        return DropdownMenuItem<String>(value: map['val'], child: Text(map['label']!, style: GoogleFonts.poppins(fontSize: 12)));
      }).toList();
    } else if (_selectedReportType == 'Anggota') {
      filterItems = [
        {'label': 'Semua', 'val': 'Semua'},
        {'label': 'Terverifikasi', 'val': 'Terverifikasi'},
        {'label': 'Pending', 'val': 'Belum'},
      ].map((map) {
        return DropdownMenuItem<String>(value: map['val'], child: Text(map['label']!, style: GoogleFonts.poppins(fontSize: 12)));
      }).toList();
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            height: 48,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => _processAndGroupData(),
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterStatus,
                isExpanded: true,
                items: filterItems,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _filterStatus = val;
                      _processAndGroupData();
                    });
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleSummaryCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildListHeader() {
    String titleText = 'Laporan Data';
    if (_selectedReportType == 'Simpanan') titleText = 'Ringkasan Simpanan Anggota';
    if (_selectedReportType == 'Pinjaman') titleText = 'Daftar Pinjaman Anggota';
    if (_selectedReportType == 'Angsuran') titleText = 'Ringkasan Progres Angsuran';
    if (_selectedReportType == 'Anggota') titleText = 'Daftar Anggota Koperasi';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(titleText, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
        Text('${_groupedData.length} Item', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildIntegratedSummary() {
    if (_selectedReportType == 'Simpanan') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL KAS SIMPANAN', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(formatRupiah(_simpananTotalKas), style: GoogleFonts.poppins(color: const Color(0xFFE65100), fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.account_balance_rounded, color: Color(0xFFE65100), size: 24)),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSimpleSummaryCol('Simpanan Bulanan', formatRupiah(_simpananBulanIni), Colors.green),
                _buildSimpleSummaryCol('Penarikan Bulanan', formatRupiah(_simpananPenarikanBulanIni), Colors.red),
                _buildSimpleSummaryCol('Anggota Aktif', '$_simpananAnggotaAktif Orang', const Color(0xFF0D47A1)),
              ],
            )
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
    } else if (_selectedReportType == 'Pinjaman') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
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
                    Text(formatRupiah(_pinjamanTotalPlafon), style: GoogleFonts.poppins(color: const Color(0xFF0D47A1), fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.monetization_on_rounded, color: Color(0xFF0D47A1), size: 24)),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(child: _buildSimpleSummaryCol('Angsuran Masuk', formatRupiah(_pinjamanAngsuranMasuk), Colors.green)),
                Container(height: 30, width: 1, color: Colors.grey[200]),
                Expanded(child: _buildSimpleSummaryCol('Sisa Hutang', formatRupiah(_pinjamanSisaHutang), Colors.orange)),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
    } else if (_selectedReportType == 'Angsuran') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
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
                    Text(formatRupiah(_angsuranMasukBulanIni), style: GoogleFonts.poppins(color: Colors.green[700], fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.trending_up_rounded, color: Colors.green, size: 24)),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(child: _buildSimpleSummaryCol('Anggota Menunggak', '$_angsuranTotalMenunggak Orang', Colors.red)),
                Container(height: 30, width: 1, color: Colors.grey[200]),
                Expanded(child: _buildSimpleSummaryCol('Total Progres Aktif', '${_groupedData.length} Pinjaman', const Color(0xFF0D47A1))),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
    } else if (_selectedReportType == 'Anggota') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL ANGGOTA TERDAFTAR', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text('$_anggotaTotal Orang', style: GoogleFonts.poppins(color: const Color(0xFF673AB7), fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.people_rounded, color: Colors.purple, size: 24)),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSimpleSummaryCol('Terverifikasi', '$_anggotaTerverifikasi Orang', Colors.green),
                _buildSimpleSummaryCol('Belum Verif', '$_anggotaBelumTerverifikasi Orang', Colors.orange),
                _buildSimpleSummaryCol('Laki-laki', '$_anggotaLaki L', const Color(0xFF0D47A1)),
                _buildSimpleSummaryCol('Perempuan', '$_anggotaPerempuan P', Colors.pink),
              ],
            )
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
    }
    return const SizedBox();
  }

  Widget _buildReportItemRow(Map<String, dynamic> group, int index) {
    if (_selectedReportType == 'Simpanan') {
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
          onTap: () => _showSimpananDetailDialog(group),
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
                _buildSummaryBadgesSimpanan(summary),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
    } else if (_selectedReportType == 'Pinjaman') {
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
          onTap: () => _showPinjamanDetailDialog(group),
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
                _buildSummaryBadgesPinjaman(summary),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
    } else if (_selectedReportType == 'Angsuran') {
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
          onTap: () => _showAngsuranDetailDialog(group),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text(status.toUpperCase(), style: GoogleFonts.poppins(fontSize: 9, color: statusColor, fontWeight: FontWeight.bold)),
                    ),
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
    } else if (_selectedReportType == 'Anggota') {
      final val = group['is_ktp_verified'];
      final bool isVerified = val == 1 || val == true || val.toString() == '1' || val.toString() == 'true';

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: InkWell(
          onTap: () => _showAnggotaDetailDialog(group),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: (isVerified ? Colors.green : Colors.orange).withOpacity(0.05), shape: BoxShape.circle),
                  child: Icon(isVerified ? Icons.person_rounded : Icons.person_search_rounded, color: isVerified ? Colors.green : Colors.orange, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group['nama_lengkap'] ?? '-', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
                      Text(group['nomor_anggota'] ?? '-', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: (isVerified ? Colors.green : Colors.orange).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(isVerified ? 'VERIFIED' : 'PENDING', style: GoogleFonts.poppins(color: isVerified ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
    }
    return const SizedBox();
  }

  Widget _buildSummaryBadgesSimpanan(Map<String, int> summary) {
    List<Widget> badges = [];
    if (summary['pending']! > 0) badges.add(_miniBadge('${summary['pending']}', Colors.orange));
    if (summary['verified']! > 0) badges.add(_miniBadge('${summary['verified']}', Colors.green));
    return Row(children: badges);
  }

  Widget _buildSummaryBadgesPinjaman(Map<String, int> summary) {
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

  void _showSimpananDetailDialog(Map<String, dynamic> group) {
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
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(formatRupiah(double.tryParse((item['jumlah'] ?? item['nominal'] ?? '0').toString()) ?? 0), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: color)), _buildStatusBadgeMini(item['status'], color)]),
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

  Widget _buildStatusBadgeMini(String? status, Color defaultColor) {
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

  void _showPinjamanDetailDialog(Map<String, dynamic> group) {
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
                            _buildPinjamanStatusBadge(item['status']),
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

  Widget _buildPinjamanStatusBadge(String? status) {
    Color color;
    switch (status) {
      case 'pending': color = Colors.orange; break;
      case 'disetujui':
      case 'lunas': color = Colors.green; break;
      case 'ditolak': color = Colors.red; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
      child: Text((status ?? '-').toUpperCase(), style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  void _showAngsuranDetailDialog(Map<String, dynamic> group) {
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: itemColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(isPaid ? 'LUNAS' : (isOverdue ? 'MENUNGGAK' : 'PROSES'), style: GoogleFonts.poppins(fontSize: 8, color: itemColor, fontWeight: FontWeight.bold)),
                        ),
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

  void _showAnggotaDetailDialog(Map<String, dynamic> anggota) {
    final val = anggota['is_ktp_verified'];
    final bool isVerified = val == 1 || val == true || val.toString() == '1' || val.toString() == 'true';

    final dataList = [
      {'label': 'Nomor Anggota', 'value': anggota['nomor_anggota']},
      {'label': 'Nama Lengkap', 'value': anggota['nama_lengkap']},
      {'label': 'NIK (KTP)', 'value': anggota['nomor_ktp']},
      {'label': 'Jenis Kelamin', 'value': anggota['jenis_kelamin']},
      {'label': 'TTL', 'value': '${anggota['tempat_lahir'] ?? '-'}, ${anggota['tanggal_lahir'] ?? '-'}'},
      {'label': 'Domisili', 'value': anggota['domisili']},
      {'label': 'No. Telepon', 'value': anggota['no_telepon']},
      {'label': 'Pekerjaan', 'value': anggota['pekerjaan']},
      {'label': 'Pendidikan', 'value': anggota['pendidikan']},
      {'label': 'Agama', 'value': anggota['agama']},
      {'label': 'Status Nikah', 'value': anggota['status_pernikahan']},
      {'label': 'Ibu Kandung', 'value': anggota['nama_ibu_kandung']},
      {'label': 'Verifikator', 'value': isVerified ? (anggota['verified_by_name'] ?? 'Admin/Sistem') : '-'},
      {'label': 'Waktu Verifikasi', 'value': isVerified ? (anggota['updated_at'] != null ? DateFormat('dd MMM yyyy HH:mm').format(DateTime.tryParse(anggota['updated_at'].toString()) ?? DateTime.now()) : '-') : '-'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
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
                    Text('Detail Profil Anggota', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(anggota['nama_lengkap'] ?? '-', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ...dataList.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 110,
                                child: Text('${item['label']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('${item['value'] ?? '-'}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Tutup', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
