import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
  // Stores grouped data by Loan ID: { 'pinjaman': {}, 'anggota': {}, 'angsurans': [], 'status_laporan': '', 'progress': '' }
  List<Map<String, dynamic>> _groupedData = [];
  bool _isLoading = true;
  String _filterStatusLaporan = 'Aktif'; // Default filter
  bool _isDownloadingPdf = false;

  // Summary Metrics
  double _totalMasukBulanIni = 0;
  int _totalMenunggak = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final role = authProvider.role?.toLowerCase();
      List<dynamic> rawData = [];

      // Use getPinjamanKetua to get LOANS directly.
      // This ensures we see all loans, even if they don't have installments generated yet (or if installment endpoint is buggy).
      if (role == 'ketua') {
        rawData = await _apiService.getPinjamanKetua();
      } else {
        rawData = [];
      }

      setState(() {
        _allData = rawData;
        _groupData();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  void _groupData() {
    // Map<PinjamanID, GroupData>
    final Map<String, Map<String, dynamic>> groups = {};
    final query = _searchController.text.toLowerCase();

    // _allData is now List of LOANS (Pinjaman)
    for (var loan in _allData) {
      final pinjaman = loan;
      final anggota = loan['anggota'] ?? {};
      final pinjamanId = (loan['id'] ?? 'unknown').toString();

      // Retrieve installments from the loan object
      // Handle potential key variations
      final List<dynamic> angsurans =
          (loan['angsuran'] ?? loan['angsurans'] ?? []) as List<dynamic>;

      // Filter Logic (Search by Name or Member ID)
      final nama = (anggota['nama_lengkap'] ?? '').toString().toLowerCase();
      final noAnggota = (anggota['nomor_anggota'] ?? '')
          .toString()
          .toLowerCase();

      if (query.isNotEmpty &&
          !nama.contains(query) &&
          !noAnggota.contains(query)) {
        continue;
      }

      // Check Status: Only show Active/Lunas loans (ignore Pending/Rejected for Installment Report)
      final statusPinjaman = (loan['status'] ?? '').toString().toLowerCase();
      if (statusPinjaman != 'disetujui' && statusPinjaman != 'lunas') {
        continue;
      }

      groups[pinjamanId] = {
        'pinjaman': pinjaman,
        'anggota': anggota,
        'angsurans': angsurans,
        // Will calculate these below
        'status_laporan': 'Lancar',
        'progress': '0/0',
      };
    }

    // Process Status and Progress for each group
    List<Map<String, dynamic>> processedList = [];
    double tempMasukBulanIni = 0;
    int tempMenunggak = 0;
    final now = DateTime.now();

    for (var key in groups.keys) {
      final group = groups[key]!;
      final angsurans = group['angsurans'] as List<dynamic>;
      final pinjaman = group['pinjaman'];

      // Basic info
      int total = angsurans.length;
      // If angsurans list is empty, try to use 'lama_angsuran' from pinjaman as total
      if (total == 0) {
        total =
            int.tryParse((pinjaman['lama_angsuran'] ?? '0').toString()) ?? 0;
      }

      int paid = 0;
      bool isMenunggak = false;

      // Sort Angsuran by angsuran_ke
      angsurans.sort((a, b) {
        final seqA = int.tryParse(a['angsuran_ke'].toString()) ?? 0;
        final seqB = int.tryParse(b['angsuran_ke'].toString()) ?? 0;
        return seqA.compareTo(seqB);
      });

      for (var ang in angsurans) {
        final status = (ang['status'] ?? '').toString().toLowerCase();
        final dueDateStr = ang['tanggal_jatuh_tempo'];

        if (status == 'lunas' || status == 'disetujui') {
          paid++;
        } else {
          // Check if overdue
          if (dueDateStr != null) {
            final dueDate = DateTime.tryParse(dueDateStr);
            if (dueDate != null && dueDate.isBefore(DateTime.now())) {
              isMenunggak = true;
            }
          }
        }
      }

      group['progress_text'] = '$paid/$total';
      group['progress_value'] = total > 0 ? (paid / total) : 0.0;
      group['status_laporan'] = isMenunggak ? 'Menunggak' : 'Lancar';

      // Override status based on Pinjaman Status or Count
      final statusPinjaman = (pinjaman['status'] ?? '')
          .toString()
          .toLowerCase();
      if (statusPinjaman == 'lunas' || (paid == total && total > 0)) {
        group['status_laporan'] = 'Selesai';
        // Ensure progress shows full if lunas
        if (paid < total) {
          group['progress_text'] = '$total/$total';
          group['progress_value'] = 1.0;
        }
      }

      if (group['status_laporan'] == 'Menunggak') {
        tempMenunggak++;
      }

      // Calculate Sisa Hutang
      double nominalPinjaman =
          double.tryParse(pinjaman['nominal'].toString()) ?? 0;
      double totalBayar = 0;
      for (var ang in angsurans) {
        final status = (ang['status'] ?? '').toString().toLowerCase();
        double getAngsNominal =
            double.tryParse(
              (ang['jumlah_bayar'] ?? ang['jumlah_angsuran'] ?? '0').toString(),
            ) ??
            0;

        if (status == 'lunas' || status == 'disetujui') {
          totalBayar += getAngsNominal;

          // Calculate Bulan Ini
          final paidDateStr =
              ang['updated_at'] ??
              ang['created_at']; // approximate paid date in absence of real payment date
          if (paidDateStr != null) {
            final paidDate = DateTime.tryParse(paidDateStr);
            if (paidDate != null &&
                paidDate.year == now.year &&
                paidDate.month == now.month) {
              tempMasukBulanIni += getAngsNominal;
            }
          }
        }
      }

      double sisaHutang = nominalPinjaman - totalBayar;
      if (sisaHutang < 0) sisaHutang = 0;
      group['sisa_hutang'] = sisaHutang;

      // Filter based on _filterStatusLaporan
      bool include = false;
      if (_filterStatusLaporan == 'Semua') {
        include = true;
      } else if (_filterStatusLaporan == 'Selesai') {
        if (group['status_laporan'] == 'Selesai') include = true;
      } else {
        // Aktif (Lancar or Menunggak)
        if (group['status_laporan'] != 'Selesai') include = true;
      }

      if (include) {
        processedList.add(group);
      }
    }

    setState(() {
      _groupedData = processedList;
      _totalMasukBulanIni = tempMasukBulanIni;
      _totalMenunggak = tempMenunggak;
    });
  }

  void _filterData() {
    _groupData();
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _buildMiniCard(
              'Angsuran Masuk (Bulan Ini)',
              _totalMasukBulanIni,
              Icons.savings,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMiniCard(
              'Gagal Bayar (Menunggak)',
              _totalMenunggak.toDouble(),
              Icons.warning_amber_rounded,
              Colors.red,
              isCurrency: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(
    String title,
    double value,
    IconData icon,
    Color color, {
    bool isCurrency = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            isCurrency ? formatRupiah(value) : '${value.toInt()} Anggota',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    final result = await showDialog<Map<String, int?>?>(
      context: context,
      builder: (ctx) => const PdfExportDialog(title: 'Laporan Angsuran'),
    );

    if (result != null) {
      setState(() => _isDownloadingPdf = true);
      try {
        await _apiService.downloadPdf(
          'export/angsuran',
          'Laporan_Angsuran.pdf',
          bulan: result['bulan'],
          tahun: result['tahun'],
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Berhasil membuka PDF'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
      appBar: AppBar(
        title: Text(
          'Laporan Angsuran',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isDownloadingPdf)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              tooltip: 'Cetak PDF',
              onPressed: _exportPdf,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterHeader(),
                _buildSummaryCards(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                            ),
                            border: TableBorder(
                              horizontalInside: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            columnSpacing: 20,
                            columns: [
                              DataColumn(label: _buildColumnHeader('No')),
                              DataColumn(
                                label: _buildColumnHeader('No. Anggota'),
                              ),
                              DataColumn(
                                label: _buildColumnHeader('Nama Anggota'),
                              ),
                              DataColumn(label: _buildColumnHeader('Progres')),
                              DataColumn(label: _buildColumnHeader('Status')),
                              DataColumn(label: _buildColumnHeader('Aksi')),
                            ],
                            rows: List<DataRow>.generate(_groupedData.length, (
                              index,
                            ) {
                              final group = _groupedData[index];
                              final anggota = group['anggota'];

                              return DataRow(
                                cells: [
                                  DataCell(Text('${index + 1}')),
                                  DataCell(
                                    Text(anggota['nomor_anggota'] ?? '-'),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        // highlight logic
                                        color:
                                            group['status_laporan'] ==
                                                'Menunggak'
                                            ? Colors.red.withOpacity(0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        anggota['nama_lengkap'] ?? '-',
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${group['progress_text']} Bln',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          width: 80,
                                          height: 6,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: group['progress_value'],
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              color:
                                                  group['status_laporan'] ==
                                                      'Menunggak'
                                                  ? Colors.red
                                                  : group['status_laporan'] ==
                                                        'Selesai'
                                                  ? Colors.blue
                                                  : Colors.green,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    _buildLaporanStatusBadge(
                                      group['status_laporan'],
                                    ),
                                  ),
                                  DataCell(
                                    ElevatedButton(
                                      onPressed: () => _showDetailDialog(group),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        minimumSize: Size(0, 30),
                                      ),
                                      child: const Text(
                                        'Detail',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLaporanStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Lancar':
        color = Colors.green;
        break;
      case 'Menunggak':
        color = Colors.red;
        break;
      case 'Selesai':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> group) {
    final anggota = group['anggota'];
    final pinjaman = group['pinjaman'];
    final angsurans = group['angsurans'] as List<dynamic>;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rincian Angsuran',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            Text(
              '${anggota['nama_lengkap']} - ${anggota['nomor_anggota']}',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Pinjaman: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(double.tryParse(pinjaman['nominal'].toString()) ?? 0)}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sisa Hutang:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(group['sisa_hutang'] ?? 0),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: angsurans.length,
            separatorBuilder: (ctx, i) => Divider(height: 1),
            itemBuilder: (ctx, index) {
              final item = angsurans[index];
              final status = (item['status'] ?? '').toString().toLowerCase();
              final isPaid = status == 'lunas' || status == 'disetujui';

              // Check overdue for individual item if not paid
              bool isOverdue = false;
              if (!isPaid) {
                final dueDate = DateTime.tryParse(
                  item['tanggal_jatuh_tempo'] ?? '',
                );
                if (dueDate != null && dueDate.isBefore(DateTime.now())) {
                  isOverdue = true;
                }
              }

              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey[200],
                  child: Text(
                    '${item['angsuran_ke']}',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
                title: Text(
                  NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(
                    double.tryParse(
                          (item['jumlah_bayar'] ??
                                  item['jumlah_angsuran'] ??
                                  '0')
                              .toString(),
                        ) ??
                        0,
                  ),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jatuh Tempo: ${item['tanggal_jatuh_tempo'] != null ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(item['tanggal_jatuh_tempo']) ?? DateTime.now()) : '-'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOverdue ? Colors.red : Colors.grey,
                      ),
                    ),
                    if (isPaid && (item['acc_by_name'] != null || item['acc_by'] != null))
                      Text(
                        'Diterima oleh: ${item['acc_by_name'] ?? (item['acc_by'] is Map ? item['acc_by']['name'] : 'ID:${item['acc_by']}') ?? '-'} ${item['acc_by_role'] != null ? '(${item['acc_by_role']})' : ''}',
                        style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey[600]),
                      ),
                  ],
                ),
                trailing: _buildStatusBadgeMini(
                  isPaid ? 'Lunas' : (isOverdue ? 'Menunggak' : 'Belum Bayar'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Tutup')),
        ],
      ),
    );
  }

  Widget _buildStatusBadgeMini(String status) {
    Color color;
    if (status == 'Lunas')
      color = Colors.green;
    else if (status == 'Menunggak')
      color = Colors.red;
    else
      color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Cari Anggota',
                    hintText: 'Nama / No Anggota',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (val) => _filterData(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _filterStatusLaporan,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: ['Aktif', 'Selesai', 'Semua'].map((String val) {
                    return DropdownMenuItem<String>(
                      value: val,
                      child: Text(
                        val,
                        style: GoogleFonts.poppins(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}
