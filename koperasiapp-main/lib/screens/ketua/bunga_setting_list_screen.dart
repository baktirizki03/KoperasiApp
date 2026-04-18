import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import '../../utils/currency_formatter.dart';
import 'bunga_setting_form_screen.dart';

class BungaSettingListScreen extends StatefulWidget {
  const BungaSettingListScreen({super.key});

  @override
  State<BungaSettingListScreen> createState() => _BungaSettingListScreenState();
}

class _BungaSettingListScreenState extends State<BungaSettingListScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _settings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getBungaSettings();
      setState(() {
        _settings = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    }
  }

  Future<void> _deleteSetting(int id) async {
    if (!mounted) return;
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 32),
              ),
              const SizedBox(height: 16),
              Text('Hapus Pengaturan?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text('Data yang dihapus tidak dapat dikembalikan. Apakah Anda yakin?', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Hapus', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ) ?? false;

    if (confirm) {
      try {
        await _apiService.deleteBungaSetting(id);
        _fetchSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan berhasil dihapus'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _navigateForm({Map<String, dynamic>? setting}) async {
    bool? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BungaSettingFormScreen(setting: setting)),
    );

    if (result == true) {
      _fetchSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _fetchSettings(),
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
                          _buildListHeader(),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  _settings.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 100),
                              child: Column(
                                children: [
                                  Icon(Icons.layers_clear_rounded, size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text('Belum ada pengaturan bunga.', style: GoogleFonts.poppins(color: Colors.grey[500])),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildBungaCard(_settings[index], index),
                              childCount: _settings.length,
                            ),
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateForm(),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ).animate().scale(delay: 500.ms),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 80,
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
      centerTitle: true,
      title: Text('Pengaturan Bunga', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF0D47A1).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.settings_suggest_rounded, color: Color(0xFF0D47A1), size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STATUS PENGATURAN', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Text('${_settings.length} Tipe Aktif', style: GoogleFonts.poppins(color: const Color(0xFF2D3436), fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Daftar Suku Bunga', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
        Text('Tenor & Plafon', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildBungaCard(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => _navigateForm(setting: item),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: const Color(0xFF0D47A1).withOpacity(0.05), borderRadius: BorderRadius.circular(18)),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${item['rate']}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF0D47A1))),
                      Text('%', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1).withOpacity(0.5))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tenor ${item['tenor']} Bulan', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436))),
                    const SizedBox(height: 4),
                    Text('${formatRupiah(double.tryParse(item['min_amount'].toString()) ?? 0)} - ${formatRupiah(double.tryParse(item['max_amount'].toString()) ?? 0)}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 24), onPressed: () => _navigateForm(setting: item)),
                  IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 24), onPressed: () => _deleteSetting(item['id'])),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }
}
