import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class LaporanPinjamanScreen extends StatefulWidget {
  const LaporanPinjamanScreen({super.key});

  @override
  State<LaporanPinjamanScreen> createState() => _LaporanPinjamanScreenState();
}

class _LaporanPinjamanScreenState extends State<LaporanPinjamanScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allData = [];
  List<dynamic> _filteredData = [];
  bool _isLoading = true;
  String _selectedStatus = 'Semua';

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final role = authProvider.role?.toLowerCase();

      if (role == 'ketua') {
        final ketuaData = await _apiService.getPinjamanKetua();
        setState(() {
          _allData = ketuaData;
          _filterData();
          _isLoading = false;
        });
      } else {
        // Fetch all statuses and merge
        final pending = await _apiService.getPinjamanList('pending');
        final approved = await _apiService.getPinjamanList('disetujui');
        final rejected = await _apiService.getPinjamanList('ditolak');
        final lunas = await _apiService.getPinjamanList('lunas');

        setState(() {
          _allData = [...pending, ...approved, ...rejected, ...lunas];
          _filterData();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
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
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
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
                              label: _buildColumnHeader('Nama Lengkap'),
                            ),
                            DataColumn(label: _buildColumnHeader('Alamat')),
                            DataColumn(
                              label: _buildColumnHeader('Jumlah Pinjaman'),
                            ),
                            DataColumn(label: _buildColumnHeader('Tenor')),
                            DataColumn(label: _buildColumnHeader('Status')),
                          ],
                          rows: List<DataRow>.generate(_filteredData.length, (
                            index,
                          ) {
                            final item = _filteredData[index];
                            final anggota = item['anggota'] ?? {};

                            return DataRow(
                              cells: [
                                DataCell(Text('${index + 1}')),
                                DataCell(Text(anggota['nomor_anggota'] ?? '-')),
                                DataCell(Text(anggota['nama_lengkap'] ?? '-')),
                                DataCell(Text(anggota['domisili'] ?? '-')),
                                DataCell(
                                  Text(
                                    NumberFormat.currency(
                                      locale: 'id_ID',
                                      symbol: 'Rp ',
                                      decimalDigits: 0,
                                    ).format(
                                      int.tryParse(
                                            item['nominal'].toString(),
                                          ) ??
                                          0,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text('${item['tenor_cicilan']} Bulan'),
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
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Filter Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: ['Semua', 'Pending', 'Disetujui', 'Ditolak', 'Lunas']
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
