import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/currency_formatter.dart';
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

  // Data Caching
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
      backgroundColor: const Color(0xFFF1F5FF),
      body: Column(
        children: [
          // --- PREMIUM HEADER ---
          _buildHeader(),

          // --- CONTENT AREA ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPinjamanList(_pendingFuture, 'pending', const Color(0xFFFFA000)),
                _buildPinjamanList(_approvedFuture, 'disetujui', const Color(0xFF00C853)),
                _buildPinjamanList(_rejectedFuture, 'ditolak', const Color(0xFFD32F2F)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pinjaman',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Kelola pengajuan pinjaman anggota',
                        style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isSearching = !_isSearching),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
          
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Cari nama anggota...',
                    border: InputBorder.none,
                    icon: const Icon(Icons.search, color: Color(0xFF0D47A1)),
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ).animate().fadeIn().slideY(begin: -0.2, end: 0),
            ),

          const SizedBox(height: 20),

          // --- CUSTOM TABBAR ---
          TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.6),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.normal, fontSize: 14),
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Disetujui'),
              Tab(text: 'Ditolak'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinjamanList(Future<List<dynamic>> future, String status, Color accentColor) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Gagal memuat: ${snapshot.error.toString().split(':').last}',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          );
        }

        final rawList = snapshot.data ?? [];
        final pinjamanList = rawList.where((pinjaman) {
          if (_searchQuery.isEmpty) return true;
          final anggota = pinjaman['anggota'];
          final nama = (anggota != null ? anggota['nama_lengkap'] : '').toString().toLowerCase();
          return nama.contains(_searchQuery.toLowerCase());
        }).toList();

        if (pinjamanList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty ? 'Pencarian tidak ditemukan' : 'Tidak ada data pengajuan',
                  style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshData(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: pinjamanList.length,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (ctx, index) {
              final pinjaman = pinjamanList[index];
              return _buildPinjamanCard(pinjaman, accentColor, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildPinjamanCard(Map<String, dynamic> pinjaman, Color accentColor, int index) {
    final anggota = pinjaman['anggota'];
    final String nama = anggota != null ? anggota['nama_lengkap'] : 'Nama tidak tersedia';
    final double nominal = double.tryParse(pinjaman['nominal'].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => PinjamanDetailScreen(pinjamanId: pinjaman['id'])),
            );
            if (result == true) _refreshData();
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.monetization_on_rounded, color: accentColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nama, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF2D3436))),
                      const SizedBox(height: 4),
                      Text(formatRupiah(nominal), style: GoogleFonts.poppins(fontSize: 14, color: accentColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text('Tenor: ${pinjaman['tenor_cicilan']} bulan', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }
}
