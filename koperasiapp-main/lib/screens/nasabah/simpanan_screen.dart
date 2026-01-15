import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:koperasiapp/screens/nasabah/simpanan_form_screen.dart';
import '../../services/api_service.dart';

class SimpananScreen extends StatefulWidget {
  const SimpananScreen({super.key});

  @override
  State<SimpananScreen> createState() => _SimpananScreenState();
}

class _SimpananScreenState extends State<SimpananScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _simpananFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _simpananFuture = _apiService.getMySimpanan();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
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
          future: _simpananFuture,
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
                    Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada riwayat simpanan.',
                      style: GoogleFonts.poppins(color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            final simpananList = snapshot.data!;
            final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: simpananList.length,
              itemBuilder: (ctx, index) {
                final simpanan = simpananList[index];
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
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.inventory_2_rounded, color: Colors.green),
                    ),
                    title: Text(
                      formatter.format(double.parse(simpanan['nominal'].toString())),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            simpanan['jenis_transaksi'],
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black87),
                          ),
                          Text(
                            simpanan['tanggal'],
                            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(simpanan['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        simpanan['status'].toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: _getStatusColor(simpanan['status']),
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
            MaterialPageRoute(builder: (ctx) => const SimpananFormScreen()),
          );
          if (result == true) {
            _loadData();
          }
        },
        label: Text(
          'Lakukan Setoran',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        elevation: 4,
      ).animate().scale(delay: 500.ms),
    );
  }
}
