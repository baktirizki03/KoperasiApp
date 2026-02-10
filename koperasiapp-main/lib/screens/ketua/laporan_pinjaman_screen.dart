import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

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
  // Stores grouped data
  List<Map<String, dynamic>> _groupedData = [];
  bool _isLoading = true;
  String _filterStatus = 'Semua'; // Default

  @override
  void initState() {
    super.initState();
    if (widget.initialFilterStatus != null) {
      _filterStatus = widget.initialFilterStatus!;
    }
    _fetchAllData();
  }

  // ... _fetchAllData remains same ...

  void _groupData() {
    final Map<String, Map<String, dynamic>> groups = {};

    final query = _searchController.text.toLowerCase();
    final filterStatus = _filterStatus.toLowerCase();

    for (var item in _allData) {
      final anggota = item['anggota'] ?? {};
      final userId = (item['user_id'] ?? 'unknown').toString();

      // Filter by Name/ID
      final nama = (anggota['nama_lengkap'] ?? '').toString().toLowerCase();
      final noAnggota = (anggota['nomor_anggota'] ?? '')
          .toString()
          .toLowerCase();
      if (query.isNotEmpty &&
          !nama.contains(query) &&
          !noAnggota.contains(query)) {
        continue;
      }

      // Check Item Status for Filter
      final itemStatus = (item['status'] ?? '').toString().toLowerCase();

      bool matchesStatus = false;
      if (filterStatus == 'semua') {
        matchesStatus = true;
      } else if (filterStatus == 'pending') {
        matchesStatus =
            (itemStatus == 'menunggu_konfirmasi' || itemStatus == 'pending');
      } else {
        // Loose match for other statuses
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

        // Update Summary (based on normalized status keys)
        String summaryKey = itemStatus;
        if (itemStatus == 'menunggu_konfirmasi') summaryKey = 'pending';
        if (groups[userId]!['summary'].containsKey(summaryKey)) {
          groups[userId]!['summary'][summaryKey]++;
        }
      }
    }

    // Remove groups with no matching items
    groups.removeWhere((key, value) => (value['pinjaman'] as List).isEmpty);

    setState(() {
      _groupedData = groups.values.toList();
    });
  }

  void _filterData() {
    // Re-run grouping which includes filtering
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
          'Laporan Pinjaman',
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
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent, // Clean look
                          ),
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
                                label: _buildColumnHeader('Nama Lengkap'),
                              ),
                              DataColumn(
                                label: _buildColumnHeader('Status Pinjaman'),
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

                              // Determine display status based on what they have
                              String statusText = '';
                              if (summary['pending']! > 0)
                                statusText += '${summary['pending']} Pending ';
                              if (summary['disetujui']! > 0)
                                statusText += '${summary['disetujui']} Aktif ';
                              if (statusText.isEmpty)
                                statusText = 'Tidak ada aktif';

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
    if (summary['disetujui']! > 0) {
      badges.add(_miniBadge('Aktif: ${summary['disetujui']}', Colors.green));
    }
    if (summary['ditolak']! > 0) {
      badges.add(_miniBadge('Ditolak: ${summary['ditolak']}', Colors.red));
    }
    if (summary['lunas']! > 0) {
      badges.add(_miniBadge('Lunas: ${summary['lunas']}', Colors.blue));
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
    final pinjamanList = group['pinjaman'] as List<dynamic>;

    // Sort by Date Descending
    pinjamanList.sort((a, b) {
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
              'Riwayat Pinjaman',
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
            itemCount: pinjamanList.length,
            itemBuilder: (ctx, index) {
              final item = pinjamanList[index];
              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy').format(
                              DateTime.tryParse(item['created_at']) ??
                                  DateTime.now(),
                            ),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          _buildStatusBadge(item['status']),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${item['tenor_cicilan']} Bulan',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      if (item['acc_by'] != null)
                        Text(
                          'Diverifikasi oleh: ${(item['acc_by'] is Map ? item['acc_by']['name'] : 'ID:${item['acc_by']}') ?? '-'}',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
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
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
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
                        {'label': 'Aktif', 'val': 'disetujui'},
                        {'label': 'Lunas', 'val': 'lunas'},
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
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        (status ?? '-').toUpperCase(),
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
