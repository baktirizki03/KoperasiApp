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
                  child: _filteredData.isEmpty
                      ? const Center(child: Text('Data tidak ditemukan'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredData.length,
                          itemBuilder: (context, index) {
                            final pinjaman = _filteredData[index];
                            final anggota = pinjaman['anggota'] ?? {};
                            final angsurans =
                                pinjaman['angsurans'] as List? ?? [];

                            // Hitung progress
                            final totalAngsuran = angsurans.length;
                            final lunasCount = angsurans
                                .where((a) => a['status'] == 'lunas')
                                .length;
                            final progress = totalAngsuran > 0
                                ? lunasCount / totalAngsuran
                                : 0.0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                onTap: () =>
                                    _showAngsuranDetail(pinjaman, angsurans),
                                title: Text(
                                  anggota['nama_lengkap'] ??
                                      'Nama Tidak Diketahui',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      'No. Anggota: ${anggota['nomor_anggota'] ?? '-'}',
                                    ),
                                    Text(
                                      'Total Pinjaman: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(int.tryParse((pinjaman['nominal'] ?? '0').toString().split('.')[0]) ?? 0)}',
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: Colors.grey[200],
                                            color: progress == 1.0
                                                ? Colors.green
                                                : Colors.blue,
                                            minHeight: 8,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '$lunasCount/$totalAngsuran Bulan',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showAngsuranDetail(
    Map<String, dynamic> pinjaman,
    List<dynamic> angsurans,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detail Angsuran',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: angsurans.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = angsurans[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          child: Text('${item['angsuran_ke']}'),
                        ),
                        title: Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(
                            int.tryParse(
                                  (item['jumlah_angsuran'] ?? '0')
                                      .toString()
                                      .split('.')[0],
                                ) ??
                                0,
                          ),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Jatuh Tempo: ${item['tanggal_jatuh_tempo']}',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        trailing: _buildStatusBadge(item['status']),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
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
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Cari Anggota',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
      case 'belum_lunas':
      case 'belum bayar':
        color = Colors.orange;
        break;
      case 'lunas':
      case 'disetujui':
        color = Colors.green;
        break;
      case 'menunggu_konfirmasi':
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
        (status ?? '-').replaceAll('_', ' ').toUpperCase(),
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
