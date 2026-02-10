import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.initialFilterStatus != null) {
      _filterStatus = widget.initialFilterStatus!;
    }
    _fetchData();
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
        rawData = await _apiService
            .getAllSimpanan(); // Changed to getAll for Employees to see history too
        if (rawData.isEmpty) rawData = await _apiService.getSimpananPending();
      }

      setState(() {
        _allData = rawData;
        _groupData();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _groupData() {
    final Map<String, Map<String, dynamic>> groups = {};
    final query = _searchController.text.toLowerCase();
    final filterStatus = _filterStatus.toLowerCase();

    for (var item in _allData) {
      final anggota = item['anggota'] ?? {};
      final userId = (item['user_id'] ?? 'unknown').toString();

      // Filter Logic
      final nama = (anggota['nama_lengkap'] ?? '').toString().toLowerCase();
      final noAnggota = (anggota['nomor_anggota'] ?? '')
          .toString()
          .toLowerCase();

      if (query.isNotEmpty &&
          !nama.contains(query) &&
          !noAnggota.contains(query)) {
        continue;
      }

      final itemStatus = (item['status'] ?? '').toString().toLowerCase();
      bool itemMatches = false;

      if (filterStatus == 'semua') {
        itemMatches = true;
      } else if (filterStatus == 'pending') {
        itemMatches =
            (itemStatus == 'menunggu_konfirmasi' || itemStatus == 'pending');
      } else {
        itemMatches = (itemStatus == filterStatus);
        if (filterStatus == 'verified' && itemStatus == 'disetujui')
          itemMatches = true;
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

        if (groups[userId]!['summary'].containsKey(statusKey)) {
          groups[userId]!['summary'][statusKey]++;
        }
      }
    }

    setState(() {
      _groupedData = groups.values.toList();
    });
  }

  void _filterData() {
    _groupData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Laporan Simpanan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterHeader(),
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
                              DataColumn(
                                label: _buildColumnHeader('Status Simpanan'),
                              ),
                              DataColumn(label: _buildColumnHeader('Aksi')),
                            ],
                            rows: List<DataRow>.generate(_groupedData.length, (
                              index,
                            ) {
                              final group = _groupedData[index];
                              final anggota = group['anggota'];
                              final summary =
                                  group['summary'] as Map<String, int>;

                              return DataRow(
                                cells: [
                                  DataCell(Text('${index + 1}')),
                                  DataCell(
                                    Text(anggota['nomor_anggota'] ?? '-'),
                                  ),
                                  DataCell(
                                    Text(anggota['nama_lengkap'] ?? '-'),
                                  ),
                                  DataCell(_buildSummaryBadge(summary)),
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

  Widget _buildSummaryBadge(Map<String, int> summary) {
    List<Widget> badges = [];
    if (summary['pending']! > 0) {
      badges.add(_miniBadge('Pending: ${summary['pending']}', Colors.orange));
    }
    if (summary['verified']! > 0) {
      badges.add(_miniBadge('Verified: ${summary['verified']}', Colors.green));
    }
    if (summary['ditolak']! > 0) {
      badges.add(_miniBadge('Ditolak: ${summary['ditolak']}', Colors.red));
    }

    if (badges.isEmpty) return Text('-');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: badges
          .map((b) => Padding(padding: EdgeInsets.only(bottom: 2), child: b))
          .toList(),
    );
  }

  Widget _miniBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> group) {
    final anggota = group['anggota'];
    final simpananList = group['simpanan'] as List<dynamic>;

    // Sort by Date Descending
    simpananList.sort((a, b) {
      final dateA = DateTime.tryParse(a['created_at']) ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['created_at']) ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat Simpanan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            Text(
              '${anggota['nama_lengkap']} - ${anggota['nomor_anggota']}',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: simpananList.length,
            itemBuilder: (ctx, index) {
              final item = simpananList[index];
              // Determine Icon & Color
              final type = (item['jenis_transaksi'] ?? '').toLowerCase();
              final isKredit = type == 'kredit'; // Masuk
              final isDebet = type == 'debet'; // Keluar

              IconData icon = isKredit
                  ? Icons.arrow_circle_down
                  : isDebet
                  ? Icons.arrow_circle_up
                  : Icons.info;
              Color color = isKredit
                  ? Colors.green
                  : isDebet
                  ? Colors.red
                  : Colors.blue;

              String displayTitle =
                  item['jenis_simpanan'] ?? item['tipe'] ?? 'Simpanan';

              return Card(
                elevation: 1,
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(
                    displayTitle,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(
                          DateTime.tryParse(
                                item['tanggal'] ?? item['created_at'],
                              ) ??
                              DateTime.now(),
                        ),
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      if (item['acc_by'] != null)
                        Text(
                          'Verified by: ${(item['acc_by'] is Map ? item['acc_by']['name'] : 'ID:${item['acc_by']}') ?? '-'}',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(
                          double.tryParse(item['nominal'].toString()) ?? 0,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: color,
                        ),
                      ),
                      _buildStatusBadgeMini(item['status']),
                    ],
                  ),
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

  Widget _buildStatusBadgeMini(String? status) {
    Color color;
    String text = (status ?? '-').toUpperCase();
    if (text == 'DISETUJUI') text = 'VERIFIED';

    switch (text) {
      case 'PENDING':
        color = Colors.orange;
        break;
      case 'VERIFIED':
        color = Colors.green;
        break;
      case 'DITOLAK':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (val) => _filterData(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _filterStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items:
                      [
                        {'label': 'Semua', 'val': 'Semua'},
                        {'label': 'Pending', 'val': 'pending'},
                        {'label': 'Verified', 'val': 'verified'},
                        {'label': 'Ditolak', 'val': 'ditolak'},
                      ].map((map) {
                        return DropdownMenuItem<String>(
                          value: map['val'],
                          child: Text(
                            map['label']!,
                            style: GoogleFonts.poppins(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
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
