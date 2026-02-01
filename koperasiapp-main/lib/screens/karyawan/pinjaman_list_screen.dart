import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'pinjaman_detail_screen.dart';

class PinjamanListScreen extends StatefulWidget {
  const PinjamanListScreen({super.key});

  @override
  _PinjamanListScreenState createState() => _PinjamanListScreenState();
}

class _PinjamanListScreenState extends State<PinjamanListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  // Search variables
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Data Caching to prevent re-fetching on search
  late Future<List<dynamic>> _pendingFuture;
  late Future<List<dynamic>> _approvedFuture;
  late Future<List<dynamic>> _rejectedFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _pendingFuture = _apiService.getPinjamanList('pending');
      _approvedFuture = _apiService.getPinjamanList('disetujui');
      _rejectedFuture = _apiService.getPinjamanList('ditolak');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.black54),
                decoration: const InputDecoration(
                  hintText: 'Cari nama anggota...',
                  hintStyle: TextStyle(color: Colors.black54),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text('Manajemen Pinjaman'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Disetujui'),
            Tab(text: 'Ditolak'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPinjamanList(_pendingFuture, 'pending'),
          _buildPinjamanList(_approvedFuture, 'disetujui'),
          _buildPinjamanList(_rejectedFuture, 'ditolak'),
        ],
      ),
    );
  }

  Widget _buildPinjamanList(Future<List<dynamic>> future, String status) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('Tidak ada pengajuan dengan status "$status".'),
          );
        }

        // Filtering Logic
        final pinjamanList = snapshot.data!.where((pinjaman) {
          if (_searchQuery.isEmpty) return true;
          final anggota = pinjaman['anggota'];
          final nama = (anggota != null ? anggota['nama_lengkap'] : '')
              .toString()
              .toLowerCase();
          return nama.contains(_searchQuery.toLowerCase());
        }).toList();

        if (pinjamanList.isEmpty) {
          return const Center(child: Text('Data tidak ditemukan.'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            _refreshData();
          },
          child: ListView.builder(
            itemCount: pinjamanList.length,
            itemBuilder: (ctx, index) {
              final pinjaman = pinjamanList[index];
              final anggota = pinjaman['anggota'];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(
                    anggota != null
                        ? anggota['nama_lengkap']
                        : 'Nama tidak tersedia',
                  ),
                  subtitle: Text(
                    'Nominal: Rp ${pinjaman['nominal']} \nTenor: ${pinjaman['tenor_cicilan']} bulan',
                  ),
                  isThreeLine: true,
                  onTap: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) =>
                            PinjamanDetailScreen(pinjamanId: pinjaman['id']),
                      ),
                    );
                    if (result == true) {
                      _refreshData(); // Refresh if updated
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
