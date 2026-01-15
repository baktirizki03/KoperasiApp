import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'pinjaman_form_screen.dart';

class PinjamanScreen extends StatefulWidget {
  const PinjamanScreen({super.key});

  @override
  State<PinjamanScreen> createState() => _PinjamanScreenState();
}

class _PinjamanScreenState extends State<PinjamanScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _pinjamanFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _pinjamanFuture = _apiService.getMyPinjaman();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      case 'lunas':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: FutureBuilder<List<dynamic>>(
          future: _pinjamanFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat data',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monetization_on_outlined, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada riwayat pinjaman.',
                      style: GoogleFonts.poppins(color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            final pinjamanList = snapshot.data!;
            final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pinjamanList.length,
              itemBuilder: (ctx, index) {
                final pinjaman = pinjamanList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Colors.orange),
                    ),
                    title: Text(
                      formatter.format(double.parse(pinjaman['nominal'].toString())),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Tenor: ${pinjaman['tenor_cicilan']} bulan',
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(pinjaman['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        pinjaman['status'].toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: _getStatusColor(pinjaman['status']),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 50).ms).slideX();
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => PinjamanFormScreen()),
          );
          if (result == true) {
            _loadData();
          }
        },
        label: Text(
          'Ajukan Pinjaman',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        elevation: 4,
      ).animate().scale(delay: 500.ms),
    );
  }
}
