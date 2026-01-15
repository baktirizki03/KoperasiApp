import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class LaporanAngsuranScreen extends StatefulWidget {
  const LaporanAngsuranScreen({super.key});

  @override
  State<LaporanAngsuranScreen> createState() => _LaporanAngsuranScreenState();
}

class _LaporanAngsuranScreenState extends State<LaporanAngsuranScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allData = [];
  List<dynamic> _filteredData = [];
  bool _isLoading = true;
  String _selectedStatus = 'Semua';

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

      List<dynamic> data = [];
      if (role == 'ketua') {
        data = await _apiService.getAngsuranKetua();
      } else {
        // Fallback or implement finding specific endpoint for other roles if needed
        data = [];
      }

      setState(() {
        _allData = data;
        _filterData();
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

  void _filterData() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredData = _allData.where((item) {
        final anggota = item['anggota'] ?? {};
        final nama = (anggota['nama_lengkap'] ?? '').toString().toLowerCase();
        final noAnggota = (anggota['nomor_anggota'] ?? '')
            .toString()
            .toLowerCase();
        final status = (item['status'] ?? '').toString().toLowerCase();

        final matchesSearch = nama.contains(query) || noAnggota.contains(query);
        final matchesStatus =
            _selectedStatus == 'Semua' ||
            status == _selectedStatus.toLowerCase();

        return matchesSearch && matchesStatus;
      }).toList();
    });
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
          'Laporan Angsuran',
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
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                          ),
                          border: TableBorder.all(
                            color: Colors.grey.withOpacity(0.2),
                            width: 1,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          columns: [
                            DataColumn(label: _buildColumnHeader('No')),
                            DataColumn(
                              label: _buildColumnHeader('No. Anggota'),
                            ),
                            DataColumn(
                              label: _buildColumnHeader('Nama Anggota'),
                            ),
                            DataColumn(
                              label: _buildColumnHeader('Pinjaman Ke'),
                            ),
                            DataColumn(
                              label: _buildColumnHeader('Angsuran Ke'),
                            ),
                            DataColumn(label: _buildColumnHeader('Nominal')),
                            DataColumn(label: _buildColumnHeader('Denda')),
                            DataColumn(
                              label: _buildColumnHeader('Jatuh Tempo'),
                            ),
                            DataColumn(label: _buildColumnHeader('Status')),
                          ],
                          rows: List<DataRow>.generate(_filteredData.length, (
                            index,
                          ) {
                            final item = _filteredData[index];
                            final anggota = item['anggota'] ?? {};
                            final pinjaman = item['pinjaman'] ?? {};

                            return DataRow(
                              cells: [
                                DataCell(Text('${index + 1}')),
                                DataCell(Text(anggota['nomor_anggota'] ?? '-')),
                                DataCell(Text(anggota['nama_lengkap'] ?? '-')),
                                DataCell(Text(pinjaman['id'].toString())),
                                DataCell(Text(item['angsuran_ke'].toString())),
                                DataCell(
                                  Text(
                                    NumberFormat.currency(
                                      locale: 'id_ID',
                                      symbol: 'Rp ',
                                      decimalDigits: 0,
                                    ).format(
                                      int.tryParse(
                                            item['jumlah_angsuran'].toString(),
                                          ) ??
                                          0,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    NumberFormat.currency(
                                      locale: 'id_ID',
                                      symbol: 'Rp ',
                                      decimalDigits: 0,
                                    ).format(
                                      int.tryParse(item['denda'].toString()) ??
                                          0,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(item['tanggal_jatuh_tempo'] ?? '-'),
                                ),
                                DataCell(_buildStatusBadge(item['status'])),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
              // Filter Dropdown
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Filter Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: ['Semua', 'Belum Lunas', 'Lunas', 'Jatuh Tempo']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStatus = val;
                        _filterData();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Search Bar
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Cari',
                    hintText: 'Nama / No Anggota',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (val) => _filterData(),
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
    switch (status?.toLowerCase()) {
      case 'belum lunas':
        color = Colors.orange;
        break;
      case 'lunas':
        color = Colors.green;
        break;
      case 'jatuh tempo':
        color = Colors.red;
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
        (status ?? '-').toUpperCase(),
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
